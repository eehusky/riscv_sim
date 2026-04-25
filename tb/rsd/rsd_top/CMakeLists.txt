cmake_minimum_required(VERSION 3.5)
project(tb_rsd_top)

set(REPO_DIR    ${CMAKE_CURRENT_SOURCE_DIR}/../../../)
set(RSD         $ENV{HOME}/github/rsd-devel/rsd/)
set(VERILOG_AXI $ENV{HOME}/github/alexforencich/verilog-axi/)

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
set(CXX_WARNING                     "-Wall -Wno-sign-compare -Wno-unused-variable -Wno-bool-operation -Wno-unused-but-set-variable")
set(CMAKE_CXX_FLAGS                 "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")
set(CMAKE_C_FLAGS                   "-Og -fstrict-aliasing -march=native ${CXX_WARNING}")

string(STRIP ${CMAKE_CXX_FLAGS} CMAKE_CXX_FLAGS)
string(STRIP ${CMAKE_C_FLAGS}   CMAKE_C_FLAGS)

set(RSD_SRC_CFG                 +define+RSD_MARCH_INT_ISSUE_WIDTH=2 +define+RSD_MARCH_FP_PIPE +define+RSD_ENABLE_ZBA +define+RSD_ENABLE_ZICOND)
set(RSD_VERILATOR_DEFINITION    +define+RSD_FUNCTIONAL_SIMULATION +define+RSD_FUNCTIONAL_SIMULATION_VERILATOR)

set(MY_VERILATOR_ARGS
    -O1
    --timescale-override 1ns/1ns
    #--x-assign fast
    #--x-initial fast
    #--noassert
    #--decorations none
    -Wno-context
    #--Wall
    --report-unoptflat
    #--expand-limit 100000
    --trace-fst
    #--unroll-count 512
    +incdir+.
    -CFLAGS "${CMAKE_CXX_FLAGS}"
    -LDFLAGS "-lelf -lbfd"
    +define+RSD_FUNCTIONAL_SIMULATION
    +define+RSD_FUNCTIONAL_SIMULATION_VERILATOR
    +define+RSD_MARCH_INT_ISSUE_WIDTH=2
    +define+RSD_MARCH_FP_PIPE
    +define+RSD_ENABLE_ZBA
    +define+RSD_ENABLE_ZICOND
    -Wno-WIDTH
    -Wno-INITIALDLY
    -Wno-UNOPTFLAT
    -output-split 15000
    #${RSD_SRC_CFG}
    #${RSD_VERILATOR_DEFINITION}
    #--json-only-output tree_temp.json
    #--json-only-meta-output meta_temp.json
    #--bbox-sys
    #--bbox-unsup
    #--prefix vljson

)


add_executable(tb_rsd_top
    ${REPO_DIR}/tb/biriscv/common/elf_load.cpp
    sim_main.cpp
)

