module mux #(parameter WIDTH = 2)(
    input  wire [WIDTH-1:0] in,
    input  wire [$clog2(WIDTH)-1:0] select,
    output wire out
);

assign out = in[select];


endmodule