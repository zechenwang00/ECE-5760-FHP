//=================================================================================================
// FHP module
//=================================================================================================
// 
//=================================================================================================

module FHP
#(
	parameter coord_nbits = 10,
	parameter addr_nbits  = 9,
	parameter data_nbits  = 12,
	parameter node_nbits  = 6,
	parameter last_col    = 319
)(
	// output
	output [data_nbits-1:0] vga_read_data,

	// input
	input  [coord_nbits-1:0] next_x, next_y,
	input  [node_nbits-1:0]  init_bits,
	input  [addr_nbits-1:0]  i_start, i_end, j_start, j_end,
	input                    go, clk, reset
);	
	// Rand
	wire [15:0] rand_out;

	wire [3:0] rand_idx;
	assign rand_idx = rand_out[3:0];

	wire rnd;
	assign rnd = rand_out[rand_idx];

	wire [63:0] seed_in;
	assign seed_in = 64'd_6480;  // TODO

	rand63 r (
		.rand_out (rand_out),
		.seed_in  (seed_in),
		.clk      (clk),
		.rst      (reset)
	);
	
	// Simulation:
	// Instantiate 320 FHPCols
	wire [data_nbits-1:0] n_up   [last_col:0];
	wire [data_nbits-1:0] n      [last_col:0];
	wire [data_nbits-1:0] n_down [last_col:0];

	wire [data_nbits-1:0] read_data_list [last_col:0];

	wire [addr_nbits-1:0] vga_read_address;
	assign vga_read_address = next_y[addr_nbits-1:0];

	FHPCol col0 (
		.vga_read_data      (read_data_list[0]),
		.n_up               (n_up  [0]),
		.n                  (n     [0]),
		.n_down             (n_down[0]),
		.vga_read_address   (vga_read_address),
		.wall_left          (1'b_1),
		.wall_right         (1'b_0),
		.l_up               (12'd_0),
		.l_n                (12'd_0),
		.l_down             (12'd_0),
		.r_up               (n_up  [1][node_nbits-1:0]),
		.r_n                (n     [1][node_nbits-1:0]),
		.r_down             (n_down[1][node_nbits-1:0]),
		.init_bits			(init_bits),
		.i_start			(i_start),
		.i_end				(i_end),
		.init               (1'b_0),
		.rnd                (rnd),
		.go                 (go),
		.clk                (clk),
		.reset              (reset)
	);

	FHPCol col319 (
		.vga_read_data      (read_data_list[last_col]),
		.n_up               (n_up  [last_col]),
		.n                  (n     [last_col]),
		.n_down             (n_down[last_col]),
		.vga_read_address   (vga_read_address),
		.wall_left          (1'b_0),
		.wall_right         (1'b_1),
		.l_up               (n_up  [318][data_nbits-1:node_nbits]),
		.l_n                (n     [318][data_nbits-1:node_nbits]),
		.l_down             (n_down[318][data_nbits-1:node_nbits]),
		.r_up               (12'd_0),
		.r_n                (12'd_0),
		.r_down             (12'd_0),
		.init_bits			(init_bits),
		.i_start			(i_start),
		.i_end				(i_end),
		.init               (1'b_0),
		.rnd                (rnd),
		.go                 (go),
		.clk                (clk),
		.reset              (reset)
	);

	genvar j;
	generate
		for (j = 1; j < last_col; j = j + 1) begin : pll_FHPCols
			FHPCol col (
				.vga_read_data      (read_data_list[j]),
				.n_up               (n_up  [j]),
				.n                  (n     [j]),
				.n_down             (n_down[j]),
				.vga_read_address   (vga_read_address),
				.wall_left          (1'b_0),
				.wall_right         (1'b_0),
				.l_up               (n_up  [j-1][data_nbits-1:node_nbits]),
				.l_n                (n     [j-1][data_nbits-1:node_nbits]),
				.l_down             (n_down[j-1][data_nbits-1:node_nbits]),
				.r_up               (n_up  [j+1][node_nbits-1:0]),
				.r_n                (n     [j+1][node_nbits-1:0]),
				.r_down             (n_down[j+1][node_nbits-1:0]),
				.init_bits			(init_bits), 
				.i_start			(i_start),
				.i_end				(i_end),
				.init               (((j > j_start) && (j < j_end))),
				.rnd                (rnd),
				.go                 (go),
				.clk                (clk),
				.reset              (reset)
			);
		end
	endgenerate

	// output
	assign vga_read_data = next_x[0] ? read_data_list[next_x[coord_nbits-1:1]][node_nbits-1:0] : read_data_list[next_x[coord_nbits-1:1]][data_nbits-1:node_nbits];

endmodule // end top level


`timescale 1ns / 1ns
module FHP_testbench();
	// inputs and outputs for testing
	wire [5:0] vga_read_data;

	wire [9:0] next_x_w, next_y_w;
	wire       clk_w, reset_w, go_w;

	// inputs reg
    reg [9:0] next_x, next_y;
	reg       clk, reset, go;

	assign next_x_w     = next_x;
	assign next_y_w     = next_y;
	assign clk_w        = clk;
	assign reset_w      = reset;
	assign go_w         = go;

	// Instantiate testing
	FHP fhp (
		.vga_read_data	(vga_read_data),
		.go				(go_w),
		.next_x         (next_x_w),  // This (and next_y) used to specify memory read address
		.next_y         (next_y_w),  // This (and next_x) used to specify memory read address
		.clk            (clk_w),
		.reset          (reset_w)
	);

	// Set up the clock.
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// for loop tracker
	integer i, j;

	// Set up the inputs to the design. Each "@(posedge clk);" is a clock cycle.
	initial begin
		@(posedge clk);

		go <= 1'b_0;

		// reset
		reset <= 1'b1; @(posedge clk);
		reset <= 1'b0; @(posedge clk);
		
		// simulate
		// Init state - 480 time cycles
		for(i = 0; i < 480; i = i + 1) begin
			@(posedge clk);
		end

		// Stall state - 640 * 480 time cycles
		for(i = 0; i < 480; i = i + 1) begin
			next_y <= i;
			for(j = 0; j < 640; j = j + 1) begin
				next_x <= j; @(posedge clk);
			end
		end

		go <= 1'b_1; @(posedge clk);

		// Collision state - 482 time cycles
		for(i = 0; i < 482; i = i + 1) begin
			@(posedge clk);
		end

		// Propagation state - 481 time cycles
		for(i = 0; i < 481; i = i + 1) begin
			@(posedge clk);
		end

		// Stall state - 640 * 480 time cycles
		for(i = 0; i < 480; i = i + 1) begin
			next_y <= i;
			for(j = 0; j < 640; j = j + 1) begin
				next_x <= j; @(posedge clk);
			end
		end

		// Collision state - 482 time cycles
		for(i = 0; i < 482; i = i + 1) begin
			@(posedge clk);
		end

		// Propagation state - 481 time cycles
		for(i = 0; i < 481; i = i + 1) begin
			@(posedge clk);
		end

		// Stall state - 640 * 480 time cycles
		for(i = 0; i < 480; i = i + 1) begin
			next_y <= i;
			for(j = 0; j < 640; j = j + 1) begin
				next_x <= j; @(posedge clk);
			end
		end

		@(posedge clk);
		@(posedge clk);
		
		$stop; // End the simulation.
	end

endmodule
