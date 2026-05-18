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
