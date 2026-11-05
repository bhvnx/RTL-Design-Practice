module adder #(parameter WIDTH = 2)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH:0]   out
);
    // Bit-level generate and propagate
    wire [WIDTH-1:0] G;   // G[i] = a[i] & b[i]  : bit i generates a carry unconditionally
    wire [WIDTH-1:0] P;   // P[i] = a[i] ^ b[i]  : bit i propagates an incoming carry

    assign G = a & b;
    assign P = a ^ b;

    // carry[i]: carry INTO bit position i; carry[0]=cin, carry[WIDTH]=cout
    logic [WIDTH:0] carry;

    // pp[i][j] = P[i] & P[i-1] & ... & P[j]  (prefix propagate product, i >= j)
    // Used to express each carry as a sum-of-products over G and cin with no carry chain.
    logic [WIDTH-1:0] pp [WIDTH-1:0];

    always_comb begin
        // ---- build prefix propagate products ----
        for (int i = 0; i < WIDTH; i++)
            pp[i][i] = P[i];                        // single-bit case

        for (int i = 1; i < WIDTH; i++)
            for (int j = 0; j < i; j++)
                pp[i][j] = P[i] & pp[i-1][j];      // extend product downward

        // ---- CLA carry equations (all computed in parallel) ----
        // carry[i+1] = G[i]                           <- bit i self-generates
        //            | pp[i][1] & G[0]                <- prop from i..1, gen at 0
        //            | pp[i][2] & G[1]                <- prop from i..2, gen at 1
        //            | ...
        //            | pp[i][0] & cin                 <- propagate all the way to cin
        carry[0] = cin;
        for (int i = 0; i < WIDTH; i++) begin
            carry[i+1] = G[i];
            for (int j = 1; j <= i; j++)
                carry[i+1] = carry[i+1] | (pp[i][j] & G[j-1]);
            carry[i+1] = carry[i+1] | (pp[i][0] & cin);
        end
    end

    // Sum bits: s[i] = P[i] ^ carry[i]
    assign out = {carry[WIDTH], P ^ carry[WIDTH-1:0]};

endmodule
