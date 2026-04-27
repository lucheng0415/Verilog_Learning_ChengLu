module apb_slave(apb_if.slave apb);
    // Register block: 8 registers of 32 bits each
    logic [31:0] registers [0:7];

    // Initialize registers to 0
    initial begin
        for (int i = 0; i < 8; i++) begin
            registers[i] = 32'h0;
        end
    end

    // APB slave logic
    always @(posedge apb.PCLK or negedge apb.PRESETn) begin
        if (!apb.PRESETn) begin
            apb.PRDATA  <= 32'h0;
            apb.PREADY  <= 1'b1;
            apb.PSLVERR <= 1'b0;
        end else begin
            if (apb.PSEL && apb.PENABLE) begin
                if (apb.PWRITE) begin
                    // Write operation
                    if (apb.PADDR[4:2] < 8) begin  // Address within range (32-bit aligned, 8 registers)
                        for (int i = 0; i < 4; i++) begin
                            if (apb.PSTRB[i]) begin
                                registers[apb.PADDR[4:2]][i*8 +: 8] <= apb.PWDATA[i*8 +: 8];
                            end
                        end
                        apb.PSLVERR <= 1'b0;
                    end else begin
                        apb.PSLVERR <= 1'b1;  // Address out of range
                    end
                end else begin
                    // Read operation
                    if (apb.PADDR[4:2] < 8) begin
                        apb.PRDATA <= registers[apb.PADDR[4:2]];
                        apb.PSLVERR <= 1'b0;
                    end else begin
                        apb.PRDATA <= 32'h0;
                        apb.PSLVERR <= 1'b1;
                    end
                end
                apb.PREADY <= 1'b1;  // No wait states for simplicity
            end else begin
                apb.PREADY <= 1'b1;
                apb.PSLVERR <= 1'b0;
            end
        end
    end
endmodule