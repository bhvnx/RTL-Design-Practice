module gray_code_generator(
    input  wire [7:0] binary,
    output wire [7:0] gray
);

assign gray = binary ^ (binary >> 1);



endmodule