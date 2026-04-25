import BasicTypes::*;
import CacheSystemTypes::*;
import MemoryTypes::*;
import MemoryMapTypes::*;
import IO_UnitTypes::*;
import DebugTypes::*;

module rsd_wrapper (
    input  logic         i_clk,
    input  logic         i_rst,
    output DebugRegister debugRegister,
    output Axi4MemoryIF  axi4MemoryIF
);
    logic         programLoaded;
    logic         memCLK;
    logic         locked;  // You must disable the reset signal (rst) after the clock generator is locked.
    logic         rst;
    logic         rstStart;
    logic         rstTrigger;
    logic serialWE;
    SerialDataPath serialWriteData;
    logic posResetOut;


    assign locked      = TRUE;

    // Generate a global reset signal 'rst' from 'rstTrigger'.
    assign posResetOut = rst;
    ResetController rstController (
        .clk       (i_clk),
        .rstTrigger(i_rst),
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


    Axi4Memory axi4Memory (
        .port              (axi4MemoryIF),
        .memAccessAddr     (memAccessAddr),
        .memAccessWriteData(memAccessWriteData),
        .memAccessRE       (memAccessRE),
        .memAccessWE       (memAccessWE),
        .memAccessReadBusy (memAccessReadBusy),
        .memAccessWriteBusy(memAccessWriteBusy),
        .nextMemReadSerial (nextMemReadSerial),
        .nextMemWriteSerial(nextMemWriteSerial),
        .memReadDataReady  (memReadDataReady),
        .memReadData       (memReadData),
        .memReadSerial     (memReadSerial),
        .memAccessResponse (memAccessResponse)
    );


    always_comb begin
        programLoaded      = TRUE;
        memAccessAddr      = memAccessAddrFromCore;
        memAccessWriteData = memAccessWriteDataFromCore;
        memAccessRE        = memAccessRE_FromCore;
        memAccessWE        = memAccessWE_FromCore;
    end

    PC_Path                   lastCommittedPC;
    logic                     reqExternalInterrupt;
    ExternalInterruptCodePath externalInterruptCode;
    always_comb begin
        reqExternalInterrupt  = FALSE;
        externalInterruptCode = 0;
    end

    //
    // --- Processor core
    //
    Core core (
        .clk                  (i_clk),
        .rst                  (rst || !programLoaded),
        .memAccessAddr        (memAccessAddrFromCore),
        .memAccessWriteData   (memAccessWriteDataFromCore),
        .memAccessRE          (memAccessRE_FromCore),
        .memAccessWE          (memAccessWE_FromCore),
        .memAccessReadBusy    (memAccessReadBusy),
        .memAccessWriteBusy   (memAccessWriteBusy),
        .reqExternalInterrupt (reqExternalInterrupt),
        .externalInterruptCode(externalInterruptCode),
        .nextMemReadSerial    (nextMemReadSerial),
        .nextMemWriteSerial   (nextMemWriteSerial),
        .memReadDataReady     (memReadDataReady),
        .memReadData          (memReadData),
        .memReadSerial        (memReadSerial),
        .memAccessResponse    (memAccessResponse),
        .rstStart             (rstStart),
        .serialWE             (serialWE),
        .serialWriteData      (serialWriteData),
        .lastCommittedPC      (lastCommittedPC),
        .debugRegister        (debugRegister)
    );

always_comb begin
    if (lastCommittedPC =='h1004)begin
        $finish;
    end
end

always_comb begin
    if (serialWE)begin
        $write("%c",serialWriteData[7:0]);
    end
end


endmodule : rsd_wrapper

