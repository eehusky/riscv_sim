from __future__ import annotations
import logging

import mmap
from typing import NamedTuple
import warnings


warnings.simplefilter("ignore")

import os
import random

import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue, QueueEmpty
from cocotb.handle import HierarchyObject, Immediate
from cocotb.triggers import ClockCycles, RisingEdge
from cocotbext.axi import AddressSpace, MemoryInterface, MemoryRegion
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

class ReferenceMemoryRegion(MemoryRegion):
    def __init__(self, size=4096, mem=None, **kwargs):
        super().__init__(size, **kwargs)
        self.ref = mmap.mmap(-1, size)

    def random_addr(self):
        return self.base+random.randint(0,self.size-4) & 0xFFFFFFFC

    @property
    def end_addr(self):
        return self.base+self.size

    @property
    def last_addr(self):
        return self.base+self.size-4

    def iter_addrspace(self,step=4):
        for _ in range(self.base, self.end_addr, step):
            yield _

class VPIRegion(MemoryInterface):
    def __init__(self, vpiobj, **kwargs):
        self._width_bits = len(vpiobj[0])
        self._width_bytes = len(vpiobj[0])//8
        self._n_words = len(vpiobj)
        super().__init__(self._width_bytes * self._n_words, **kwargs)
        self._vpiobj = vpiobj

    def _read_local(self,addr:int):
        word = self._vpiobj[addr//4].value.to_unsigned()
        value = word >> ((addr%4)*8) & 0xFF
        return value

    def _write_local(self,addr:int, data:int):
        word = self._vpiobj[addr//4].value.to_unsigned()
        word &= ~(0xFF << ((addr%4)*8))
        word |= (data& 0xFF) << ((addr%4)*8)
        self._vpiobj[addr//4].value = Immediate(word)

    async def _read(self, address, length, **kwargs):
        rv = bytes([self._read_local(address+_) for _ in range(length)])
        #print(f"read {address=}, {length=} {rv=}")
        return rv

    async def _write(self, address, data, **kwargs):
        #print(f"write {address=}, {data=}")
        for ndx,_ in enumerate(data):
            self._write_local(address+ndx, _)

    def random_addr(self):
        return self.base+random.randint(0,self.size-4) & 0xFFFFFFFC

    @property
    def end_addr(self):
        return self.base+self.size

    @property
    def last_addr(self):
        return self.base+self.size-4

    def iter_addrspace(self,step=4):
        for _ in range(self.base, self.end_addr, step):
            yield _


class ReferenceVPIRegion(VPIRegion):
    def __init__(self, vpiobj, **kwargs):
        super().__init__(vpiobj, **kwargs)
        self.ref = mmap.mmap(-1, self.size)


class Request(NamedTuple):
    addr:int
    aid:int
    wdata:int
    wstrb:int

    @property
    def is_write(self):
        return self.wstrb !=0


class Response(NamedTuple):
    error: int
    rdata: int
    rid:int
    req: Request

REGIONS = [
    ("mtime",    0x0000_2000, "i_obi_mtime.mem"),
    ("simctrl",  0x0000_3000, "i_obi_simctrl.mem"),
    ("dtcm",     0x8002_0000, "i_obi_dtcm.mem"),
    ("cached",   0x9000_0000, "i_axi_cached_ram.mem"),
    ("uncached", 0xA000_0000, "i_axi_uncached_ram.mem"),
    ("axil",     0xB000_0000, "i_axil_ram.mem"),
]

INITIATORS = [
    ("xbar0",    "xbar_initiators", 0),
    ("xbar1",    "xbar_initiators", 1),
]

class OBI:
    def __init__(self, obi, tb, aid=0):
        self.aid = aid
        self.obi = obi

        self.clkcycle = tb.clkcycle
        self.rising_edge = tb.rising_edge
        self.read_ref = tb.read_ref
        self.write_ref = tb.write_ref

        self.req_queue:Queue[Request] = Queue()
        self.rsp_queue:Queue[Response] = Queue()
        self.pend_queue:Queue[Request] = Queue()

        cocotb.start_soon(self.proc_check())
        cocotb.start_soon(self.proc_rsp())
        cocotb.start_soon(self.proc_req())

    async def proc_check(self):
        while True:
            rsp:Response = await self.rsp_queue.get()
            req = rsp.req
            if rsp.error:
                continue
            assert req.aid == rsp.rid
            if not req.wstrb:
                ref = await self.read_ref(req.addr)
                #print(f"{req.addr:04X}: {rsp.rdata:08X} == {self.read_ref(req.addr):08X}")
                assert rsp.rdata == ref, f"{req.addr:04X}: {rsp.rdata:08X} == {ref:08X}"

    async def proc_rsp(self):
        rready = self.obi.rready
        rvalid = self.obi.rvalid
        rdata = self.obi.rdata
        err = self.obi.err
        rid = self.obi.rid

        rready.value = 1
        while True:
            if rready.value and rvalid.value:
                req = self.pend_queue.get_nowait()
                self.rsp_queue.put_nowait(Response(err.value,rdata.value.to_unsigned(),rid.value,req))
                if not err.value and req.is_write:
                    await self.write_ref(req.addr,req.wdata)
            await self.clkcycle()

    async def proc_req(self):
        req = self.obi.req
        gnt = self.obi.gnt
        addr = self.obi.addr
        we = self.obi.we
        be = self.obi.be
        wdata = self.obi.wdata
        aid = self.obi.aid

        NULL_REQ = Request(0,0,0,0)

        def get_next():
            try:
                return self.req_queue.get_nowait()
            except QueueEmpty:
                return NULL_REQ

        while True:
            await self.rising_edge
            if req.value and gnt.value or not req.value:
                reqobj = get_next()
                if reqobj is not NULL_REQ:
                    self.pend_queue.put_nowait(reqobj)
                req.value = 0 if reqobj is NULL_REQ else 1
                wdata.value = reqobj.wdata
                be.value = reqobj.wstrb
                addr.value = reqobj.addr
                we.value = 1 if reqobj.wstrb else 0
                aid.value = reqobj.aid


    def read(self,addr:int):
        self.req_queue.put_nowait((Request(addr,random.getrandbits(2),0,0)))

    def write(self,addr:int,data:int):
        self.req_queue.put_nowait((Request(addr,random.getrandbits(2),data,0xF)))

class TB:
    def __init__(self, dut):
        self.dut = dut
        logging.getLogger("cocotb.initialize").setLevel(logging.INFO)
        logging.getLogger("cocotb.regression").setLevel(logging.INFO)
        logging.getLogger("gpi").setLevel(logging.INFO)
        logging.getLogger("pygpi").setLevel(logging.INFO)

        self.reset = self.dut.rst_i
        self.clk = self.dut.clk_i
        self.rising_edge = RisingEdge(self.clk)
        cocotb.start_soon(Clock(self.clk, CLK_PERIOD, unit="ns", impl="gpi").start())

        self.addrspace = AddressSpace()
        self.regions = dict[str,ReferenceVPIRegion]()
        for name, base, vpi in REGIONS:
            self.regions[name] = ReferenceVPIRegion(getattr(dut,vpi))
            self.addrspace.register_region(self.regions[name],base)

    async def clkcycle(self, n=1):
        await ClockCycles(self.clk, n)

    async def cycle_reset(self):
        self.reset.value = 1
        await self.clkcycle(1)
        #self.dut.mem_data_wr_i.value = 0
        #self.dut.mem_wr_i.value = 0
        #self.dut.mem_addr_i.value = 0
        #self.dut.mem_rd_i.value = 0
        await self.clkcycle(10)
        self.reset.value = 0
        await self.clkcycle(10)
        logging.getLogger("cocotb.tb_dport.m_axi_cached").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_dport.m_axi_uncached").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_dport.m_axil").setLevel(logging.INFO)

    ##

    async  def write_pool(self,addr:int,data:int):
        await self.addrspace.write(addr,data.to_bytes(4,byteorder="little"))

    async def read_pool(self,addr:int):
        return int.from_bytes(await self.addrspace.read(addr,4),byteorder="little")

    async def write_ref(self,addr:int,data:int):
        base, size, translate, region = self.addrspace.find_regions(addr)[0]
        assert isinstance(region, ReferenceVPIRegion|ReferenceMemoryRegion)
        addr -= base
        region.ref[addr:addr+4] = data.to_bytes(4)

    async def read_ref(self,addr:int):
        base, size, translate, region = self.addrspace.find_regions(addr)[0]
        assert isinstance(region, ReferenceVPIRegion|ReferenceMemoryRegion)
        addr -= base
        return int.from_bytes(region.ref[addr:addr+4])

    def random_addr(self):
        region = random.choice(list(self.regions.values()))
        return region.random_addr()

    def iter_addrspace(self,step=4):
        for region in self.regions.values():
            yield from region.iter_addrspace(step)

## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------

def random_addr():
    return random.randint(0,(1<<16)-4) & 0xFFFFFFFC
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
