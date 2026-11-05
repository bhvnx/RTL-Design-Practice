`timescale 1ns/1ps

// Module under test:
//   module adder #(parameter WIDTH = 2)(
//       input  wire [WIDTH-1:0] a,
//       input  wire [WIDTH-1:0] b,
//       input  wire             cin,
//       output wire [WIDTH:0]   out   // WIDTH+1 bits: captures carry-out
//   );
// Logic: out = a + b + cin
module tb_adder;

    parameter int WIDTH = 4;  // change to test different widths

    logic [WIDTH-1:0]  a, b;
    logic              cin;
    wire  [WIDTH:0]    out;

    adder #(.WIDTH(WIDTH)) dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .out (out)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(input string label);
        logic [WIDTH:0] exp;
        exp = {1'b0, a} + {1'b0, b} + {{WIDTH{1'b0}}, cin};
        #1;
        if (out !== exp) begin
            $error("FAIL [%s] a=%0d b=%0d cin=%0d | got out=%0d, expected %0d",
                   label, a, b, cin, out, exp);
            fail_count++;
        end else begin
            $display("PASS [%s] a=%0d b=%0d cin=%0d | out=%0d", label, a, b, cin, out);
            pass_count++;
        end
    endtask

    initial begin
        $display("=== tb_adder: WIDTH=%0d ===", WIDTH);

        // --- corner cases: cin=0 ---
        $display("--- corner cases (cin=0) ---");
        cin = 0;
        a = '0; b = '0;                     check("0+0+0");
        a = '0; b = '1;                     check("0+max+0");
        a = '1; b = '0;                     check("max+0+0");
        a = '1; b = '1;                     check("max+max+0");
        a = WIDTH'(1 << (WIDTH-1)); b = '0; check("MSB_a+0");
        a = '0; b = WIDTH'(1 << (WIDTH-1)); check("MSB_b+0");

        // --- corner cases: cin=1 ---
        $display("--- corner cases (cin=1) ---");
        cin = 1;
        a = '0; b = '0;                     check("0+0+1");
        a = '0; b = '1;                     check("0+max+1");   // double carry
        a = '1; b = '0;                     check("max+0+1");
        a = '1; b = '1;                     check("max+max+1"); // max possible
        a = WIDTH'(1 << (WIDTH-1)); b = '0; check("MSB_a+1");
        a = '0; b = WIDTH'(1 << (WIDTH-1)); check("MSB_b+1");

        // --- exhaustive sweep (only practical for small WIDTH) ---
        if (WIDTH <= 5) begin
            $display("--- exhaustive sweep (2^%0d combos x 2 cin) ---", 2*WIDTH);
            for (int c = 0; c < 2; c++) begin
                for (int i = 0; i < (1 << WIDTH); i++) begin
                    for (int j = 0; j < (1 << WIDTH); j++) begin
                        a   = WIDTH'(i);
                        b   = WIDTH'(j);
                        cin = logic'(c);
                        check($sformatf("ex_%0d_%0d_c%0d", i, j, c));
                    end
                end
            end
        end else begin
            // --- randomized sweep for larger widths ---
            $display("--- randomized sweep (200 vectors) ---");
            begin
                logic [WIDTH-1:0] r_a, r_b;
                logic             r_cin;
                repeat (200) begin
                    r_a   = $urandom();
                    r_b   = $urandom();
                    r_cin = $urandom_range(0, 1);
                    a = r_a; b = r_b; cin = r_cin;
                    check($sformatf("rand_%0h_%0h_c%0d", r_a, r_b, r_cin));
                end
            end
        end

        // --- carry boundary walk: both cin values ---
        $display("--- carry boundary walk ---");
        begin
            logic [WIDTH-1:0] max_val;
            max_val = '1;
            for (int k = 0; k <= 4; k++) begin
                a = max_val - WIDTH'(k); b = WIDTH'(k);
                cin = 0; check($sformatf("carry_walk_%0d_c0", k));
                cin = 1; check($sformatf("carry_walk_%0d_c1", k));
            end
        end

        $display("=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        $finish;
    end

endmodule
