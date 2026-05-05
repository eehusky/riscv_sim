from __future__ import annotations

import enum
from typing import NamedTuple
import warnings
from collections import deque

from cocotbext.axi.axi_master import AxiReadResp, AxiWriteResp

warnings.simplefilter("ignore")

import asyncio
import logging
import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles, Combine, RisingEdge, ValueChange
from cocotbext.axi import AddressSpace, AxiBus, AxiLiteBus, AxiResp, AxiSlave, AxiMaster, AxiLiteSlave, MemoryInterface, MemoryRegion, Pool, Region, Window
from rich import get_console
from rich.text import Text
from rich.tree import Tree

_print = print
print = get_console().print


CLK_PERIOD = 10
ADDR_RANGE = 1<<17

def walk_dut(dut: HierarchyObject, tree: Tree | None = None) -> Tree:
    colormap = {
        cocotb.handle.HierarchyObject: "bold magenta",  # pyright: ignore
        cocotb.handle.HierarchyArrayObject: "bright cyan",  # pyright: ignore
        cocotb.handle.RealObject: "cyan",  # pyright: ignore
        cocotb.handle.EnumObject: "blue",  # pyright: ignore
        cocotb.handle.IntegerObject: "white",  # pyright: ignore
        cocotb.handle.StringObject: "yellow",  # pyright: ignore
        cocotb.handle.LogicArrayObject: "white",  # pyright: ignore
        cocotb.handle.LogicObject: "white",  # pyright: ignore
        cocotb.handle.ArrayObject: "white",  # pyright: ignore
        cocotb.handle.PackedObject: "white",  # pyright: ignore
    }
    tname = f"{type(dut).__name__} | {dut._name} [{len(dut)}]"  # pyright: ignore
    text = Text(tname, colormap[type(dut)])

    if tree is None:
        tree = Tree(text)

    temp = dir(dut)
    handles = sorted(
        dut._sub_handles.items(),
        key=lambda it: (
            type(it[1]).__name__,
            it[0],
        ),
    )

    for name, handle in handles:
        # print(f"{name} {handle}")
        temp = dir(handle)
        tname = f"{type(handle).__name__} | {handle._name} [{len(handle)}]"
        # tname = repr(handle)
        text = Text(tname, colormap[type(handle)])
        if isinstance(handle, HierarchyObject):
            branch = tree.add(text)
            walk_dut(handle, branch)
        else:
            tree.add(text)

    return tree

