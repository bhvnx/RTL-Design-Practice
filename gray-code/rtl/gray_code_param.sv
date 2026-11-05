module gray_code_generator #(parameter WIDTH = 8)(
    input  wire [WIDTH-1:0] binary,
    output wire [WIDTH-1:0] gray
);

assign gray = binary ^ (binary >> 1);



endmodule