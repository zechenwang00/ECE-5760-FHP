//=================================================================================================
// Mem module
//=================================================================================================
// A 480 12-bit words mem in M10K ram style.
// output read_data ready in next clock cycle;
// input write_data can be read at mem[write_address] in next clock cycle
//=================================================================================================

module Mem
#(
	parameter addr_nbits = 9,
	parameter data_nbits = 12,
	parameter mem_size   = 480
)(
	output reg [data_nbits-1:0] read_data,
	input      [data_nbits-1:0] write_data,
	input      [addr_nbits-1:0] write_address, read_address,
	input                       write_enable, clk
);
	// force M10K ram style
	// 480 12-bit words
	reg [data_nbits-1:0] mem [mem_size-1:0]  /* synthesis ramstyle = "no_rw_check, M10K" */;

	// integer i;
		
	always @ (posedge clk) begin
		// if (reset) begin
		// 	// for (i = 0; i < mem_size; i = i+1) begin
		// 	// 	mem[i] <= 0;
		// 	// end
		// end
		if (write_enable) begin
			mem[write_address] <= write_data;
		end
		read_data <= mem[read_address];
	end

endmodule

`timescale 1ns / 1ns
module Mem_testbench();
	// signal length
	parameter addr_nbits = 9;
	parameter data_nbits = 12;

	// inputs and outputs for testing
	wire [data_nbits-1:0] read_data;
	reg  [data_nbits-1:0] write_data;
	reg  [addr_nbits-1:0] write_address, read_address;
	reg                   write_enable, clk;

	wire [data_nbits-1:0] write_data_w;
	wire [addr_nbits-1:0] write_address_w, read_address_w;
	wire                  write_enable_w, clk_w;

	assign write_data_w    = write_data;
	assign write_address_w = write_address;
	assign read_address_w  = read_address;
	assign write_enable_w  = write_enable;
	assign clk_w           = clk;

	// Instantiate testing
	Mem DUT (
		.read_data      (read_data),
		.write_data     (write_data_w),
		.write_address  (write_address_w),
		.read_address   (read_address_w),
		.write_enable   (write_enable_w),
		.clk            (clk_w)
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
		write_enable <= 1'b0; @(posedge clk);
		write_enable <= 1'b1; @(posedge clk);

		write_data <= 0; write_address <= 0;                    @(posedge clk);
		write_data <= 1; write_address <= 1; read_address <= 0; @(posedge clk);

		// simulate for 16 time cycles
		for(i = 2; i < 24; i = i + 1) begin
			write_data    <= (write_data    + 1);
			write_address <= (write_address + 1);
			read_address  <= (read_address  + 1);
			@(posedge clk);
		end
		
		$stop; // End the simulation.
	end

endmodule
