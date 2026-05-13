# RISCV Sim

This is a collection of odds and ends to make a up a full RISCV RTL simulation environment.  There isnt *much* original work here on my part besides providing the duct tape and string to tie all the parts and pieces together.

It has sort of evolved into a kind of goldilocks situation with RISCV cores, trying to find one that is easy to integrate, verilator compatible, and has the extensions I'm interested in.

For each core ive tried to makeup a baremetal demo application as well as a freertos demo application.  the ones that havent hit dealbreakers also get a ringbuffer demo application to see how well they play with using DMA (usually this is limited by the ability to do fine grained cache control ie flush/invalidate specific addresses.)

For the most part this should be completely sythensizable however ive taken some liberties in the area of setup/memory loading so at the moment there isnt any way to load an application when running on a piece of hardware.  If pressed, a UART/SPI2AXI connection that can tied into the memory complex to load the ITCM/DTCM should do the trick but isnt of particular interest at the moment.

## Errata

Notes and observations made in the pursuit of finding the perfect RISCV core

* openhwgroup/cv32e40pv2
    * this is pretty close
    * I wish it had the bit manipulation extension
    * The RVFI interface is kind of finicky and not easy to setup since its using some goofy timing features that verilator doesnt play well with.  Not a deal breaker but a bummer none the less.
* ultraembedded/biriscv
    * Vector Interrupts dont work
    * wfi doesnt wait for anything
    * mtime is csr based instead of mm and isnt 64 bits
    * the dcache line invalidate extension doesnt seem to work correctly
        * ```asm volatile("csrw pmpcfg2, %0" : : "r"(addr));```
        * this means when something is DMA'd into a cacheable region of ram you need to do a full dcache flush inorder to retrieve the contents instead of just invalidating the region of interest.
* openhwgroup/cva6 (todo)
    * Havent tried this one yet but i think this one will be pretty good.
    * RVFI is probably going to be a pain
* lowRISC/ibex (todo)
    * Havent tried this one yet but i think this one will be pretty good.
    * If this had a FPU i suspect this would be my winner
    * has ready to go RVFI
* ARM/DesignStart M0/M3 (todo)
* openhwgroup/CVW (abandoned)
    * uses AHB...i strongly dislike using AHB buses
    * Something in the Mult/Div extensions blows the verilation process up and takes ~15 minutes to finish
* rsd-devel/rsd (abandoned)
    * integration with external modules is sort of a hot mess.  spent an afternoon trying to do memory accesses outside of RAM and gave up on this one.



## FreeRTOS QEMU notes


export PATH=/opt/riscv/bin:$PATH
qemu-system-riscv32 -nographic -machine virt -net none \
  -chardev stdio,id=con,mux=on -serial chardev:con \
  -mon chardev=con,mode=readline -bios none \
  -smp 4 -kernel ./build/RTOSDemo.axf


## BIRISCV

Build the SOC testbench with ELF loader

```bash
make -C tb/biriscv/riscv_top
```

Build and run the FreeRTOS demo application

```bash
make make -C sw/ freertos
tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f sw/build/biriscv_freertos.elf
```

```
tb/biriscv/riscv_top/build/tb_biriscv_idcache_top -f sw/build/biriscv_freertos.elf
Memory: 0x80000000 - 0x800040d3 (Size=16KB) [.text]
Memory: 0x800040d4 - 0x80004143 (Size=0KB) [.data]
Memory: 0x80004150 - 0x8000a3e7 (Size=24KB) [.bss]
347: Hello FreeRTOS!
86435: 0: Tx: Transfer1
184756: 0: Rx: Blink1
190366: 0: Tx: Transfer2
283796: 0: Rx: Blink2
289057: 0: Tx: Transfer1
383627: 0: Rx: Blink1
388885: 0: Tx: Transfer2
483619: 0: Rx: Blink2
488855: 0: Tx: Transfer1
```




## Opensource RISCV Cores/Odds And Ends

### Cores

| ultraembedded |             |
|---------------|-------------|
| [riscv](https://github.com/ultraembedded/riscv)       | 2 stage, RV32IMZicsr            |
| [biriscv](https://github.com/ultraembedded/biriscv)   | 6 stage, dual issue RV32IMZicsr |

| rsd-devel     |             |
|---------------|-------------|
| [rsd](https://github.com/rsd-devel/rsd)               | RV32IMF     |

| lowRISC       |             |
|---------------|-------------|
| [ibex](https://github.com/lowRISC/ibex)               | RV32IMCB    |

| openhwgroup   |             |
|---------------|-------------|
| [CVA6](https://github.com/openhwgroup/cva6)           | 6-stage, application-class and embedded-class configurable core family         |
| [CVW](https://github.com/openhwgroup/cvw)             | 5-stage, application-class core with education focus                           |
| [CV32E40PV2](https://github.com/openhwgroup/cv32e40p) | 4-stage, embedded-class core extending CV32E40Pv1 with FPU and PULP extensions |
| [CV32E40S](https://github.com/openhwgroup/cv32e40s)   | 4-stage, embedded-class core with security focus                               |
| [CV32E20](https://github.com/openhwgroup/cve2)        | 2-stage, embedded-class microcontroller core and core complex                  |
| [CV32E40P](https://github.com/openhwgroup/cv32e40p)   | 4-stage, embedded-class core implementing PULP extensions at TRL5              |
| [CVA5](https://github.com/openhwgroup/cva5)           | 5-stage, FPGA-optimized application-class core at TRL3                         |
| [CV32E41P](https://github.com/openhwgroup/cv32e41p)   | 4-stage, embedded-class core prototyping Zfinx and Zce at TRL3                 |


### Cachii

* https://github.com/pulp-platform/axi_llc
* https://github.com/pulp-platform/ace
* https://github.com/IObundle/iob-cache

### DDR

* https://github.com/AngeloJacobo/UberDDR3

### AXI Plumbing

* https://github.com/ZipCPU/wb2axip
* https://github.com/alexforencich/verilog-axi
* https://github.com/pulp-platform/axi

### Software

* Simulator: https://github.com/verilator/verilator
* RISCV GCC Toolchain: https://github.com/riscv-collab/riscv-gnu-toolchain
* FreeRTOS: https://github.com/FreeRTOS/FreeRTOS
