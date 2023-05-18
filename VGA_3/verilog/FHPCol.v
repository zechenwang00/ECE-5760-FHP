//=================================================================================================
// FHPCol module
//=================================================================================================
// Each FPHCol stores two column of pixels in M10K Mem.
// Applys FHP collision to both two pixels in one row from top to bottom, one pair per clock cycle.
// Then propagate both two pixels in one row from top to bottom, one pair per clock cycle.
// Stall for read by VGA and restart previous steps after finish reading all pixels.
//=================================================================================================

module FHPCol
#(
	parameter addr_nbits = 9,
	parameter data_nbits = 12,
	parameter node_nbits = 6,
	parameter mem_bottom = 479,
	parameter init_start = 120,
	parameter init_end   = 360
)(
	// outputs
	output [data_nbits-1:0] vga_read_data,
	output [data_nbits-1:0] n_up, n, n_down,

	// inputs
	input  [addr_nbits-1:0] vga_read_address,
	input  [addr_nbits-1:0] i_start, i_end,
	input                   wall_left, wall_right,
	input  [node_nbits-1:0] l_up, l_n, l_down, r_up, r_n, r_down, 
	input  [node_nbits-1:0] init_bits,
	input                   init, rnd, go,
	input                   clk, reset
);
	// State Machine regs.
	reg [1:0]            state;
	reg [data_nbits-1:0] n_up_reg, n_reg, n_down_reg;

	// Conections to M10K Mem module.
	wire [data_nbits-1:0] read_data;
	wire [addr_nbits-1:0] read_addr;
	reg  [data_nbits-1:0] write_data;
	reg  [addr_nbits-1:0] write_addr, FHP_read_addr;
	reg                   write_enable;

	assign read_addr = (state == 2'd_1) ? vga_read_address : FHP_read_addr;

	Mem col (
		.read_data      (read_data),
		.write_data     (write_data),
		.write_address  (write_addr),
		.read_address   (read_addr),
		.write_enable   (write_enable),
		.clk            (clk)
	);

	// Conections to Collision module.
	wire [node_nbits-1:0] c_node_0, c_node_1, c_node_0_out, c_node_1_out;

	assign c_node_0 = read_data[node_nbits-1:0];
	assign c_node_1 = read_data[data_nbits-1:node_nbits];

	Collision cn1 (
		.out   (c_node_0_out),
		.in    (c_node_0),
		.rnd   (rnd)
	);

	Collision cn0 (
		.out   (c_node_1_out),
		.in    (c_node_1),
		.rnd   (rnd)
	);

	// Conections to Propagation module.
	wire [node_nbits-1:0] p_node_0_out, p_node_1_out;
	wire [node_nbits-1:0] l_up_1, l_n_1, l_down_1, p_node_1;
	wire [node_nbits-1:0] r_up_0, r_n_0, r_down_0, p_node_0;
	wire [3:0]	wall_0, wall_1;
	
	reg                   wall_up, wall_down;

	assign l_up_1   =   n_up[node_nbits-1:0];
	assign l_n_1    =      n[node_nbits-1:0];
	assign l_down_1 = n_down[node_nbits-1:0];
	assign p_node_1 =      n[data_nbits-1:node_nbits];
	assign wall_1   = {wall_up, wall_down, 1'b_0, wall_right};
	
	assign r_up_0   =   n_up[data_nbits-1:node_nbits];
	assign r_n_0    =      n[data_nbits-1:node_nbits];
	assign r_down_0 = n_down[data_nbits-1:node_nbits];
	assign p_node_0 =      n[node_nbits-1:0];
	assign wall_0   = {wall_up, wall_down, wall_left, 1'b_0};

	Propagation pn1 (
		.out    (p_node_1_out),
		.l_up   (l_up_1),
		.l_n    (l_n_1),
		.l_down (l_down_1),
		.r_up   (r_up),
		.r_n    (r_n),
		.r_down (r_down),
		.n      (p_node_1),
		.wall   (wall_1)
	);

	Propagation pn0 (
		.out    (p_node_0_out),
		.l_up   (l_up),
		.l_n    (l_n),
		.l_down (l_down),
		.r_up   (r_up_0),
		.r_n    (r_n_0),
		.r_down (r_down_0),
		.n      (p_node_0),
		.wall   (wall_0)
	);

	// State Machine.
	always @(posedge clk) begin
		if (reset) begin
			// Goto Init state.
			state <= 2'd_0;

			// Set initial condition of Init state.
			write_addr   <= 9'd_0;
			write_data   <= 12'd0; // all 0s
			write_enable <= 1'b1;
		end
		else if (state == 2'd_0) begin // Init state
			// Load initial directions of each node in this two-column block.
			if (write_addr > i_end) begin
				write_data <= 12'd0; // all 0s
			end
			else if ((write_addr > i_start)) begin
				if (init == 1'b1) begin
					write_data <= {init_bits, init_bits}; // enable a, e, f
				end
			end
			
			// Set to next row.
			if (write_addr == mem_bottom) begin
				write_enable <= 1'b0;

				// All loaded, goto Stall state
				state <= 2'd_1;
			end
			else begin
				write_addr <= (write_addr + 1);
			end
		end
		else if (state == 2'd_1) begin // Stall state
			if (go == 1'b1) begin
				// Goto Collision state.
				state <= 2'd_2;

				// Set initial condition of Collision state.
				FHP_read_addr <= 9'd_0;
				write_addr    <= 9'd_0;
			end
		end
		else if (state == 2'd_2) begin // Collision state
			// Read.
			if (FHP_read_addr == mem_bottom) begin
				FHP_read_addr <= 9'd_0;
			end
			else begin
				FHP_read_addr <= (FHP_read_addr + 1);
			end

			// Write.
			if ((FHP_read_addr == 9'd_1) && (write_addr == 9'd_1)) begin
				write_addr   <= 9'd_0;
				write_data   <= {c_node_1_out, c_node_0_out};
				write_enable <= 1'b1;
			end
			else if (write_addr == mem_bottom) begin
				write_enable <= 1'b0;

				// Goto Propagation state.
				state <= 2'd_3;

				// Set initial condition of Propagation state.
				FHP_read_addr <= 9'd_2;
				write_addr   <= 9'd_0;

				n_up_reg <= 12'd_0;
				n_reg    <= read_data;
			end
			else begin
				write_addr   <= (write_addr + 1);
				write_data   <= {c_node_1_out, c_node_0_out};
			end
		end
		else begin // Propagation state
			// Read.
			if (FHP_read_addr < mem_bottom) begin
				FHP_read_addr <= (FHP_read_addr + 1);
			end

			// Update nodes.
			if (FHP_read_addr == 9'd_2) begin
				n_down_reg <= read_data;
				wall_up    <= 1'b_1;
				wall_down  <= 1'b_0;
			end
			else if (write_addr == 9'd_477) begin
				n_up_reg   <= n_reg;
				n_reg      <= n_down_reg;
				n_down_reg <= 12'd_0;
				wall_down  <= 1'b_1;
			end
			else begin
				n_up_reg   <= n_reg;
				n_reg      <= n_down_reg;
				n_down_reg <= read_data;
				wall_up    <= 1'b_0;
			end


			// Write.
			if (FHP_read_addr == 9'd_3) begin
				write_addr   <= 9'd_0;
				write_data   <= {p_node_1_out, p_node_0_out};
				write_enable <= 1'b1;
			end
			else if (write_addr == mem_bottom) begin
				write_enable <= 1'b0;

				// Goto Stall state.
				state        <= 2'd_1;
			end
			else begin
				write_addr   <= (write_addr + 1);
				write_data   <= {p_node_1_out, p_node_0_out};
			end
		end
	end

	// Output logics.
	assign vga_read_data = read_data;
	assign n_up          = n_up_reg;
	assign n             = n_reg;
	assign n_down        = n_down_reg;

endmodule // end top level

`timescale 1ns / 1ns
module FHPCol_testbench();
	wire [11:0] vga_read_data, n_up, n, n_down;
	
	
	// inputs and outputs for testing
	wire [8:0]  vga_read_address_w;
	wire        clk_w, reset_w;

	// inputs reg
	reg  [8:0]  vga_read_address;
	reg         clk, reset;

	assign clk_w              = clk;
	assign reset_w            = reset;
	assign vga_read_address_w = vga_read_address;

	// Instantiate testing
	FHPCol col0 (
		.vga_read_data      (vga_read_data),
		.n_up               (n_up),
		.n                  (n),
		.n_down             (n_down),
		.vga_read_address   (vga_read_address_w),
		.wall_left          (1'b_1),
		.wall_right         (1'b_1),
		.l_up               (12'd_0),
		.l_n                (12'd_0),
		.l_down             (12'd_0),
		.r_up               (12'd_0),
		.r_n                (12'd_0),
		.r_down             (12'd_0),
		.init               (1'b_1),
		.rnd                (1'b1),
		.go                 (1'b1),
		.clk                (clk_w),
		.reset              (reset_w)
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
		// reset inital values
		vga_read_address <= 9'd_0;

		// reset
		reset <= 1'b1; @(posedge clk); @(posedge clk);
		reset <= 1'b0; @(posedge clk);
		
		// simulate
		// simulate for 1000000 time cycles
		for(i = 1; i < 5000; i = i + 1) begin
			@(posedge clk);
		end
		
		@(posedge clk);
		@(posedge clk);
		
		$stop; // End the simulation.
	end

endmodule