class VPIRegion(MemoryInterface):
    def __init__(self, size, vpiobj, **kwargs):
        super().__init__(size, **kwargs)
        self._vpiobj = vpiobj

    def _read_local(self,addr:int):
        mem = self._vpiobj
        word = mem[addr//4].value.to_unsigned()
        value = word >> ((addr%4)*8) & 0xFF
        return value
    def _write_local(self,addr:int, data:int):
        mem = self._vpiobj
        word = mem[addr//4].value.to_unsigned()
        mask = 0xFF << ((addr%4)*8)
        word &= ~mask
        word |= (data& 0xFF) << ((addr%4)*8)
        mem[addr//4].value = word

    async def _read(self, address, length, **kwargs):
        rv = bytes([self._read_local(address+_) for _ in range(length)])
        #print(f"read {address=}, {length=} {rv=}")
        return rv

    async def _write(self, address, data, **kwargs):
        print(f"write {address=}, {data=}")
        for ndx,_ in enumerate(data):
            self._write_local(address+ndx, _)
        #self.mem[address:address+len(data)] = data

class Request(NamedTuple):
    addr:int
    wdata:int
    wstrb:int

    @property
    def is_write(self):
        return self.wstrb !=0


class Response(NamedTuple):
    rdata: int
    req: Request

class TB:
    def __init__(self, dut):
        self.dut = dut
        tb_loglevel = logging.FATAL
        reg_loglevel = logging.FATAL
        axi_loglevel = logging.FATAL

        self.reset = self.dut.rst_i
        self.clk = self.dut.clk_i
        cocotb.start_soon(Clock(self.clk, CLK_PERIOD, unit="ns", impl="gpi").start())

        logging.getLogger("cocotb.tb_dport.m_axi_cached").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_dport.m_axi_uncached").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_dport.m_axil").setLevel(logging.WARNING)
        #self.axi_logger.setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb").setLevel(tb_loglevel)
        self.local_mem = self.dut.i_mem_dport_axi.i_mem_dummy.mem
        self.dtcm_mem = self.dut.i_mem_dport_axi.i_dtcm.mem

        self.addrspace = AddressSpace()
        self.cached_region = MemoryRegion(ADDR_RANGE)
        self.uncached_region = MemoryRegion(ADDR_RANGE)
        self.axil_region = MemoryRegion(ADDR_RANGE)
        self.local_region = VPIRegion(ADDR_RANGE, self.local_mem)
        self.dtcm_region = VPIRegion(ADDR_RANGE, self.dtcm_mem)
        self.addrspace.register_region(self.cached_region,0x9000_0000,ADDR_RANGE)
        self.addrspace.register_region(self.uncached_region,0xA000_0000,ADDR_RANGE)
        self.addrspace.register_region(self.axil_region,0xB000_0000,ADDR_RANGE)
        self.addrspace.register_region(self.local_region,0x0000_0000,1<<16)


        self.ref = bytearray(0 for _ in range(ADDR_RANGE))
        self.axi_cached = AxiSlave(
            bus=AxiBus.from_prefix(dut, "m_axi_cached"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
            target = self.addrspace
        )
        self.axi_uncached = AxiSlave(
            bus=AxiBus.from_prefix(dut, "m_axi_uncached"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
            target = self.addrspace
        )
        self.axil = AxiLiteSlave(
            bus=AxiLiteBus.from_prefix(dut, "m_axil"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
            target = self.addrspace
        )

        self.req_queue:Queue[Request] = Queue()
        self.rsp_queue:Queue[Response] = Queue()
        self.pend_queue:Queue[Request] = Queue()


    async def clkcycle(self, n=1):
        await ClockCycles(self.clk, n)

    async def cycle_reset(self):
        self.reset.value = 1

        await self.clkcycle(10)
        self.reset.value = 0
        await self.clkcycle(10)
        #self.axi_logger.setLevel(logging.INFO)

        logging.getLogger("cocotb.tb_dport.m_axi_cached").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_dport.m_axi_uncached").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_dport.m_axil").setLevel(logging.INFO)

    async def read_csr(self, addr):
        self.dut.iob_valid_i.value = 1
        self.dut.iob_addr_i.value = addr
        while True:
            await self.clkcycle()
            if self.dut.iob_rvalid_o.value and self.dut.iob_valid_i.value and self.dut.iob_ready_o.value:
                break

        rv = self.dut.iob_rdata_o.value.to_unsigned()
        self.dut.iob_valid_i.value = 0
        self.dut.iob_addr_i.value = 0
        await self.clkcycle()
        return rv

    async def proc_check(self):
        while True:
            rsp:Response = await self.rsp_queue.get()
            req = rsp.req
            if not req.wstrb:
                #print(f"{req.addr:04X}: {rsp.rdata:08X} == {self.read_ref(req.addr):08X}")
                assert rsp.rdata == self.read_ref(req.addr), f"{req.addr:04X}: {rsp.rdata:08X} == {self.read_ref(req.addr):08X}"


    async def proc_rsp(self):
        data_wr_i = self.dut.mem_data_wr_i
        wr_i = self.dut.mem_wr_i
        addr_i = self.dut.mem_addr_i
        rd_i = self.dut.mem_rd_i
        data_rd_o = self.dut.mem_data_rd_o
        accept_o = self.dut.mem_accept_o
        ack_o = self.dut.mem_ack_o
        while True:
            if ack_o.value:
                req = self.pend_queue.get_nowait()
                self.rsp_queue.put_nowait(Response(data_rd_o.value.to_unsigned(),req))
                if req.is_write:
                    self.write_ref(req.addr,req.wdata)
            await self.clkcycle()

    async def proc_req(self):
        data_wr_i = self.dut.mem_data_wr_i
        wr_i = self.dut.mem_wr_i
        addr_i = self.dut.mem_addr_i
        rd_i = self.dut.mem_rd_i
        data_rd_o = self.dut.mem_data_rd_o
        accept_o = self.dut.mem_accept_o
        ack_o = self.dut.mem_ack_o

        req = None
        while True:
            if req is None:
                req = await self.req_queue.get()
                self.pend_queue.put_nowait(req)
                data_wr_i.value = req.wdata
                wr_i.value = req.wstrb
                addr_i.value = req.addr
                rd_i.value = 0 if req.wstrb else 1

            await self.clkcycle(1)
            if accept_o.value and req:
                data_wr_i.value = 0
                wr_i.value = 0
                addr_i.value = 0
                rd_i.value = 0
                req = None

    async  def write_pool(self,addr:int,data:int):
        await self.addrspace.write(addr,data.to_bytes(4,byteorder="little"))
        ##self.cached_region.mem[addr:addr+4] = data.to_bytes(4,byteorder="little")

    async def read_pool(self,addr:int):
        return int.from_bytes(await self.addrspace.read(addr,addr+4),byteorder="little")
        #return int.from_bytes(self.cached_region.mem[addr:addr+4],byteorder="little")

    def write_ref(self,addr:int,data:int):
        self.ref[addr:addr+4] = data.to_bytes(4)

    def read_ref(self,addr:int):
        return int.from_bytes(self.ref[addr:addr+4])

    def read(self,addr:int):
        self.req_queue.put_nowait((Request(addr,0,0)))

    def write(self,addr:int,data:int):
        self.req_queue.put_nowait((Request(addr,data,0xF)))

    def _read_local(self,addr:int):
        mem = self.dut.i_mem_dport_axi.i_mem_dummy.mem
        word = mem[addr//4].value.to_unsigned()
        value = word >> ((addr%4)*8) & 0xFF
        return value
    def _write_local(self,addr:int, data:int):
        mem = self.dut.i_mem_dport_axi.i_mem_dummy.mem
        word = mem[addr//4].value.to_unsigned()
        mask = 0xFF << ((addr%4)*8)
        word &= ~mask
        word |= (data& 0xFF) << ((addr%4)*8)
        mem[addr//4].value = word

    def write_local_word(self,addr:int, data:int):
        self.local_mem[addr//4].value = data

    def read_local_word(self,addr:int):
        return self.local_mem[addr//4].value.to_unsigned()

    def write_dtcm_word(self,addr:int, data:int):
        self.dtcm_mem[addr//4].value = data

    def read_dtcm_word(self,addr:int):
        return self.dtcm_mem[addr//4].value.to_unsigned()

## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------

def random_addr():
    return random.randint(0,ADDR_RANGE-1) & 0xFFFFFFFC
def random_int():
    return random.randint(0,0xFFFFFFFF)

def pf(text, okay, assert_=True):
    color = "green" if okay else "red"
    if not okay or not assert_:
        print(f"[{color}]{text}[/{color}]")
    if assert_:
        assert okay, text


def testname(prefix):
    NAME = os.environ.get("TESTNAME", None)
    if NAME:
        return f"{prefix}_{NAME}"
    return f"{prefix}"


## ----------------------------------------------------------------------------


class Range(NamedTuple):
    name: str
    decode: int
    low: int
    size: int

    @property
    def high(self):
        return self.low+self.size-1

@cocotb.test(timeout_time=10, timeout_unit="ms", skip=False)
async def test_decode(dut):
    #print(walk_dut(dut))
    tb = TB(dut)
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    #for _ in range(0,ADDR_RANGE,4):
    #    v = random_int()
    #    tb.write_ref(_,v)
    #    await tb.write_pool(_,v)

    async def set_addr(addr):
        error = False
        ack = False
        decode = 0
        dut.mem_addr_i.value = addr
        dut.mem_rd_i.value = 1
        await tb.clkcycle(1)
        decode = dut.i_mem_dport_axi.i_mem_dport_mux.o_decode.value
        dut.mem_rd_i.value = 0
        for _ in range(10):
            if dut.mem_ack_o.value:
                ack = True
                if dut.mem_error_o.value:
                    error = True
                break
            await tb.clkcycle(1)
        return decode, ack, error

    async def check_addr(addr:int,r:Range,expect_error:bool):
        decode, ack, error = await set_addr(addr)
        assert ack, f"{r.name}: {addr=:08X}, {decode=:b}, {ack=}, {error=}"
        assert error == expect_error, f"{r.name}: {addr=:08X}, {decode=:b}, {ack=}, {error=}"
        if expect_error:
            assert decode != r.decode, f"{r.name}: {addr=:08X}, {decode=:b}, {ack=}, {error=}"
        else:
            assert decode == r.decode, f"{r.name}: {addr=:08X}, {decode=:b}, {ack=}, {error=}"

    #tb.write_local_word(0x0000,0xDEADBEEF)
    #tb.write_dtcm_word(0x0000,0xDEADBEEF)
    await tb.addrspace.write(0x0000,0xDEADBEEF.to_bytes(4))
    await tb.clkcycle(1)
    await tb.addrspace.read(0x0000,4)

    ranges = [
        Range("local",    0b000001, 0x0000_0000, 64*1024),
        Range("dtcm",     0b000010, 0x8002_0000, 128*1024),
        Range("cached",   0b000100, 0x9000_0000, 128*1024),
        Range("uncached", 0b001000, 0xA000_0000, 128*1024),
        Range("axil",     0b010000, 0xB000_0000, 128*1024),
    ]

    #await set_addr(0xA0000000)
    #await set_addr(0x80000000)
    #await set_addr(0x10000000)

    for r in ranges:
        if r.low >=4:
            await check_addr(r.low-4,r,True)
        await check_addr(r.low,r,False)
        await check_addr(r.low+4,r,False)
        await check_addr(r.high+1-4,r,False)
        await check_addr(r.high+1+4,r,True)
        await tb.clkcycle(10)

    await tb.clkcycle(100)


@cocotb.test(timeout_time=10, timeout_unit="ms", skip=True)
async def test_dummy(dut):

    tb = TB(dut)
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)


    tb.read_local(0x0000)
    await tb.clkcycle(10)

    tb.write_local_word(0x0000,0xDEADBEEF)
    await tb.clkcycle(10)
    print(tb.read_local_word(0x0000))
    print(tb.read_local_word(0x0001))
    print(tb.read_local_word(0x0002))
    print(tb.read_local_word(0x0003))
