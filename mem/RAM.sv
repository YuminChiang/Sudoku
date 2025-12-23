`timescale 1ns/10ps

module RAM #(
	parameter Width = 8 
)(
	input 							RAM_ceb,  
	input 		 [6 : 0]			RAM_A 	, 
	input				     		clk		, 
	input 		 [Width-1:0] 		RAM_D 	,
	input 					 		RAM_web,
	output logic [Width-1:0] 		RAM_Q
);

logic [7:0] RAM_M [0:80];
integer i;

initial begin
	for (i=0; i<=81; i=i+1) 
		RAM_M[i] = 0;
end

always@(negedge clk) begin
	if (RAM_ceb) begin
		if(~RAM_web)
			RAM_M[RAM_A] <= (RAM_A > 7'd80) ? 8'hFF : RAM_D;
		else 
			RAM_Q <= RAM_M[RAM_A];
	end
end
	
endmodule