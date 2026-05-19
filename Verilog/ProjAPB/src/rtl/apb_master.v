// APB Master (Verilog rewrite of apb_master.sv)
// Flattened APB ports — no SystemVerilog interface/modport.
module apb_master (
    input  wire        PCLK,
    input  wire        PRESETn,
    output reg  [31:0] PADDR,
    output reg  [31:0] PWDATA,
    input  wire [31:0] PRDATA,
    output reg         PSEL,
    output reg         PENABLE,
    output reg         PWRITE,
    input  wire        PREADY,
    input  wire        PSLVERR,
    output reg  [3:0]  PSTRB
);

    // Write transfer: addr, data, byte-strobe
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            // Setup phase
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b1;
            PADDR   <= addr;
            PWDATA  <= data;
            PSTRB   <= strb;
            @(posedge PCLK);

            // Access phase
            PENABLE <= 1'b1;
            @(posedge PCLK);

            // Wait for PREADY
            while (!PREADY) begin
                @(posedge PCLK);
            end

            // Idle
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            @(posedge PCLK);
        end
    endtask

    // Read transfer: addr in, data out
    task apb_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            // Setup phase
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
            PADDR   <= addr;
            PSTRB   <= 4'b1111;  // unused for read
            @(posedge PCLK);

            // Access phase
            PENABLE <= 1'b1;
            @(posedge PCLK);

            // Wait for PREADY
            while (!PREADY) begin
                @(posedge PCLK);
            end

            data = PRDATA;

            // Idle
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            @(posedge PCLK);
        end
    endtask

    initial begin
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 32'h0;
        PWDATA  = 32'h0;
        PSTRB   = 4'b1111;
    end
endmodule
