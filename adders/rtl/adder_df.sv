module adder#(parameter WIDTH = 2)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH:0] out
);

assign out = a+b+cin; 


endmodule