debug_level 2
adapter speed     10000

adapter driver remote_bitbang
remote_bitbang host localhost
remote_bitbang port 44853
transport select jtag

set _CHIPNAME riscv
jtag newtap $_CHIPNAME cpu -irlen 5
# -expected-id 0x249511C3

foreach t [jtag names] {
    puts [format "TAP: %s\n" $t]
}

set _TARGETNAME $_CHIPNAME.cpu
#target create $_TARGETNAME riscv -chain-position $_TARGETNAME -coreid 0x3e0
target create $_TARGETNAME riscv -chain-position $_TARGETNAME -rtos none

riscv set_command_timeout_sec 2000
# prefer to use sba for system bus access
#riscv set_prefer_sba on

# dump jtag chain
scan_chain

init
halt

riscv info
echo "Ready for Remote Connections"
