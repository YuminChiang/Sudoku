`timescale 1ns/10ps
`define CYCLE      20.0   
`define MAX_CYCLE  10000      	        
`define tb2		// Modify to test different pattern

`ifdef tb1
  `define EXPECT "./dat/tb1_goal.dat"
`elsif tb2
  `define EXPECT "./dat/tb2_goal.dat"
`elsif tb3
  `define EXPECT "./dat/tb3_goal.dat"
`endif

`include "./mem/ROM.sv"
`include "./mem/RAM.sv"

module testfixture;
parameter DATA_N_PAT = 81;
parameter t_reset = `CYCLE*2;


logic clk;
logic rst;
logic [6:0] err_IRAM;
logic [7:0] out_mem[0:80];


logic ROM_rd;
logic [6:0] ROM_A;
logic RAM_ceb;
logic RAM_web;
logic [7:0] RAM_D;
logic [6:0] RAM_A;
logic [7:0] RAM_Q;
logic done;
logic [7:0] ROM_Q;

integer cycle_count;
integer i, j, k, l, err, err1;
logic over, over1;

Sudoku u_Sudoku(
	.clk		(clk	  ), 
	.rst		(rst	  ), 
	.ROM_rd		(ROM_rd   ), 
	.ROM_A		(ROM_A    ), 
	.ROM_Q		(ROM_Q    ), 
	.RAM_ceb	(RAM_ceb  ), 
	.RAM_web    (RAM_web  ),
	.RAM_D		(RAM_D    ), 
	.RAM_A		(RAM_A    ),
	.RAM_Q		(RAM_Q	  ), 
	.done		(done     )
);

ROM #(8) ROM_1(
	.clk		(clk	  ), 
	.rst		(rst	  ),
	.ROM_rd		(ROM_rd   ), 
	.ROM_data	(ROM_Q    ), 
	.ROM_addr	(ROM_A    )
);

RAM #(8) RAM_1(
	.clk		(clk 	  ),
	.RAM_D		(RAM_D	  ), 
	.RAM_A		(RAM_A	  ), 
	.RAM_ceb	(RAM_ceb  ),
	.RAM_web	(RAM_web  ),
	.RAM_Q		(RAM_Q	  )
);

// initial begin
//     $fsdbDumpfile("Sudoku.fsdb");
//     $fsdbDumpvars();
//     $fsdbDumpMDA;
// end

initial	$readmemb (`EXPECT, out_mem);

initial begin
   clk         = 1'b0;
   over	       = 1'b0;
   err         = 0; 
end

always begin #(`CYCLE/2) clk <= ~clk; end

initial begin
   rst = 1'b1;
   #t_reset        rst = 1'b0;                   
end  

initial @(posedge done) begin
   	for(k=0;k<81;k=k+1)begin
		if( RAM_1.RAM_M[k] !== out_mem[k]) 
		begin
         	$display("ERROR at %d:output %h !=expect %h ",k, RAM_1.RAM_M[k], out_mem[k]);
         	err = err+1 ;
		end
        else 
		if ( out_mem[k] === 8'dx) begin
            $display("ERROR at %d:output %h !=expect %h ",k, RAM_1.RAM_M[k], out_mem[k]);
			err = err+1;
        end

 		over=1'b1;
	end
	if (err === 0 &&  over===1'b1) begin
		$display("All data have been generated successfully!\n");
		`ifdef tb1
			$display(">>> Pattern: tb1");
		`elsif tb2
			$display(">>> Pattern: tb2");
		`elsif tb3
			$display(">>> Pattern: tb3");
		`endif
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  Congratulations !!    /      / O.O  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation PASS !!    /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display("\n");
		$display("Cycle: %0d \n", cycle_count);
		#10 $finish;
	end
	else if( over===1'b1) begin 
		$display("There are %d errors!\n", err);
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  OOPS !!               /      / X.X  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation Failed !!  /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display("\n");
		#10 $finish;
	end
end

always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count <= 0;
			err1 <= 0;
			over1 <= 0;
        end else begin
            cycle_count <= cycle_count + 1;

            if (cycle_count >= `MAX_CYCLE) begin
                $display("ERROR: Simulation stopped. Cycle count exceeded MAX_CYCLE = %0d", `MAX_CYCLE);
				for(l=0;l<81;l=l+1)begin
					if( RAM_1.RAM_M[l] !== out_mem[l]) 
					begin
						$display("ERROR at %d:output %h !=expect %h ",k, RAM_1.RAM_M[l], out_mem[l]);
						err1 = err1+1 ;
					end
					else 
					if ( out_mem[l] === 8'dx) begin
						$display("ERROR at %d:output %h !=expect %h ",k, RAM_1.RAM_M[l], out_mem[l]);
						err1 = err1+1;
					end
					over1=1'b1;
				end
				if( over1===1'b1) begin 
					`ifdef tb1
						$display(">>> Pattern: tb1");
					`elsif tb2
						$display(">>> Pattern: tb2");
					`elsif tb3
						$display(">>> Pattern: tb3");
					`endif
					$display("There are %d errors!\n", err1);
					$display("                   //////////////////////////               ");
					$display("                   /                        /       |\__||  ");
					$display("                   /  OOPS !!               /      / X.X  | ");
					$display("                   /                        /    /_____   | ");
					$display("                   /  Simulation Failed !!  /   /^ ^ ^ \\  |");
					$display("                   /                        /  |^ ^ ^ ^ |w| ");
					$display("                   //////////////////////////   \\m___m__|_|");
					$display("\n");
				end
                $finish;
            end
        end
    end

endmodule

