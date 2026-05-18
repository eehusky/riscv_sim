from __future__ import annotations

import warnings


warnings.simplefilter("ignore")

import random

import cocotb
from rich import get_console

_print = print
print = get_console().print

from tb_dport import TB, REGIONS, OBI, random_int


@cocotb.test(timeout_time=100, timeout_unit="ms", skip=False)
@cocotb.parametrize(region_def=REGIONS)
async def test_demux_by_region(dut,region_def=REGIONS[0]):
    tb = TB(dut)
    obi = OBI(dut.initiator, tb, 0)

    await tb.cycle_reset()
    name, _,_  = region_def
    region = tb.regions[name]

    ## fill in memory and ref block with random data
    print("seed")
    for _ in range(region.base,region.end_addr,4):
        v = random_int()
        #await tb.write_ref(_,v)
        #await tb.write_pool(_,v)
        await tb.write_ref(_,_)
        await tb.write_pool(_,_)

    print("random")
    for _ in range(1000):
        if random.choice([True,False]):
            obi.write(region.random_addr(),random_int())
        else:
            obi.read(region.random_addr())

    print("wait random")
    for _ in range(1000):
        if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
            break
        await tb.clkcycle(100)
    else:
        print(f"{obi.rsp_queue.qsize()}")
        print(f"{obi.req_queue.qsize()}")
        print(f"{obi.pend_queue.qsize()}")
        assert obi.rsp_queue.empty()
        assert obi.req_queue.empty()
        assert obi.pend_queue.empty()

    await tb.clkcycle(100)

    ## issue reads for entire memory range to do a final check
    #print("readback")
    #for _ in range(region.base,region.end_addr,4):
    #    tb.read(_)

    ## wait for pipe line to clear
    print("wait readback")
    for _ in range(5000):
        if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
            break
        await tb.clkcycle(100)
    else:
        print(f"{obi.rsp_queue.qsize()}")
        print(f"{obi.req_queue.qsize()}")
        print(f"{obi.pend_queue.qsize()}")
        assert obi.rsp_queue.empty()
        assert obi.req_queue.empty()
        assert obi.pend_queue.empty()

    ## check the memory pool against the reference pool
    print("verify")
    for _ in range(region.base,region.end_addr,4):
        ref= await tb.read_ref(_)
        pool = await tb.read_pool(_)
        assert ref == pool, f"{_:04X}: {ref:08X} == {pool:08x}"

    await tb.clkcycle(1000)


@cocotb.test(timeout_time=100, timeout_unit="ms", skip=False)
async def test_demux_addrspace(dut):
    tb = TB(dut)
    obi = OBI(dut.initiator, tb, 0)
    await tb.cycle_reset()

    ## fill in memory and ref block with random data
    print("seed")
    for _ in tb.iter_addrspace():
        v = random_int()
        #await tb.write_ref(_,v)
        #await tb.write_pool(_,v)
        await tb.write_ref(_,_)
        await tb.write_pool(_,_)

    print("random")
    for _ in range(1000):
        if random.choice([True,False]):
            obi.write(tb.random_addr(),random_int())
        else:
            obi.read(tb.random_addr())
        #await tb.clkcycle(2)

    print("wait random")
    for _ in range(5000):
        if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
            break
        await tb.clkcycle(100)
    else:
        print(f"{obi.rsp_queue.qsize()}")
        print(f"{obi.req_queue.qsize()}")
        print(f"{obi.pend_queue.qsize()}")
        assert obi.rsp_queue.empty()
        assert obi.req_queue.empty()
        assert obi.pend_queue.empty()

    await tb.clkcycle(100)

    ## issue reads for entire memory range to do a final check
    #print("readback")
    #for _ in tb.iter_addrspace():
    #    tb.read(_)

    ## wait for pipe line to clear
    print("wait readback")
    for _ in range(5000):
        if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
            break
        await tb.clkcycle(100)
    else:
        print(f"{obi.rsp_queue.qsize()}")
        print(f"{obi.req_queue.qsize()}")
        print(f"{obi.pend_queue.qsize()}")
        assert obi.rsp_queue.empty()
        assert obi.req_queue.empty()
        assert obi.pend_queue.empty()

    ## check the memory pool against the reference pool
    print("verify")
    for _ in tb.iter_addrspace():
        ref= await tb.read_ref(_)
        pool = await tb.read_pool(_)
        assert ref == pool, f"{_:04X}: {ref:08X} == {pool:08x}"

    await tb.clkcycle(1000)


@cocotb.test(timeout_time=100, timeout_unit="ms", skip=False)
async def test_demux_oob(dut):
    tb = TB(dut)
    obi = OBI(dut.initiator, tb, 0)
    await tb.cycle_reset()

    print("seed")
    for _ in tb.iter_addrspace():
        v = random_int()
        await tb.write_ref(_,_)
        await tb.write_pool(_,_)


    obi.write(0,random_int())
    obi.read(0)

    print("wait readback")
    for _ in range(5000):
        if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
            break
        await tb.clkcycle(100)
    else:
        print(f"{obi.rsp_queue.qsize()}")
        print(f"{obi.req_queue.qsize()}")
        print(f"{obi.pend_queue.qsize()}")
        assert obi.rsp_queue.empty()
        assert obi.req_queue.empty()
        assert obi.pend_queue.empty()



@cocotb.test(timeout_time=100, timeout_unit="ms", skip=False)
async def test_mux_1(dut):
    tb = TB(dut)
    obis = [
        OBI(dut.initiators[0], tb, 0),
        OBI(dut.initiators[1], tb, 1),
        OBI(dut.initiators[2], tb, 2),
        #OBI(dut.initiators[3], tb, 3),
    ]
    #obi = obis[1]
    name, _,_  = REGIONS[0]
    region = tb.regions[name]

    await tb.cycle_reset()

    for _ in obis:
        _.read(region.random_addr())

    for _ in range(1000):
        obi = random.choice(obis)
        if random.choice([True,False]):
            obi.write(region.random_addr(),random_int())
        else:
            obi.read(region.random_addr())
        await tb.clkcycle(1)


    await tb.clkcycle(1000)
    #print("wait readback")
    #for _ in range(5000):
    #    if obi.rsp_queue.empty() and obi.req_queue.empty() and obi.pend_queue.empty():
    #        break
    #    await tb.clkcycle(100)
    #else:
    #    print(f"{obi.rsp_queue.qsize()}")
    #    print(f"{obi.req_queue.qsize()}")
    #    print(f"{obi.pend_queue.qsize()}")
    #    assert obi.rsp_queue.empty()
    #    assert obi.req_queue.empty()
    #    assert obi.pend_queue.empty()
