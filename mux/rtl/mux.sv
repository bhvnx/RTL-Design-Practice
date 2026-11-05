module mux (
    input  wire [1:0] in,
    input  wire select,
    output wire out
);

assign out = select? in[0] :in[1];


endmodule