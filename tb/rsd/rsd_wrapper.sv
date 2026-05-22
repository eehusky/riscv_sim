import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryTypes::*;
import MemoryMapTypes::*;
import IO_UnitTypes::*;
import DebugTypes::*;

module rsd_wrapper (
    input  logic         clk_i,
    input  logic         rst_i,
    obi_if.master        dport,
    output DebugRegister debugRegister
);
    logic          programLoaded;
    logic          memCLK;
    logic          locked;  // You must disable the reset signal (rst) after the clock generator is locked.
    logic          rst;
    logic          rstStart;
    logic          rstTrigger;
    logic          serialWE;
    SerialDataPath serialWriteData;
    logic          posResetOut;


    assign locked      = TRUE;

    // Generate a global reset signal 'rst' from 'rstTrigger'.
    assign posResetOut = rst;
    ResetController rstController (
        .clk       (clk_i),
        .rstTrigger(rst_i),
        .locked    (locked),
        .rst       (rst),
        .rstStart  (rstStart)
    );

    //
    // --- Memory and Program Loader
    //
    logic               memCaribrationDone;
    MemoryEntryDataPath memReadData;
    logic               memReadDataReady;
    logic               memAccessReadBusy;
    logic               memAccessWriteBusy;
    logic               memAccessBusy;
    MemoryEntryDataPath memAccessWriteData;
    MemoryEntryDataPath memAccessWriteDataFromCore;
    MemoryEntryDataPath memAccessWriteDataFromProgramLoader;
    AddrPath            memAccessAddr;
    AddrPath            memAccessAddrFromProgramLoader;
    PhyAddrPath         memAccessAddrFromCore;
    logic               memAccessRE;
    logic               memAccessRE_FromCore;
    logic               memAccessWE;
    logic               memAccessWE_FromCore;
    logic               memAccessWE_FromProgramLoader;
    MemAccessSerial     nextMemReadSerial;
    MemWriteSerial      nextMemWriteSerial;
    MemAccessSerial     memReadSerial;
    MemAccessResponse   memAccessResponse;

    Memory #(
        //.INIT_HEX_FILE("/home/rbriggin/github/eehusky/riscv_sim/sw/build/baremetal_demo.hex")
    ) memory (
        .clk               (clk_i),
        .rst               (rst),
        .memAccessAddr     (memAccessAddr),
        .memAccessWriteData(memAccessWriteData),
        .memAccessRE       (memAccessRE),
        .memAccessWE       (memAccessWE),
        .memAccessBusy     (memAccessBusy),
        .nextMemReadSerial (nextMemReadSerial),
        .nextMemWriteSerial(nextMemWriteSerial),
        .memReadDataReady  (memReadDataReady),
        .memReadData       (memReadData),
        .memReadSerial     (memReadSerial),
        .memAccessResponse (memAccessResponse)
    );

    assign memAccessReadBusy  = memAccessBusy;
    assign memAccessWriteBusy = memAccessBusy;
    assign memAccessAddr      = memAccessAddrFromCore;
    assign memAccessWriteData = memAccessWriteDataFromCore;
    assign memAccessRE        = memAccessRE_FromCore;
    assign memAccessWE        = memAccessWE_FromCore;
    assign programLoaded      = TRUE;
    assign reqExternalInterrupt  = FALSE;
    assign externalInterruptCode = 0;

    //memAccessBusy
    //nextMemReadSerial
    //nextMemWriteSerial
    //memReadDataReady
    //memReadData
    //memReadSerial
    //memAccessResponse

    PC_Path                   lastCommittedPC;
    logic                     reqExternalInterrupt;
    ExternalInterruptCodePath externalInterruptCode;

    //
    // --- Processor core
    //
    Core core (
        .clk                  (clk_i),
        .rst                  (rst || !programLoaded),
        .rstStart             (rstStart),
        //
        .memAccessAddr        (memAccessAddrFromCore),
        .memAccessWriteData   (memAccessWriteDataFromCore),
        .memAccessRE          (memAccessRE_FromCore),
        .memAccessWE          (memAccessWE_FromCore),
        .memAccessReadBusy    (memAccessReadBusy),
        .memAccessWriteBusy   (memAccessWriteBusy),
        .nextMemReadSerial    (nextMemReadSerial),
        .nextMemWriteSerial   (nextMemWriteSerial),
        .memReadDataReady     (memReadDataReady),
        .memReadData          (memReadData),
        .memReadSerial        (memReadSerial),
        .memAccessResponse    (memAccessResponse),
        //
        .reqExternalInterrupt (reqExternalInterrupt),
        .externalInterruptCode(externalInterruptCode),
        //
        .serialWE             (serialWE),
        .serialWriteData      (serialWriteData),
        //
        .lastCommittedPC      (lastCommittedPC),
        .debugRegister        (debugRegister)
    );

    always_comb begin
        if (lastCommittedPC == 'h1004) begin
            $finish;
        end
    end

    always_comb begin
        if (serialWE) begin
            $write("%c", serialWriteData[7:0]);
        end
    end


endmodule : rsd_wrapper

