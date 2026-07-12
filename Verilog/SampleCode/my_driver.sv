class my_driver extends uvm_driver;
    `uvm_component_utils(my_driver);
    function new(string name = "my_driver", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("my_driver", "new is called", UVM_LOW);
    endfunction
    extern virtual task main_phase(uvm_phase phase);
endclass

task my_driver::main_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("my_driver", "main_phase is called", UVM_LOW);
    // drive known idle values before reset deasserts to avoid X propagation into the DUT
    top_tb.rxd <= 8'b0;
    top_tb.rx_dv <= 1'b0;
    while(!top_tb.rst_n)
        @(posedge top_tb.clk);

    // send 256 random data to the DUT
    for(int i = 0; i < 256; i++)begin
       bit [7:0] data;
       @(posedge top_tb.clk);
       data = $urandom_range(0, 255);
       top_tb.rxd <= data;
       top_tb.rx_dv <= 1'b1;
       `uvm_info("my_driver", $sformatf("beat %0d: data drived = 0x%0h", i, data), UVM_LOW);
    end
    // deassert rx_dv one cycle after the last data beat to close out the transfer
    @(posedge top_tb.clk);
    top_tb.rx_dv <= 1'b0;
    phase.drop_objection(this);
endtask

class my_test extends uvm_test;
    `uvm_component_utils(my_test)
    my_driver drv;

    function new(string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = my_driver::type_id::create("drv", this);
    endfunction
endclass

`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
   
module top_tb;

reg clk;
reg rst_n;
reg[7:0] rxd;
reg rx_dv;
wire[7:0] txd;
wire tx_en;

dut my_dut(.clk(clk),
            .rst_n(rst_n),
            .rxd(rxd),
            .rx_dv(rx_dv),
            .txd(txd),
            .tx_en(tx_en));

initial begin
   clk = 0;
   forever begin
      #100 clk = ~clk;
   end
end

initial begin
    rst_n = 1'b0;
    #1000;
    rst_n = 1'b1;
end

initial begin
    run_test("my_test");
end

endmodule

