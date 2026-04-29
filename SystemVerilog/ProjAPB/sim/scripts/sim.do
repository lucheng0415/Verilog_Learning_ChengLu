# ModelSim simulation script for APB testbench
# This script runs the simulation and generates a VCD waveform file
# Run from: SystemVerilog/ProjAPB directory

vlib work
vlog -sv src/tb/transaction.sv src/tb/driver.sv src/tb/monitor.sv src/tb/scoreboard.sv src/rtl/*.sv src/tb/tb.sv src/tb/test.sv

vsim -c tb

# Configure waveform capture
vcd file sim/waveforms/waveform.vcd
vcd add -r /tb/*
vcd add -r /tb/dut/*
vcd add -r /tb/t/*

# Run simulation
run -all

# Close VCD file
vcd close

quit
