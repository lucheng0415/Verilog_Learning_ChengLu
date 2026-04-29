#!/bin/bash
# Script to view waveforms with GTKWave

if command -v gtkwave &> /dev/null; then
    echo "Opening waveform with GTKWave..."
    gtkwave waveform.vcd &
else
    echo "GTKWave not found. Here are alternative options:"
    echo "1. Open with ModelSim Wave Viewer:"
    echo "   vsim -view waveform.wdb"
    echo ""
    echo "2. Install GTKWave and run:"
    echo "   gtkwave waveform.vcd"
    echo ""
    echo "3. View raw VCD file:"
    echo "   cat waveform.vcd | head -100"
fi
