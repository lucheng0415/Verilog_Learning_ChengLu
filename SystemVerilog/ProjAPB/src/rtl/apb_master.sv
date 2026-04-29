module apb_master(apb_if.master apb);
    // Tasks for write and read
    task apb_write(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] strb = 4'b1111);
        // Setup phase
        apb.PSEL    <= 1'b1;
        apb.PENABLE <= 1'b0;
        apb.PWRITE  <= 1'b1;
        apb.PADDR   <= addr;
        apb.PWDATA  <= data;
        apb.PSTRB   <= strb;
        @(posedge apb.PCLK);

        // Access phase
        apb.PENABLE <= 1'b1;
        @(posedge apb.PCLK);

        // Wait for PREADY
        while (!apb.PREADY) begin
            @(posedge apb.PCLK);
        end

        // Idle
        apb.PSEL    <= 1'b0;
        apb.PENABLE <= 1'b0;
        @(posedge apb.PCLK);
    endtask

    task apb_read(input logic [31:0] addr, output logic [31:0] data);
        // Setup phase
        apb.PSEL    <= 1'b1;
        apb.PENABLE <= 1'b0;
        apb.PWRITE  <= 1'b0;
        apb.PADDR   <= addr;
        apb.PSTRB   <= 4'b1111;  // Not used for read
        @(posedge apb.PCLK);

        // Access phase
        apb.PENABLE <= 1'b1;
        @(posedge apb.PCLK);

        // Wait for PREADY
        while (!apb.PREADY) begin
            @(posedge apb.PCLK);
        end

        data = apb.PRDATA;

        // Idle
        apb.PSEL    <= 1'b0;
        apb.PENABLE <= 1'b0;
        @(posedge apb.PCLK);
    endtask

    // Initialize signals
    initial begin
        apb.PSEL    = 1'b0;
        apb.PENABLE = 1'b0;
        apb.PWRITE  = 1'b0;
        apb.PADDR   = 32'h0;
        apb.PWDATA  = 32'h0;
        apb.PSTRB   = 4'b1111;
    end
endmodule