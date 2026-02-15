# Verilog Data Types
The primary intent of data-types in the Verilog language is to represent data storage elements like bits in a flip-flop and transmission elements like wires that connect between logic gates and sequential structures.

## What values do variables hold ?
Almost all data-types can only have one of the four different values as given below except for real and event data types.

0	represents a logic zero, or a false condition
1	represents a logic one, or a true condition
x	represents an unknown logic value (can be zero or one)
z	represents a high-impedance state

The following image shows how these values are represented in timing diagrams and simulation waveforms. Most simulators use this convention where red stands for X and orange in the middle stands for high-impedance or Z.

![Values](images/Values.png)

## What does the verilog value-set imply ?
Since Verilog is essentially used to describe hardware elements like flip-flops and combinational logic like NAND and NOR, it has to model the value system found in hardware. A logic one would represent the voltage supply Vdd which can range anywhere between 0.8V to more than 3V based on the fabrication technology node. A logic zero would represent ground and hence a value of 0V.

X or x means that the value is simply unknown at the time, and could be either 0 or 1. This is quite different from the way X is treated in boolean logic, where it means "don't care".

As with any incomplete electric circuit, the wire that is not connected to anything will have a high-impedance at that node and is represented by Z or z. Even in verilog, any unconnected wire will result in a high impedance.



