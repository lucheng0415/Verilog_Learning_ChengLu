class apb_driver;
    virtual apb_if.master vif;

    function new(virtual apb_if.master vif);
        this.vif = vif;
    endfunction

    task apb_write(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] strb = 4'b1111);
        // Setup phase
        vif.PSEL    <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= 1'b1;
        vif.PADDR   <= addr;
        vif.PWDATA  <= data;
        vif.PSTRB   <= strb;
        @(posedge vif.PCLK);

        // Access phase
        vif.PENABLE <= 1'b1;
        @(posedge vif.PCLK);

        // Wait for PREADY
        while (!vif.PREADY) begin
            @(posedge vif.PCLK);
        end

        // Idle
        vif.PSEL    <= 1'b0;
        vif.PENABLE <= 1'b0;
        @(posedge vif.PCLK);
    endtask

    task apb_read(input logic [31:0] addr, output logic [31:0] data);
        // Setup phase
        vif.PSEL    <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= 1'b0;
        vif.PADDR   <= addr;
        vif.PSTRB   <= 4'b1111;
        @(posedge vif.PCLK);

        // Access phase
        vif.PENABLE <= 1'b1;
        @(posedge vif.PCLK);

        // Wait for PREADY
        while (!vif.PREADY) begin
            @(posedge vif.PCLK);
        end

        data = vif.PRDATA;

        // Idle
        vif.PSEL    <= 1'b0;
        vif.PENABLE <= 1'b0;
        @(posedge vif.PCLK);
    endtask
endclass