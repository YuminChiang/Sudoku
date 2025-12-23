module Sudoku(
	input        clk     , 
	input        rst     , 
	output reg       ROM_rd  , 
	output reg [6:0] ROM_A   , 
	input  [7:0] ROM_Q   , 
	output reg       RAM_ceb , 
	output reg       RAM_web ,
	output reg [7:0] RAM_D   , 
	output reg [6:0] RAM_A   ,
	input  [7:0] RAM_Q	 , 
	output reg   done      
);

localparam IDLE      = 3'd0,
		   READ_ROM  = 3'd1,
		   SOLVE     = 3'd2,
		   WRITE_RAM = 3'd3,
		   DONE      = 3'd4;

reg [2:0] state, next_state;

reg [7:0] grid [0:80]; // 9x9 Sudoku grid
reg [6:0] addr_counter;

always @(posedge clk or posedge rst) begin
	if (rst)
		state <= IDLE;
	else
		state <= next_state;
end

always @(*) begin
	case (state)
		IDLE: next_state = READ_ROM;
		READ_ROM: next_state = (addr_counter == 7'd81) ? WRITE_RAM : READ_ROM;
		// SOLVE: next_state = WRITE_RAM;
		WRITE_RAM: next_state = (addr_counter == 7'd81) ? DONE  : WRITE_RAM;
		DONE: next_state = DONE;
		default: next_state = IDLE;
	endcase
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		addr_counter <= 7'd0;
		done <= 1'b0;
	end else begin
		case (state)
			IDLE: begin
				addr_counter <= 7'd0;
				done <= 1'b0;
			end
			READ_ROM: begin
				grid[addr_counter] <= ROM_Q;
				addr_counter <= addr_counter + 1;
			end
			WRITE_RAM: begin
				addr_counter <= addr_counter + 1;
			end
			DONE: begin
				done <= 1'b1;
			end
		endcase
	end
end

always @(*) begin
	ROM_rd = 0;
	ROM_A  = 0;
	RAM_ceb = 0;
	RAM_web = 1; // Read by default
	RAM_A = 0;
	RAM_D = 0;
	case (state)
		READ_ROM: begin
			ROM_rd = 1;
			ROM_A  = addr_counter;
		end
		WRITE_RAM: begin
			RAM_ceb = 1;
			RAM_web = 0; // Write
			RAM_A = addr_counter;
			RAM_D = grid[addr_counter];
		end
		default: begin
			ROM_rd = 0;
			ROM_A  = 0;
			RAM_ceb = 0;
			RAM_web = 1;
			RAM_A = 0;
			RAM_D = 0;
		end
	endcase
end

endmodule