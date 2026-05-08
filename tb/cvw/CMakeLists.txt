cmake_minimum_required(VERSION 3.5)
project(tb_wally)

#set(REPO_DIR                  ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
#set(BIRISCV                   ${REPO_DIR}/cores/biriscv)
#set(VERILOG_AXI $ENV{HOME}/github/alexforencich/verilog-axi/)

find_package(verilator
    NO_DEFAULT_PATH
    PATHS
        $ENV{VERILATOR_ROOT}
)

find_package(SystemCLanguage
    NO_DEFAULT_PATH
    PATHS
        $ENV{SYSTEMC}
)



set(CMAKE_CXX_STANDARD              ${SystemC_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED     ${SystemC_CXX_STANDARD_REQUIRED})
set(CMAKE_EXPORT_COMPILE_COMMANDS   "ON")
set(CXX_WARNING                     "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation")
set(CMAKE_CXX_FLAGS                 "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
#set(LD_FLAGS                        "")
#-O3 -flto
#-O3 -flto
#set(LD_FLAGS                        "-fwhole-program")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)
#string(STRIP ${LD_FLAGS}        LD_FLAGS)
#set(CMAKE_MODULE_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_SHARED_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_STATIC_LINKER_FLAGS   ${LD_FLAGS})
#set(CMAKE_EXE_LINKER_FLAGS      ${LD_FLAGS})

set(MY_VERILATOR_ARGS
    -O1
    --timescale-override 1ns/1ns
    --x-assign fast
    --x-initial fast
    #--noassert
    --decorations none
    -Wno-context
    #--Wall
    --report-unoptflat
    #--expand-limit 100000
    --trace-fst
    #--unroll-count 512
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd ${LD_FLAGS}"

    #--json-only-output tree_temp.json
    #--json-only-meta-output meta_temp.json
    #--bbox-sys
    #--bbox-unsup
    #--prefix vljson

)

set(WALLY /home/rbriggin/github/openhwgroup/cvw/)
set(WALLYCONF rv64i)

file(GLOB SOURCE_FILES ${WALLY}/src/*/*.sv ${WALLY}/src/*/*/*.sv)


add_executable(tb_wally
    elf_load.cpp
    sim_main.cpp
)

verilate(tb_wally
    PREFIX
        Vtb_wally
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${WALLY}/config/shared
        .
        #${WALLY}/config/${WALLYCONF}
        #${WALLY}/config/deriv/${WALLYCONF}
    TOP_MODULE
        tb_wally
    SOURCES
        ${WALLY}/src/cvw.sv
        ${SOURCE_FILES}
        #${WALLY}/addins/verilog-ethernet/*/*.sv
        #${WALLY}/addins/verilog-ethernet/*/*/*/*.sv

        #${WALLY}/testbench/${TESTBENCH}.sv
        #${WALLY}/testbench/common/*.sv
        tb_wally.sv
        tb_wally.vlt
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


#target_include_directories(tb_wally
#    PUBLIC
#        ${.}
#        ../common/
#)
