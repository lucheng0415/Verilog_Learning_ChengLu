# What is Verilog ?

Verilog is a hardware description language (HDL) that is used to describe digital systems and circuits in the form of code. It was developed by Gateway Design Automation in the mid-1980s and later acquired by Cadence Design Systems.

Verilog is widely used for design and verification of digital and mixed-signal systems, including both application-specific integrated circuits (ASICs) and field-programmable gate arrays (FPGAs). It supports a range of levels of abstraction, from structural to behavioral, and is used for both simulation-based design and synthesis-based design.

The language is used to describe digital circuits hierarchically, starting with the most basic elements such as logic gates and flip-flops and building up to more complex functional blocks and systems. It also supports a range of modeling techniques, including gate-level, RTL-level, and behavioral-level modeling.

# Why Verilog useful ?

Verilog creates a level of abstraction that helps hide away the details of its implementation and technology.

For example, the design of a D flip-flop would require the knowledge of how the transistor need to be arranged to achive a positive-dege triggered FF and waht the rise, fall and clk-Q timesrequired to latch the value onto a flop among many other technology oriented details. Powr dissipation, timing and the ability to drive nets and other flops would also requrie a more through understading of the physical characteristics of a transistor.

Verilog helps us to focus on the behaviour and leave the rest to be sorted out later. 

# Verilog Code Example:
```verilog 
module ctr ( input up_down,
                   clk,
		           rstn,
             output reg [2:0] out);

always @ (posedge clk)
        if (!rstn)
            out << 0;
        else begin
            if (up_down)
	            out <= out + 1;
            else
                out <= out - 1;
        end
endmodule
```

The simple example shown above illustrates how all the physical implementation details (interconnection of underlying logic gates like NAND and NOR) have been hidden while still providing a clear idea of how the counter functions.

ctr is a module that represents an up/down counter, and it is possible to choose the actual physical implementation of the design from a wide variety of different styles of flops optimized for area, power and performance. They are usually compiled into libraries and will be available for us to select within EDA tools at a later stage in the design process.

# Verilog Hello World
It's always best to get started using a very simple example, and none serves the purpose best other than "Hello World !".


```verilog
// Single line comments start with double forward slash "//"
// Verilog code is always written inside modules, and each module represents a digital block with some functionality
module tb;

  // Initial block is another construct typically used to initialize signal nets and variables for simulation
	initial
		// Verilog supports displaying signal values to the screen so that designers can debug whats wrong with their circuit
		// For our purposes, we'll simply display "Hello World"
		$display ("Hello World !");
endmodule
```

A module called tb with no input-output ports act as the top module for the simulation. The initial block starts and executes the first statement at time 0 units. $display is a Verilog system task used to display a formatted string to the console and cannot be synthesized into hardware. Its primarily used to help with testbench and design debug. In this case, the text message displayed onto the screen is "Hello World !".

# Verilog Syntax
Lexical conventions in Verilog are similar to C in the sense that it contains a stream of tokens. A lexical token may consist of one or more characters and tokens can be comments, keywords, numbers, strings or white space. All lines should be terminated by a semi-colon ;.

## Comments
There are two ways to write comments in Verilog.

1. A single line comment starts with // and tells Verilog compiler to treat everything after this point to the end of the line as a comment.
2. A multiple-line comment starts with /* and ends with */ and cannot be nested.

However, single line comments can be nested in a multiple line comment.
```
// This is a single line comment

integer a;   // Creates an int variable called a, and treats everything to the right of // as a comment

/*
This is a
multiple-line or
block comment
*/

/* This is /*
an invalid nested
block comment */
*/

/* However,
// this one is okay
*/

// This is also okay
///////////// Still okay
```
## Whitespace
White space is a term used to represent the characters for spaces, tabs, newlines and formfeeds, and is usually ignored by Verilog except when it separates tokens. In fact, this helps in the indentation of code to make it easier to read. However blanks(spaces) and tabs (from TAB key) are not ignored in strings.

## Operators
There are three types of operators: unary, binary, and ternary or conditional.

1. Unary operators shall appear to the left of their operand.
2. Binary operators shall appear between their operands.
3. Conditional operators have two separate operators that separate three operands.
```
x = ~y;                // ~ is a unary operator, and y is the operand
x = y | z;             // | is a binary operator, where y and z are its operands
x = (y > 5) ? w : z;   // ?: is a ternary operator, and the expression (y>5), w and z are its operands

```
If the expression (y > 5) is true, then variable x will get the value in w, else the value in z.


