## Errata

 * biriscv
   * AXI interfaces are only 32 bit
   * Vector Interrupts dont work
   * wfi doesnt wait for anything
   * mtime is csr based instead of mm and isnt 64 bits

## FreeRTOS notes


export PATH=/opt/riscv/bin:$PATH
qemu-system-riscv32 -nographic -machine virt -net none \
  -chardev stdio,id=con,mux=on -serial chardev:con \
  -mon chardev=con,mode=readline -bios none \
  -smp 4 -kernel ./build/RTOSDemo.axf
