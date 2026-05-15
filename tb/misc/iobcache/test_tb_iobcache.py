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
from cocotbext.axi import AxiBus, AxiLiteBus, AxiResp, AxiSlave, AxiMaster, AxiLiteSlave, MemoryRegion, Pool
from rich import get_console
from rich.text import Text
from rich.tree import Tree

_print = print
print = get_console().print


CLK_PERIOD = 10
ADDR_RANGE = 1<<16

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

        self.reset = self.dut.i_reset
        self.clk = self.dut.i_clk
        cocotb.start_soon(Clock(self.clk, CLK_PERIOD, unit="ns", impl="gpi").start())

        logging.getLogger("cocotb.tb_iobcache.be_axi").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_iobcache.be_iob").setLevel(logging.WARNING)
        #self.axi_logger.setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb").setLevel(tb_loglevel)

        self.pool = Pool(parent=None, base=0, size=ADDR_RANGE)
        self.region = self.pool.alloc_region(ADDR_RANGE)
        self.ref = bytearray(0 for _ in range(ADDR_RANGE))
        self.s_data_axi = AxiSlave(
            bus=AxiBus.from_prefix(dut, "be_axi"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
            target = self.pool
        )
        self.s_iob_axi = AxiSlave(
            bus=AxiBus.from_prefix(dut, "be_iob"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
            target = self.pool
        )
        #p = 1
        #for i in range(0,1024):
        #    r.mem[i] = (i+1)%256
            #r.mem[i+1] = i+1
            #r.mem[i+2] = i+1
            #r.mem[i+3] = i+1

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

        logging.getLogger("cocotb.tb_iobcache.be_axi").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_iobcache.be_iob").setLevel(logging.WARNING)

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

    def write_pool(self,addr:int,data:int):
        self.region.mem[addr:addr+4] = data.to_bytes(4,byteorder="little")

    def read_pool(self,addr:int):
        return int.from_bytes(self.region.mem[addr:addr+4],byteorder="little")

    def write_ref(self,addr:int,data:int):
        self.ref[addr:addr+4] = data.to_bytes(4)

    def read_ref(self,addr:int):
        return int.from_bytes(self.ref[addr:addr+4])

    def read(self,addr:int):
        self.req_queue.put_nowait((Request(addr,0,0)))

    def write(self,addr:int,data:int):
        self.req_queue.put_nowait((Request(addr,data,0xF)))

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

class IobCacheCsr(enum.IntEnum):
    WTB_EMPTY  = 0
    WTB_FULL   = 1
    RW_HIT     = 4
    RW_MISS    = 8
    READ_HIT   = 12
    READ_MISS  = 16
    WRITE_HIT  = 20
    WRITE_MISS = 24
    RST_CNTRS  = 28
    INVALIDATE = 29
    VERSION    = 32

@cocotb.test(timeout_time=10, timeout_unit="ms", skip=True)
async def test_glue_rd(dut):
    tb = TB(dut)
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    cnt = 0
    addr = 0
    dut.mem_rd_i.value = 1
    while True:
        dut.mem_addr_i.value = addr
        await tb.clkcycle(1)
        if dut.mem_accept_o.value:
            addr+=32
            cnt +=1
        if cnt == 32:
            break
    dut.mem_rd_i.value = 0

    await tb.clkcycle(40)

    cnt = 0
    addr = 0
    dut.mem_rd_i.value = 1
    while True:
        dut.mem_addr_i.value = addr
        await tb.clkcycle(1)
        if dut.mem_accept_o.value:
            addr+=4
            cnt +=1
        if cnt == 32*4:
            break
    dut.mem_rd_i.value = 0


    await tb.clkcycle(20)


@cocotb.test(timeout_time=10, timeout_unit="ms", skip=True)
async def test_glue_wr(dut):
    tb = TB(dut)
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    cnt = 0
    addr = 0
    dut.mem_wr_i.value = 0xF
    while True:
        dut.mem_addr_i.value = addr
        await tb.clkcycle(1)
        if dut.mem_accept_o.value:
            addr+=32
            cnt +=1
        if cnt == 32:
            break
    dut.mem_wr_i.value = 0

    await tb.clkcycle(40)

    cnt = 0
    addr = 0
    dut.mem_wr_i.value = 0xF
    while True:
        dut.mem_addr_i.value = addr
        await tb.clkcycle(1)
        if dut.mem_accept_o.value:
            addr+=4
            cnt +=1
        if cnt == 32*4:
            break
    dut.mem_wr_i.value = 0


    await tb.clkcycle(200)


@cocotb.test(timeout_time=10, timeout_unit="ms", skip=True)
async def test_iob_random(dut):

    tb = TB(dut)
    cocotb.start_soon(tb.proc_req())
    cocotb.start_soon(tb.proc_rsp())
    cocotb.start_soon(tb.proc_check())
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    # fill in memory and ref block with random data
    for _ in range(0,ADDR_RANGE,4):
        v = random_int()
        tb.write_ref(_,v)
        tb.write_pool(_,v)

    #for _ in range(1000):
    #    tb.write(random_addr(),random_int())

    #for _ in range(1000):
    #    tb.read(random_addr())

    for _ in range(ADDR_RANGE//8):
        if random_int()%2 == 0:
            tb.write(random_addr(),random_int())
        else:
            tb.read(random_addr())

    # issue reads for entire memory range to do a final check
    for _ in range(0,ADDR_RANGE,4):
        tb.read(_)


    for _ in range(0,ADDR_RANGE,4):
        assert tb.read_ref(_) == tb.read_pool(_)


    #tb.read(4)
    #tb.read(8)
    #tb.read(12)
    #tb.write(32,0xDEADBEEF)
    #tb.read(32)

    #rsp = await tb.rsp_queue.get()
    #print(rsp)
    #rsp = await tb.rsp_queue.get()
    #print(rsp)
    #rsp = await tb.rsp_queue.get()
    #print(rsp)
    #rsp = await tb.rsp_queue.get()
    #print(rsp)

    while not tb.rsp_queue.empty() or not tb.req_queue.empty() or not tb.pend_queue.empty():
        await tb.clkcycle(10)


@cocotb.test(timeout_time=10, timeout_unit="ms", skip=False)
async def test_axi(dut):

    tb = TB(dut)
    cocotb.start_soon(tb.proc_req())
    cocotb.start_soon(tb.proc_rsp())
    cocotb.start_soon(tb.proc_check())
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    for _ in range(0,ADDR_RANGE,4):
        v = random_int()
        tb.write_ref(_,v)
        tb.write_pool(_,v)

    tb.read(random_addr())
    tb.read(random_addr())
    tb.read(random_addr())
    tb.write(random_addr(),random_int())
    tb.write(random_addr(),random_int())
    tb.write(random_addr(),random_int())
    #await tb.clkcycle(10)
    await tb.clkcycle(100)





@cocotb.test(timeout_time=10, timeout_unit="ms", skip=True)
async def test_decode(dut):

    tb = TB(dut)
    await tb.cycle_reset()
    dut.mem_data_wr_i.value = 0
    dut.mem_wr_i.value = 0
    dut.mem_addr_i.value = 0
    dut.mem_rd_i.value = 0
    await tb.clkcycle(10)

    for _ in range(0,ADDR_RANGE,4):
        v = random_int()
        tb.write_ref(_,v)
        tb.write_pool(_,v)


    dut.mem_addr_i.value = 0xA0000000
    dut.mem_rd_i.value = 1
    await tb.clkcycle(1)
    dut.mem_rd_i.value = 0
    await tb.clkcycle(1)

    dut.mem_addr_i.value = 0x80000000
    dut.mem_rd_i.value = 1
    await tb.clkcycle(1)
    dut.mem_rd_i.value = 0
    await tb.clkcycle(1)

    dut.mem_addr_i.value = 0x10000000
    dut.mem_rd_i.value = 1
    await tb.clkcycle(1)
    dut.mem_rd_i.value = 0
    await tb.clkcycle(1)

    await tb.clkcycle(100)
