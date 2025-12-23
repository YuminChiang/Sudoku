`timescale 1ns/10ps

`ifdef tb1
  `define DATA "./dat/data1.dat"
`elsif tb2
  `define DATA "./dat/data2.dat"
`elsif tb3
  `define DATA "./dat/data3.dat"
`endif

module ROM #(
	parameter Width = 8 ,
	parameter Row   = 81
)(
	input 							ROM_rd	 ,
	input  		 [$clog2(Row)-1:0]	ROM_addr, 
	input 							clk		 , 
	input 							rst		 ,
	output logic [Width-1:0] 	    ROM_data
);

string data_path = "./dat";
logic [Width-1:0] sti_M [0:Row-1];
integer i;

initial begin
	@ (negedge rst) $readmemb (`DATA , sti_M);
end

always@(negedge clk) 
	if (ROM_rd) ROM_data <= sti_M[ROM_addr];
	
endmodule