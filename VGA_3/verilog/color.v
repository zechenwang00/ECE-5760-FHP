//----------------------------------
// color.v
//----------------------------------

module Color
#(
	parameter color_nbits = 8
)(
    input  [5:0] in,
    output [color_nbits-1:0] color
);
    reg [color_nbits-1:0] color_reg;
    
   wire [2:0] num_ones;
   assign num_ones = (3'd_0 + in[5] + in[4] + in[3] + in[2] + in[1] + in[0]);

//    always @* begin
// 		if (in == 6'd_0) begin
// 			color_reg = 8'b_000_000_00; // black
// 		end
// 		else begin
// 			color_reg = 8'b_111_111_11; // white
// 		end
//     end


    always @* begin
		case (num_ones)
			3'd_0:		color_reg = 8'b_000_000_00; // black
			3'd_1:		color_reg = 8'b_111_111_11; // white
			3'd_2:		color_reg = 8'b_111_111_00; // yellow
			3'd_3:		color_reg = 8'b_111_110_00; 
			3'd_4:		color_reg = 8'b_111_101_00; 
			3'd_5:		color_reg = 8'b_111_100_00;
			3'd_6:		color_reg = 8'b_111_011_00;
			default:	color_reg = 8'b_000_000_00; 
		endcase
    end

    assign color = color_reg;

endmodule


`timescale 1ns / 1ns
module Color_testbench();

	// inputs and outputs for testing
    reg  [5:0] in;
    wire [5:0] in_w, out;

	reg clk;

	assign in_w  = in;

	// Instantiate testing
	Color DUT (
		.in     (in_w),
		.color  (out)
	);

	// Set up the clock.
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// Set up the inputs to the design. Each "@(posedge clk);" is a clock cycle.
	initial begin
		
		@(posedge clk);
		@(posedge clk);

        in <= 6'b000000; @(posedge clk);
        in <= 6'b000001; @(posedge clk); 
        in <= 6'b000011; @(posedge clk);    
        in <= 6'b000111; @(posedge clk);    
        in <= 6'b001111; @(posedge clk);    
        in <= 6'b011111; @(posedge clk);
        in <= 6'b111111; @(posedge clk);

		@(posedge clk);
		@(posedge clk);
		
		$stop; // End the simulation.
	end

endmodule