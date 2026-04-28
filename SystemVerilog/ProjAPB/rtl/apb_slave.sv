module apb_slave(apb_if.slave apb);
    // Register block: 8 registers of 32 bits each
    logic [31:0] registers [0:7];

    // Initialize registers to 0
    initial begin
        for (int i = 0; i < 8; i++) begin
            registers[i] = 32'h0;
        end
    end

    // APB slave logic - combinational for immediate response
    always_comb begin
        apb.PREADY = 1'b1;  // Default no wait states
        apb.PSLVERR = 1'b0;
        apb.PRDATA = 32'h0;

        if (apb.PSEL && apb.PENABLE) begin
            if (apb.PWRITE) begin
                // Write operation - check address
                if (apb.PADDR[4:2] >= 8) begin
                    apb.PSLVERR = 1'b1;
                end
            end else begin
                // Read operation
                if (apb.PADDR[4:2] < 8) begin
                    apb.PRDATA = registers[apb.PADDR[4:2]];
                end else begin
                    apb.PSLVERR = 1'b1;
                end
            end
        end
    end

    // Write logic - synchronous
    always @(posedge apb.PCLK or negedge apb.PRESETn) begin
        if (!apb.PRESETn) begin
            for (int i = 0; i < 8; i++) begin
                registers[i] <= 32'h0;
            end
        end else if (apb.PSEL && apb.PENABLE && apb.PWRITE && apb.PREADY) begin
            if (apb.PADDR[4:2] < 8) begin
                for (int i = 0; i < 4; i++) begin
                    if (apb.PSTRB[i]) begin
                        registers[apb.PADDR[4:2]][i*8 +: 8] <= apb.PWDATA[i*8 +: 8];
                    end
                end
            end
        end
    end
endmodule