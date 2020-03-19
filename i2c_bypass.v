module tmp(
	sda0,
	sda1
);

inout wire	sda0;
inout wire	sda1;

assign	sda0 = sda1;
assign	sda1 = sda0;

endmodule
