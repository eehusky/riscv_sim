from __future__ import annotations

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
from cocotb.handle import HierarchyObject
from cocotb.triggers import ClockCycles, Combine, RisingEdge, ValueChange
from cocotbext.axi import AxiBus, AxiLiteBus, AxiResp, AxiSlave, AxiMaster, AxiLiteSlave, MemoryRegion, Pool
from rich import get_console
from rich.text import Text
from rich.tree import Tree

_print = print
print = get_console().print


CLK_PERIOD = 10


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


class TB:
    def __init__(self, dut):
        self.dut = dut
        tb_loglevel = logging.FATAL
        reg_loglevel = logging.FATAL
        axi_loglevel = logging.FATAL

        self.reset = self.dut.i_reset
        self.clk = self.dut.i_clk
        cocotb.start_soon(Clock(self.clk, CLK_PERIOD, unit="ns", impl="gpi").start())

        logging.getLogger("cocotb.tb_soc_top.s_data_axi").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_soc_top.s_instr_axi").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_soc_top.s_axi").setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb_soc_top.m_axil").setLevel(logging.WARNING)
        #self.axi_logger.setLevel(logging.WARNING)
        logging.getLogger("cocotb.tb").setLevel(tb_loglevel)

        self.pool = Pool(parent=None, base=0, size=4096 * 32)
        self.pool.alloc_region((1<<16))
        self.pool.alloc_region((1<<16))


        self.s_data_axi = AxiMaster(
            bus=AxiBus.from_prefix(dut, "s_data_axi"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
        )
        self.s_instr_axi = AxiMaster(
            bus=AxiBus.from_prefix(dut, "s_instr_axi"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
        )
        self.s_axi = AxiMaster(
            bus=AxiBus.from_prefix(dut, "s_axi"),
            clock=self.clk,
            reset=self.reset,
            reset_active_level=True,
        )
        self.m_axil = AxiLiteSlave(
            bus=AxiLiteBus.from_prefix(dut, "m_axil"),
            clock=self.clk,
            reset=self.reset,
            target=self.pool,
            reset_active_level=True,
        )

    async def clkcycle(self, n=1):
        await ClockCycles(self.clk, n)

    async def cycle_reset(self):
        self.reset.value = 1

        await self.clkcycle(10)
        self.reset.value = 0
        await self.clkcycle(10)
        #self.axi_logger.setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_soc_top.s_data_axi").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_soc_top.s_instr_axi").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_soc_top.s_axi").setLevel(logging.INFO)
        logging.getLogger("cocotb.tb_soc_top.m_axil").setLevel(logging.INFO)

## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------
## ----------------------------------------------------------------------------


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



@cocotb.test(timeout_time=10, timeout_unit="ms", skip=False, name=testname("test_init"))
async def test_init(dut):
    tb = TB(dut)
    await tb.cycle_reset()
    await tb.clkcycle(100)



    await tb.s_axi.read(0x00000000,16)
    await tb.clkcycle(100)
    await tb.s_data_axi.read(0x00000000,16)
    await tb.clkcycle(100)
    await tb.s_instr_axi.read(0x00000000,16)
    await tb.clkcycle(100)

    await tb.s_axi.read(1<<16,4)
    await tb.clkcycle(100)
    await tb.s_data_axi.read(1<<16,4)
    await tb.clkcycle(100)
    await tb.s_instr_axi.read(1<<16,4)
    await tb.clkcycle(100)

    await Combine(*[cocotb.start_soon(tb.s_data_axi.read(0x00000000,4)) for _ in range(4)])

    await tb.clkcycle(100)


async def read(master:AxiMaster, address, length, **kwargs)->bytes:
    resp = await master.read(address, length, **kwargs)
    assert isinstance(resp,AxiReadResp)
    assert resp.resp == AxiResp.OKAY
    assert len(resp.data) == length
    return resp.data

async def write(master:AxiMaster, address, data, **kwargs):
    resp = await master.write(address, data, **kwargs)
    assert isinstance(resp,AxiWriteResp)
    assert resp.resp == AxiResp.OKAY


@cocotb.test(timeout_time=10, timeout_unit="ms", skip=False, name=testname("test_regions"))
async def test_regions(dut):
    tb = TB(dut)
    await tb.cycle_reset()
    await tb.clkcycle(100)

    # 0 ( 0): 00000000 / 16 -- 00000000-0000ffff
    # 1 ( 0): 00010000 / 16 -- 00010000-0001ffff

    ranges = [
        (0x00000000,0x0000ffff, [tb.s_data_axi, tb.s_instr_axi, tb.s_axi ] ),
        (0x00010000,0x0001ffff, [tb.s_data_axi, ] ),
    ]

    for low, high, masters in ranges:
        for master in masters:
            await read(master,low,4)
            await read(master,(high+1)-4,4)

    for low, high, masters in ranges:
        for master in masters:
            payload = random.randbytes(4)
            await write(master,low,payload)
            assert await read(master,low,4) == payload
            payload = random.randbytes(4)
            await write(master,(high+1)-4,payload)
            assert await read(master,(high+1)-4,4)== payload
