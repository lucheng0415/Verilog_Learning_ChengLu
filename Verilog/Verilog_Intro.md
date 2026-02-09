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

## Number Format
We are most familiar with numbers being represented as decimals. However, numbers can also be represented in binary, octal and hexadecimal. By default, Verilog simulators treat numbers as decimals. In order to represent them in a different radix, certain rules have to be followed.
```
16          // Number 16 in decimal
0x10        // Number 16 in hexadecimal
10000       // Number 16 in binary
20          // Number 16 in octal
```
### Sized
Sized numbers are represented as shown below, where size is written only in decimal to specify the number of bits in the number.
```
[size]'[base_format][number]
```
1. base_format can be either decimal ('d or 'D), hexadecimal ('h or 'H) and octal ('o or 'O) and specifies what base the number part represents.
2. number is specified as consecutive digits from 0, 1, 2 ... 9 for decimal base format and 0, 1, 2 .. 9, A, B, C, D, E, F for hexadecimal.

```
3'b010;     // size is 3, base format is binary ('b), and the number is 010 (indicates value 2 in binary)
3'd2;       // size is 3, base format is decimal ('d) and the number is 2 (specified in decimals)
8'h70;      // size is 8, base format is hexadecimal ('h) and the number is 0x70 (in hex) to represent decimal 112
9'h1FA;     // size is 9, base format is hexadecimal ('h) and the number is 0x1FA (in hex) to represent decimal 506

4'hA = 4'd10 = 4'b1010 = 4'o12	// Decimal 10 can be represented in any of the four formats
8'd234 = 8'D234                 // Legal to use either lower case or upper case for base format
32'hFACE_47B2;                  // Underscore (_) can be used to separate 16 bit numbers for readability
```
Uppercase letters are legal for number specification when the base format is hexadecimal.

```
16'hcafe;         // lowercase letters Valid
16'hCAFE;         // uppercase letters Valid
32'h1D40_CAFE;    // underscore can be used as separator between 4 letters Valid
```

### Unsized
Numbers without a base_format specification are decimal numbers by default. Numbers without a size specification have a default number of bits depending on the type of simulator and machine.

```
-6'd3;            // 8-bit negative number stored as two's complement of 3
-6'sd9;           // For signed maths
8'd-4;            // Illegal
```

## Strings
A sequence of characters enclosed in a double quote " " is called a string. It cannot be split into multiple lines and every character in the string take 1-byte to be stored.

```
"Hello World!"        // String with 12 characters -> require 12 bytes
"x + z"               // String with 5 characters

"How are you
feeling today ?"      // Illegal for a string to be split into multiple lines
```

## Identifiers
Identifiers are names of variables so that they can be referenced later on. They are made up of alphanumeric characters [a-z][A-Z][0-9], underscores _ or dollar sign $ and are case sensitive. They cannot start with a digit or a dollar sign.

```
integer var_a;        // Identifier contains alphabets and underscore -> Valid
integer $var_a;       // Identifier starts with $ -> Invalid
integer v$ar_a;       // Identifier contains alphabets and $ -> Valid
integer 2var;         // Identifier starts with a digit -> Invalid
integer var23_g;      // Identifier contains alphanumeric characters and underscore -> Valid
integer 23;           // Identifier contains only numbers -> Invalid
```

## Keywords
Keywords are special identifiers reserved to define the language constructs and are in lower case. A list of important keywords is given below.

![Verilog Keywords](images/verilog_keywords_2.png)

# Verilog module
A module is a block of Verilog code that implements a certain functionality. Modules can be embedded within other modules and a higher level module can communicate with its lower level modules using their input and output ports.

## Syntax
A module should be enclosed within module and endmodule keywords. Name of the module should be given right after the module keyword and an optional list of ports may be declared as well. Note that ports declared in the list of port declarations cannot be redeclared within the body of the module.
```
module <name> ([port_list]);
	// Contents of the module
endmodule

// A module can have an empty portlist
module name;
	// Contents of the module
endmodule
```
All variable declarations, dataflow statements, functions or tasks and lower module instances if any, must be defined within the module and endmodule keywords. There can be multiple modules with different names in the same file and can be defined in any order.

## Example
![Verilog Module Example](images/dff_module.png)

The module dff represents a D flip flop which has three input ports d, clk, rstn and one output port q. Contents of the module describe how a D flip flop should behave for different combinations of inputs. Here, input d is always assigned to output q at positive edge of clock if rstn is high because it is an active low reset.

```
// Module called "dff" has 3 inputs and 1 output port
module dff ( 	input 			d,
							input 			clk,
							input 			rstn,
							output reg	q);

	// Contents of the module
	always @ (posedge clk) begin
		if (!rstn)
			q <= 0;
		else
			q <= d;
	end
endmodule
```

