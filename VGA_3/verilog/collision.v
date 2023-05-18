//=================================================================================================
// Collision module
//=================================================================================================
// 
//=================================================================================================


module Collision
(
    output [5:0] out,
    input  [5:0] in,
    input        rnd
);
    wire a, b, c, d, e, f, ad, be, cf, triple, no_rnd;
    wire cha, chb, chc, chd, che, chf;
    wire aout, bout, cout, dout, eout, fout;
    
    // a to f
    assign a = in[0];
    assign b = in[1];
    assign c = in[2];
    assign d = in[3];
    assign e = in[4];
    assign f = in[5];

    // collision values
    assign ad = ( (a & d) & (~(b | c | e | f)) );
    assign be = ( (b & e) & (~(a | c | d | f)) );
    assign cf = ( (c & f) & (~(a | b | d | e)) );

    // triple
    assign triple = ( (a ^ b) & (b ^ c) & (c ^ d) & (d ^ e) & (e ^ f) );

    // random bits
    assign no_rnd = ~rnd;

    // changes
    assign cha = (ad | triple | (rnd & be) | (no_rnd & cf));
    assign chb = (be | triple | (rnd & cf) | (no_rnd & ad));
    assign chc = (cf | triple | (rnd & ad) | (no_rnd & be));
    assign chd = cha;
    assign che = chb;
    assign chf = chc;

    // output values
    assign aout = a ^ cha;
    assign bout = b ^ chb;
    assign cout = c ^ chc;
    assign dout = d ^ chd;
    assign eout = e ^ che;
    assign fout = f ^ chf;

    assign out = {fout, eout, dout, cout, bout, aout};

endmodule


`timescale 1ns / 1ns
module Collision_testbench();

	// inputs and outputs for testing
    reg  [5:0] in;
    wire [5:0] in_w, out;
    wire rnd_w;

	reg clk;

	assign in_w  = in;
    assign rnd_w = 1;

	// Instantiate testing
	Collision DUT (
		.in   (in_w),
		.out  (out),
        .rnd  (rnd_w)
	);

	// Set up the clock.
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// for loop tracker
	integer i;

	// Set up the inputs to the design. Each "@(posedge clk);" is a clock cycle.
	initial begin
		
		@(posedge clk);
		@(posedge clk);

        // squence: {d, c, e, b, f, a}
        in <= 6'b100001; @(posedge clk);    // ad -> be/cf
        in <= 6'b001100; @(posedge clk);    // be -> ad/cf
        in <= 6'b010010; @(posedge clk);    // cf -> ad/be

        in <= 6'b011001; @(posedge clk);    //ace -> bdf
        in <= 6'b100110; @(posedge clk);    //bdf -> ace
        

		// // simulate for 100000 time cycles
		// for(i = 0; i < 7'b1000000; i = i + 1) begin
		// 	in <= i; @(posedge clk);
		// end

		@(posedge clk);
		@(posedge clk);
		
		$stop; // End the simulation.
	end

endmodule

