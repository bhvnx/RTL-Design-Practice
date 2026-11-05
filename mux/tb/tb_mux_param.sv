`timescale 1ns/1ps

// Module under test:
//   module mux #(parameter WIDTH = 2)(
//       input  wire [WIDTH-1:0]         in,
//       input  wire [$clog2(WIDTH)-1:0] select,
//       output wire                     out
//   );
// Logic: out = in[select]
module tb_mux_param;

    parameter int WIDTH = 2;  // number of inputs; must be a power of 2

    localparam int SEL_W = $clog2(WIDTH);

    logic [WIDTH-1:0]  in;
    logic [SEL_W-1:0]  select;
    wire               out;

    mux #(.WIDTH(WIDTH)) dut (
        .in     (in),
        .select (select),
        .out    (out)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic  exp_out,
        input string label
    );
        #1;
        if (out !== exp_out) begin
            $error("FAIL [%s] in=%b select=%0d | got out=%b, expected out=%b",
                   label, in, select, out, exp_out);
            fail_count++;
        end else begin
            $display("PASS [%s] in=%b select=%0d | out=%b", label, in, select, out);
            pass_count++;
        end
    endtask

    initial begin
        $display("=== tb_mux_param: WIDTH=%0d, SEL_W=%0d ===", WIDTH, SEL_W);

        // --- directed: walk select through every input position ---
        // Set exactly one input high at a time and verify it propagates
        $display("--- one-hot input sweep ---");
        for (int s = 0; s < WIDTH; s++) begin
            in = '0;
            in[s] = 1'b1;
            select = SEL_W'(s);
            check(1'b1, $sformatf("one_hot_sel%0d_hi", s));

            in = '1;
            in[s] = 1'b0;
            select = SEL_W'(s);
            check(1'b0, $sformatf("one_hot_sel%0d_lo", s));
        end

        // --- directed: all-zeros and all-ones input bus ---
        $display("--- all-0 / all-1 input sweep ---");
        for (int s = 0; s < WIDTH; s++) begin
            in = '0; select = SEL_W'(s);
            check(1'b0, $sformatf("all0_sel%0d", s));

            in = '1; select = SEL_W'(s);
            check(1'b1, $sformatf("all1_sel%0d", s));
        end

        // --- directed: alternating patterns ---
        $display("--- alternating patterns ---");
        in = WIDTH'('h5555_5555); // ...0101
        for (int s = 0; s < WIDTH; s++) begin
            select = SEL_W'(s);
            check(logic'(s[0] == 0 ? 1'b1 : 1'b0), $sformatf("alt55_sel%0d", s));
        end

        in = WIDTH'('hAAAA_AAAA); // ...1010
        for (int s = 0; s < WIDTH; s++) begin
            select = SEL_W'(s);
            check(logic'(s[0] == 1 ? 1'b1 : 1'b0), $sformatf("altAA_sel%0d", s));
        end

        // --- randomized sweep ---
        $display("--- randomized sweep (40 vectors) ---");
        begin
            logic [WIDTH-1:0] r_in;
            logic [SEL_W-1:0] r_sel;
            logic             exp;
            repeat (40) begin
                r_in  = $urandom();
                r_sel = SEL_W'($urandom_range(0, WIDTH-1));
                exp   = r_in[r_sel];
                in = r_in; select = r_sel;
                #1;
                if (out !== exp) begin
                    $error("FAIL [rand] in=%b select=%0d | got out=%b, expected out=%b",
                           r_in, r_sel, out, exp);
                    fail_count++;
                end else begin
                    pass_count++;
                end
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
