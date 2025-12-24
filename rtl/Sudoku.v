module Sudoku(
    input             clk,
    input             rst,
    output reg        ROM_rd,
    output reg  [6:0] ROM_A,
    input       [7:0] ROM_Q,
    output reg        RAM_ceb,
    output reg        RAM_web,
    output reg  [7:0] RAM_D,
    output reg  [6:0] RAM_A,
    input       [7:0] RAM_Q,
    output reg        done
);

localparam IDLE      = 3'd0,
		   READ_ROM  = 3'd1,
		   SOLVE     = 3'd2,
		   WRITE_RAM = 3'd3,
		   DONE_S    = 3'd4;

reg [2:0] state, next_state;

reg [7:0] grid  [0:80];  // 81 cells, each 8-bit (0/1..9)
reg       fixed [0:80];  // 1 = given clue, cannot change
reg [3:0] cand  [0:80];  // candidate pointer for each cell (1..9)

reg [6:0] addr_counter;  // for ROM/RAM streaming 0..80

// solve pointers
reg [6:0] pos;           // 0..81 (81 means solved)

// Solve sub-FSM
localparam S_FIND      = 3'd0,  // move to next cell to fill (skip fixed)
           S_TRY       = 3'd1,  // if cand>9 => backtrack else check
		   S_CHECK     = 3'd2,  // validate cand at pos
		   S_BACK_CLR  = 3'd3,  // clear current pos, step back
		   S_BACK_SKIP = 3'd4;  // skip fixed while stepping back, then try next cand

reg [2:0] solve_state;

integer i;

function automatic is_valid;
	input [6:0] idx;
	input [3:0] val;
	integer r, c, br, bc, base;
	integer k;
	begin
		is_valid = 1'b1;

		// idx in 0..80, val in 1..9
		r = idx / 9;
		c = idx % 9;

		// row check
		for (k = 0; k < 9; k = k + 1) begin
			if (grid[r * 9 + k] == {4'b0, val}) is_valid = 1'b0;
		end

		// col check
		for (k = 0; k < 9; k = k + 1) begin
			if (grid[k * 9 + c] == {4'b0, val}) is_valid = 1'b0;
		end

		// block check
		br = (r / 3) * 3;
		bc = (c / 3) * 3;
		base = br*9 + bc;

		// 3 rows x 3 cols
		if (grid[base + 0]  == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 1]  == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 2]  == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 9]  == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 10] == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 11] == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 18] == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 19] == {4'b0, val}) is_valid = 1'b0;
		if (grid[base + 20] == {4'b0, val}) is_valid = 1'b0;
	end
endfunction

always @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

always @(*) begin
	case (state)
		IDLE:      next_state = READ_ROM;
		READ_ROM:  next_state = (addr_counter == 7'd80) ? SOLVE : READ_ROM;
		SOLVE:     next_state = (pos == 7'd81) ? WRITE_RAM : SOLVE;
		WRITE_RAM: next_state = (addr_counter == 7'd80) ? DONE_S : WRITE_RAM;
		DONE_S:    next_state = DONE_S;
		default:   next_state = IDLE;
	endcase
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		addr_counter <= 7'd0;
		done         <= 1'b0;

		pos          <= 7'd0;
		solve_state  <= S_FIND;

		// clear arrays (synth OK for small arrays like 81 entries)
		for (i = 0; i < 81; i = i + 1) begin
			grid[i]  <= 8'd0;
			fixed[i] <= 1'b0;
			cand[i]  <= 4'd0;
		end
	end else begin
		case (state)

			IDLE: begin
				addr_counter <= 7'd0;
				done         <= 1'b0;

				pos         <= 7'd0;
				solve_state <= S_FIND;

				// (optional) clear candidates for cleanliness
				for (i = 0; i < 81; i = i + 1) begin
					cand[i] <= 4'd0;
				end
			end
			READ_ROM: begin
				// latch ROM_Q into grid[addr_counter]
				grid[addr_counter]  <= ROM_Q;
				fixed[addr_counter] <= (ROM_Q != 8'd0);

				// next address
				addr_counter <= (addr_counter == 7'd80) ? 7'd0 : (addr_counter + 7'd1);

				// prepare solve
				if (addr_counter == 7'd80) begin
					pos         <= 7'd0;
					solve_state <= S_FIND;
					// reset cand pointers
					for (i = 0; i < 81; i = i + 1) begin
						cand[i] <= 4'd0;
					end
				end
			end
			SOLVE: begin
				case (solve_state)

					// Move forward to find a non-fixed position to fill
					S_FIND: begin
						if (pos == 7'd81) begin
							// solved (guard)
							solve_state <= S_FIND;
						end else if (fixed[pos]) begin
							pos <= pos + 7'd1;
						end else begin
							// this cell is editable
							// ensure it's empty before trying
							grid[pos] <= 8'd0;
							cand[pos] <= 4'd1;
							solve_state <= S_TRY;
						end
					end

					// Decide to check or backtrack
					S_TRY: begin
						if (cand[pos] > 4'd9) begin
							solve_state <= S_BACK_CLR;
						end else begin
							solve_state <= S_CHECK;
						end
					end

					// Validate candidate
					S_CHECK: begin
						if (is_valid(pos, cand[pos])) begin
							grid[pos] <= {4'b0, cand[pos]}; // place number
							pos <= pos + 7'd1;
							solve_state <= S_FIND;
						end else begin
							cand[pos] <= cand[pos] + 4'd1;
							solve_state <= S_TRY;
						end
					end

					// Clear current cell and step back
					S_BACK_CLR: begin
						// clear current editable cell (the one that failed)
						grid[pos] <= 8'd0;
						cand[pos] <= 4'd0;

						if (pos == 7'd0) begin
							// theoretically no-solution; keep safe
							pos <= 7'd0;
							solve_state <= S_FIND;
						end else begin
							pos <= pos - 7'd1;
							solve_state <= S_BACK_SKIP;
						end
					end

					// Skip fixed cells while moving backward;
					// when landing on editable cell: clear it and try next candidate
					S_BACK_SKIP: begin
						if (fixed[pos]) begin
							if (pos == 7'd0) begin
								solve_state <= S_FIND;
							end else begin
								pos <= pos - 7'd1;
							end
						end else begin
							// clear previous editable cell then increment candidate and retry
							grid[pos] <= 8'd0;
							cand[pos] <= cand[pos] + 4'd1;
							solve_state <= S_TRY;
						end
					end

					default: begin
						solve_state <= S_FIND;
					end
				endcase
			end
			WRITE_RAM: begin
				addr_counter <= (addr_counter == 7'd80) ? 7'd0 : (addr_counter + 7'd1);
			end
			DONE_S: begin
				done <= 1'b1;
			end

		endcase
	end
end

always @(*) begin
	// defaults
	ROM_rd  = 1'b0;
	ROM_A   = 7'd0;

	RAM_ceb = 1'b0;
	RAM_web = 1'b1; // read by default
	RAM_A   = 7'd0;
	RAM_D   = 8'd0;

	case (state)

		READ_ROM: begin
			ROM_rd = 1'b1;
			ROM_A  = addr_counter;
		end

		WRITE_RAM: begin
			RAM_ceb = 1'b1;
			RAM_web = 1'b0;        // write
			RAM_A   = addr_counter;
			RAM_D   = grid[addr_counter];
		end

		default: begin
			// keep defaults
		end
	endcase
end

endmodule
