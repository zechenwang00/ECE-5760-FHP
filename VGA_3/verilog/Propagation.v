//=================================================================================================
// Propagation module
//=================================================================================================
// 
//=================================================================================================


module Propagation
(
    output [5:0] out,
    input  [5:0] l_up, l_n, l_down, r_up, r_n, r_down, n,
    input  [3:0] wall
);
    // TODO
    
    wire a, b, c, d, e, f;
    wire a_in, b_in, c_in, d_in, e_in, f_in;
    wire w_u, w_d, w_l, w_r;
    wire nw_u, nw_d, nw_l, nw_r;
    wire aout, bout, cout, dout, eout, fout;
    
    // a to f
    assign a = n[0];
    assign b = n[1];
    assign c = n[2];
    assign d = n[3];
    assign e = n[4];
    assign f = n[5];

    assign a_in = r_down[0];
    assign b_in = r_n   [1];
    assign c_in = r_up  [2];
    assign d_in = l_up  [3];
    assign e_in = l_n   [4];
    assign f_in = l_down[5];

    // walls
    assign w_u = wall[3];
    assign w_d = wall[2];
    assign w_l = wall[1];
    assign w_r = wall[0];
    assign nw_u = (~w_u);
    assign nw_d = (~w_d);
    assign nw_l = (~w_l);
    assign nw_r = (~w_r);

    // output values
    assign aout = (((nw_r & nw_d) & a_in) | (w_d & c) | (w_r & f));
    assign dout = (((nw_l & nw_u) & d_in) | (w_u & f) | (w_l & c));

    assign bout = ((nw_r & b_in) | (w_r & e));
    assign eout = ((nw_l & e_in) | (w_l & b));

    assign cout = (((nw_r & nw_u) & c_in) | (w_u & a) | (w_r & d));
    assign fout = (((nw_l & nw_d) & f_in) | (w_d & d) | (w_l & a));

    assign out = {fout, eout, dout, cout, bout, aout};

endmodule


// `timescale 1ns / 1ns
// module Collision_testbench();

// 	// inputs and outputs for testing
//     reg  [5:0] in;
//     wire [5:0] in_w, out;
//     wire rnd_w;

// 	reg clk;

// 	assign in_w  = in;
//     assign rnd_w = 1;

// 	// Instantiate testing
// 	Collision DUT (
// 		.in   (in_w),
// 		.out  (out),
//         .rnd  (rnd_w)
// 	);

// 	// Set up the clock.
// 	parameter CLOCK_PERIOD = 100;
// 	initial begin
// 		clk <= 0;
// 		forever #(CLOCK_PERIOD/2) clk <= ~clk;
// 	end

// 	// for loop tracker
// 	integer i;

// 	// Set up the inputs to the design. Each "@(posedge clk);" is a clock cycle.
// 	initial begin
		
// 		@(posedge clk);
// 		@(posedge clk);

//         // squence: {d, c, e, b, f, a}
//         in <= 6'b100001; @(posedge clk);    // ad -> be/cf
//         in <= 6'b001100; @(posedge clk);    // be -> ad/cf
//         in <= 6'b010010; @(posedge clk);    // cf -> ad/be

//         in <= 6'b011001; @(posedge clk);    //ace -> bdf
//         in <= 6'b100110; @(posedge clk);    //bdf -> ace
        

// 		// // simulate for 100000 time cycles
// 		// for(i = 0; i < 7'b1000000; i = i + 1) begin
// 		// 	in <= i; @(posedge clk);
// 		// end

// 		@(posedge clk);
// 		@(posedge clk);
		
// 		$stop; // End the simulation.
// 	end

// endmodule