## Hardware Schematic
This module will be converted into the following digital circuit during synthesis.
![Hardware Schematic](images/dff_sync_reset_schematic.png)
Note that you cannot have any code written outside a module !

## What is the purpose of a module ?
A module represents a design unit that implements certain behavioral characteristics and will get converted into a digital circuit during synthesis. Any combination of inputs can be given to the module and it will provide a corresponding output. This allows the same module to be reused to form bigger modules that implement more complex hardware.

For example, the DFF shown above can be chained to form a shift register.

```
module shift_reg ( 	input 	d,
					input  	clk,
					input 	rstn,
					output 	q);

	wire [2:0] q_net;
	dff u0 (.d(d),        .clk(clk), .rstn(rstn), .q(q_net[0]));
	dff u1 (.d(q_net[0]), .clk(clk), .rstn(rstn), .q(q_net[1]));
	dff u2 (.d(q_net[1]), .clk(clk), .rstn(rstn), .q(q_net[2]));
	dff u3 (.d(q_net[2]), .clk(clk), .rstn(rstn), .q(q));

endmodule
```
Note that the dff instances are connected together with wires as described by the Verilog RTL module.

![Hardware Schematic](images/dff_shift_reg_schematic.png)
Instead of building up from smaller blocks to form bigger design blocks, the reverse can also be done. Consider the breakdown of a simple GPU engine into smaller components such that each can be represented as a module that implements a specific feature. The GPU engine shown below can be divided into five different sub-blocks where each perform a specific functionality. The bus interface unit gets data from outside into the design, which gets processed by another unit to extract instructions. Other units down the line process data provided by previous unit.

![GPU Module](images/gpu_modules2.png)
Each sub-block can be represented as a module with a certain set of input and output signals for communication with other modules and each sub-block can be further divided into more finer blocks as required.

## What are top-level modules ?
A top-level module is one which contains all other modules. A top-level module is not instantiated within any other module.

For example, design modules are normally instantiated within top level testbench modules so that simulation can be run by providing input stimulus. But, the testbench is not instantiated within any other module because it is a block that encapsulates everything else and hence is the top-level module.

Design Top Level
The design code shown below has a top-level module called design. This is because it contains all other sub-modules requried to make the design complete. The submodules can have more nested sub-modules like mod3 inside mod1 and mod4 inside mod2. Anyhow, all these are included into the top level module when mod1 and mod2 are instantiated. So this makes the design complete and is the top-level module for the design.

```
//---------------------------------
//  Design code
//---------------------------------
module mod3 ( [port_list] );
	reg c;
	// Design code
endmodule

module mod4 ( [port_list] );
	wire a;
	// Design code
endmodule

module mod1 ( [port_list] );	 	// This module called "mod1" contains two instances
	wire 	y;

	mod3 	mod_inst1 ( ... ); 	 		// First instance is of module called "mod3" with name "mod_inst1"
	mod3 	mod_inst2 ( ... );	 		// Second instance is also of module "mod3" with name "mod_inst2"
endmodule

module mod2 ( [port_list] ); 		// This module called "mod2" contains two instances
	mod4 	mod_inst1 ( ... );			// First instance is of module called "mod4" with name "mod_inst1"
	mod4 	mod_inst2 ( ... );			// Second instance is also of module "mod4" with name "mod_inst2"
endmodule

// Top-level module
module design ( [port_list]); 		// From design perspective, this is the top-level module
	wire 	_net;
	mod1 	mod_inst1 	( ... ); 			// since it contains all other modules and sub-modules
	mod2 	mod_inst2 	( ... );
endmodule
```
## Testbench Top Level
The testbench module contains stimulus to check functionality of the design and is primarily used for functional verification using simulation tools. Hence the design is instantiated and called d0 inside the testbench module. From a simulator perspective, testbench is the top level module.

```
//-----------------------------------------------------------
// Testbench code
// From simulation perspective, this is the top-level module
// because 'design' is instantiated within this module
//-----------------------------------------------------------
module testbench;
	design d0 ( [port_list_connections] );

	// Rest of the testbench code
endmodule
```

## Hierarchical Names
A hierarchical structure is formed when modules can be instantiated inside one another, and hence the top level module is called the root. Since each lower module instantiations within a given module is required to have different identifier names, there will not be any ambiguity in accessing signals. A hierarchical name is constructed by a list of these identifiers separated by dots . for each level of the hierarchy. Any signal can be accessed within any module using the hierarchical path to that particular signal.

```
// Take the example shown above in top level modules
design.mod_inst1 					// Access to module instance mod_inst1
design.mod_inst1.y 					// Access signal "y" inside mod_inst1
design.mod_inst2.mod_inst2.a		// Access signal "a" within mod4 module

testbench.d0._net; 					// Top level signal _net within design module accessed from testbench
```

