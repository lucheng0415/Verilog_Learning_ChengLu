# ModelSim simulation script for APB testbench
# This script runs the simulation and generates a VCD waveform file

vlib work
vlog -sv tb/transaction.sv tb/driver.sv tb/monitor.sv tb/scoreboard.sv rtl/*.sv tb/tb.sv tb/test.sv

vsim -c tb

# Configure waveform capture
vcd file waveform.vcd
vcd add -r /tb/*
vcd add -r /tb/dut/*
vcd add -r /tb/t/*

# Run simulation
run -all

# Close VCD file
vcd close

quit
