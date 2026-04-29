#!/bin/bash
# Script to view waveforms with GTKWave
# Run from: SystemVerilog/ProjAPB/sim/scripts directory

cd "$(dirname "$0")/../waveforms" || exit

WAVEFORM="waveform_detailed.vcd"

if [ ! -f "$WAVEFORM" ]; then
    echo "Error: $WAVEFORM not found in $(pwd)"
    exit 1
fi

if command -v gtkwave &> /dev/null; then
    echo "Opening waveform with GTKWave: $WAVEFORM"
    gtkwave "$WAVEFORM" &
else
    echo "GTKWave not found. Here are alternative options:"
    echo "1. Install GTKWave:"
    echo "   - Linux: apt-get install gtkwave"
    echo "   - macOS: brew install gtkwave"
    echo "   - Windows: http://gtkwave.sourceforge.net/"
    echo ""
    echo "2. Open with ModelSim Wave Viewer:"
    echo "   vsim -view waveform.wdb"
    echo ""
    echo "3. View raw VCD file:"
    echo "   cat $WAVEFORM | head -100"
fi