set(RSD_SRC         $ENV{HOME}/github/rsd-devel/rsd/Processor/Src/)
verilate(tb_rsd_top
    PREFIX
        Vtb_rsd_top
    OPT_GLOBAL
        ${CMAKE_CXX_FLAGS}
    OPT_SLOW
        ${CMAKE_CXX_FLAGS}
    OPT_FAST
        ${CMAKE_CXX_FLAGS}
    INCLUDE_DIRS
        ${RSD}/Processor/Src/
    TOP_MODULE
        tb_rsd_top
    SOURCES
        ${RSD_SRC}/MicroArchConf.sv
        ${RSD_SRC}/BasicTypes.sv
        ${RSD_SRC}/Memory/MemoryMapTypes.sv
        ${RSD_SRC}/RenameLogic/ActiveListIndexTypes.sv
        ${RSD_SRC}/Cache/CacheSystemTypes.sv
        ${RSD_SRC}/Memory/MemoryTypes.sv
        ${RSD_SRC}/Decoder/OpFormat.sv
        ${RSD_SRC}/Decoder/MicroOp.sv
        ${RSD_SRC}/RegisterFile/BypassTypes.sv
        ${RSD_SRC}/FetchUnit/FetchUnitTypes.sv
        ${RSD_SRC}/FloatingPointUnit/FPUTypes.sv
        ${RSD_SRC}/LoadStoreUnit/LoadStoreUnitTypes.sv
        ${RSD_SRC}/RenameLogic/RenameLogicTypes.sv
        ${RSD_SRC}/Scheduler/SchedulerTypes.sv
        ${RSD_SRC}/Pipeline/PipelineTypes.sv
        ${RSD_SRC}/IO/IO_UnitTypes.sv
        ${RSD_SRC}/Privileged/CSR_UnitTypes.sv
        ${RSD_SRC}/Debug/DebugTypes.sv
        ${RSD_SRC}/Main_Zynq_Wrapper.sv
        ${RSD_SRC}/Main_Zynq.sv
        ${RSD_SRC}/Memory/Axi4LiteControlRegisterIF.sv
        ${RSD_SRC}/Memory/Axi4LiteControlRegister.sv
        ${RSD_SRC}/Memory/ControlQueue.sv
        ${RSD_SRC}/Memory/Axi4Memory.sv
        ${RSD_SRC}/Memory/Axi4MemoryIF.sv
        ${RSD_SRC}/Memory/MemoryReadReqQueue.sv
        ${RSD_SRC}/Memory/MemoryWriteDataQueue.sv
        ${RSD_SRC}/Memory/MemoryLatencySimulator.sv
        ${RSD_SRC}/Core.sv
        ${RSD_SRC}/Pipeline/FetchStage/NextPCStage.sv
        ${RSD_SRC}/Pipeline/FetchStage/NextPCStageIF.sv
        ${RSD_SRC}/Pipeline/FetchStage/FetchStage.sv
        ${RSD_SRC}/Pipeline/FetchStage/FetchStageIF.sv
        ${RSD_SRC}/Pipeline/FetchStage/PC.sv
        ${RSD_SRC}/Pipeline/PreDecodeStage.sv
        ${RSD_SRC}/Pipeline/PreDecodeStageIF.sv
        ${RSD_SRC}/Pipeline/DecodeStage.sv
        ${RSD_SRC}/Pipeline/DecodeStageIF.sv
        ${RSD_SRC}/Pipeline/RenameStage.sv
        ${RSD_SRC}/Pipeline/RenameStageIF.sv
        ${RSD_SRC}/Pipeline/DispatchStage.sv
        ${RSD_SRC}/Pipeline/DispatchStageIF.sv
        ${RSD_SRC}/Pipeline/ScheduleStage.sv
        ${RSD_SRC}/Pipeline/ScheduleStageIF.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerIssueStage.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerIssueStageIF.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerRegisterReadStage.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerRegisterReadStageIF.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerExecutionStageIF.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerExecutionStage.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerRegisterWriteStageIF.sv
        ${RSD_SRC}/Pipeline/IntegerBackEnd/IntegerRegisterWriteStage.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerIssueStage.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerIssueStageIF.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterReadStage.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterReadStageIF.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerExecutionStageIF.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerExecutionStage.sv
        ${RSD_SRC}/Pipeline/ComplexIntegerBackEnd/ComplexIntegerRegisterWriteStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryIssueStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryIssueStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryRegisterReadStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryRegisterReadStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryExecutionStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryExecutionStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryAccessStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryAccessStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryTagAccessStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryTagAccessStage.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryRegisterWriteStageIF.sv
        ${RSD_SRC}/Pipeline/MemoryBackEnd/MemoryRegisterWriteStage.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPIssueStage.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPIssueStageIF.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPRegisterReadStage.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPRegisterReadStageIF.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPExecutionStageIF.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPExecutionStage.sv
        ${RSD_SRC}/Pipeline/FPBackEnd/FPRegisterWriteStage.sv
        ${RSD_SRC}/Pipeline/CommitStageIF.sv
        ${RSD_SRC}/Pipeline/CommitStage.sv
        ${RSD_SRC}/RegisterFile/RegisterFile.sv
        ${RSD_SRC}/RegisterFile/RegisterFileIF.sv
        ${RSD_SRC}/RegisterFile/BypassController.sv
        ${RSD_SRC}/RegisterFile/BypassNetwork.sv
        ${RSD_SRC}/RegisterFile/BypassNetworkIF.sv
        ${RSD_SRC}/ExecUnit/BitCounter.sv
        ${RSD_SRC}/ExecUnit/IntALU.sv
        ${RSD_SRC}/ExecUnit/Shifter.sv
        ${RSD_SRC}/ExecUnit/MultiplierUnit.sv
        ${RSD_SRC}/ExecUnit/PipelinedRefDivider.sv
        ${RSD_SRC}/ExecUnit/DividerUnit.sv
        ${RSD_SRC}/MulDivUnit/MulDivUnitIF.sv
        ${RSD_SRC}/MulDivUnit/MulDivUnit.sv
        ${RSD_SRC}/LoadStoreUnit/LoadStoreUnit.sv
        ${RSD_SRC}/LoadStoreUnit/LoadStoreUnitIF.sv
        ${RSD_SRC}/LoadStoreUnit/LoadQueue.sv
        ${RSD_SRC}/LoadStoreUnit/StoreQueue.sv
        ${RSD_SRC}/LoadStoreUnit/StoreCommitter.sv
        ${RSD_SRC}/FloatingPointUnit/FP32PipelinedAdder.sv
        ${RSD_SRC}/FloatingPointUnit/FP32PipelinedMultiplier.sv
        ${RSD_SRC}/FloatingPointUnit/FP32PipelinedFMA.sv
        ${RSD_SRC}/FloatingPointUnit/FP32PipelinedOther.sv
        ${RSD_SRC}/FloatingPointUnit/FP32DivSqrter.sv
        ${RSD_SRC}/FloatingPointUnit/FPDivSqrtUnit.sv
        ${RSD_SRC}/FloatingPointUnit/FPDivSqrtUnitIF.sv
        ${RSD_SRC}/RenameLogic/RenameLogic.sv
        ${RSD_SRC}/RenameLogic/RenameLogicIF.sv
        ${RSD_SRC}/RenameLogic/ActiveListIF.sv
        ${RSD_SRC}/RenameLogic/ActiveList.sv
        ${RSD_SRC}/RenameLogic/RMT.sv
        ${RSD_SRC}/RenameLogic/RetirementRMT.sv
        ${RSD_SRC}/RenameLogic/RenameLogicCommitter.sv
        ${RSD_SRC}/Decoder/Decoder.sv
        ${RSD_SRC}/Decoder/DecodedBranchResolver.sv
        ${RSD_SRC}/FetchUnit/BTB.sv
        ${RSD_SRC}/FetchUnit/BranchPredictor.sv
        ${RSD_SRC}/FetchUnit/Gshare.sv
        ${RSD_SRC}/FetchUnit/Bimodal.sv
        ${RSD_SRC}/Scheduler/SchedulerIF.sv
        ${RSD_SRC}/Scheduler/IssueQueue.sv
        ${RSD_SRC}/Scheduler/ReplayQueue.sv
        ${RSD_SRC}/Scheduler/WakeupSelectIF.sv
        ${RSD_SRC}/Scheduler/DestinationRAM.sv
        ${RSD_SRC}/Scheduler/ReadyBitTable.sv
        ${RSD_SRC}/Scheduler/Scheduler.sv
        ${RSD_SRC}/Scheduler/SelectLogic.sv
        ${RSD_SRC}/Scheduler/SourceCAM.sv
        ${RSD_SRC}/Scheduler/WakeupLogic.sv
        ${RSD_SRC}/Scheduler/WakeupPipelineRegister.sv
        ${RSD_SRC}/Scheduler/ProducerMatrix.sv
        ${RSD_SRC}/Scheduler/MemoryDependencyPredictor.sv
        ${RSD_SRC}/Cache/CacheSystemIF.sv
        ${RSD_SRC}/Cache/DCache.sv
        ${RSD_SRC}/Cache/DCacheIF.sv
        ${RSD_SRC}/Cache/ICache.sv
        ${RSD_SRC}/Cache/MemoryAccessController.sv
        ${RSD_SRC}/Cache/CacheFlushManager.sv
        ${RSD_SRC}/Cache/CacheFlushManagerIF.sv
        ${RSD_SRC}/Memory/Memory.sv
        ${RSD_SRC}/Recovery/RecoveryManager.sv
        ${RSD_SRC}/Recovery/RecoveryManagerIF.sv
        ${RSD_SRC}/ControllerIF.sv
        ${RSD_SRC}/Controller.sv
        ${RSD_SRC}/ResetController.sv
        ${RSD_SRC}/Privileged/InterruptController.sv
        ${RSD_SRC}/Privileged/CSR_Unit.sv
        ${RSD_SRC}/Privileged/CSR_UnitIF.sv
        ${RSD_SRC}/IO/IO_Unit.sv
        ${RSD_SRC}/IO/IO_UnitIF.sv
        ${RSD_SRC}/Primitives/FlipFlop.sv
        ${RSD_SRC}/Primitives/FreeList.sv
        ${RSD_SRC}/Primitives/Queue.sv
        ${RSD_SRC}/Primitives/RAM.sv
        ${RSD_SRC}/Primitives/LRU_Counter.sv
        ${RSD_SRC}/Primitives/Picker.sv
        ${RSD_SRC}/Primitives/Multiplier.sv
        ${RSD_SRC}/Primitives/Divider.sv
        ${RSD_SRC}/Debug/Debug.sv
        ${RSD_SRC}/Debug/DebugIF.sv
        ${RSD_SRC}/Debug/PerformanceCounter.sv
        ${RSD_SRC}/Debug/PerformanceCounterIF.sv
        ${RSD_SRC}/SysDeps/Verilator/VerilatorHelper.sv
        ##
        ${VERILOG_AXI}/rtl/axi_ram.v
        ${VERILOG_AXI}/rtl/axi_crossbar.v
        ${VERILOG_AXI}/rtl/axi_crossbar_wr.v
        ${VERILOG_AXI}/rtl/axi_crossbar_rd.v
        ${VERILOG_AXI}/rtl/axi_crossbar_addr.v
        ${VERILOG_AXI}/rtl/axi_register_rd.v
        ${VERILOG_AXI}/rtl/axi_register_wr.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_wr.v
        ${VERILOG_AXI}/rtl/axi_axil_adapter_rd.v
        ${VERILOG_AXI}/rtl/arbiter.v
        ${VERILOG_AXI}/rtl/priority_encoder.v
        ##
        ${REPO_DIR}/rtl/soc_mem.vlt
        ${REPO_DIR}/rtl/rsd_soc_mem.sv
        ${REPO_DIR}/rtl/axi_crossbar_wrap_2x2.v
        ##
        ${REPO_DIR}/rtl/rsd_wrapper.sv
        tb_rsd_top.sv
        #
    VERILATOR_ARGS
        ${MY_VERILATOR_ARGS}
)


target_include_directories(tb_rsd_top
    PUBLIC
        SystemC::systemc
        ${.}
        ../../biriscv/common/
)
