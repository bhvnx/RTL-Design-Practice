`timescale 1ns/1ps

// Assumptions: module mux2to1 (input logic a, b, sel, output logic y)
module tb_mux2to1;

    logic a, b, sel, y;

    mux dut (
        .in   ({a,b}),
        .select (sel),
        .out   (y)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(
        input logic exp_y,
        input string label
    );
        #1;
        if (y !== exp_y) begin
            $error("FAIL [%s] a=%b b=%b sel=%b | got y=%b, expected y=%b",
                   label, a, b, sel, y, exp_y);
            fail_count++;
        end else begin
            $display("PASS [%s] a=%b b=%b sel=%b | y=%b", label, a, b, sel, y);
            pass_count++;
        end
    endtask

    initial begin
        $display("=== tb_mux2to1: exhaustive truth table ===");

        // sel=0 -> y should equal a
        {a, b, sel} = 3'b000; check(1'b0, "sel0_a0b0");
        {a, b, sel} = 3'b010; check(1'b0, "sel0_a0b1");
        {a, b, sel} = 3'b100; check(1'b1, "sel0_a1b0");
        {a, b, sel} = 3'b110; check(1'b1, "sel0_a1b1");

        // sel=1 -> y should equal b
        {a, b, sel} = 3'b001; check(1'b0, "sel1_a0b0");
        {a, b, sel} = 3'b011; check(1'b1, "sel1_a0b1");
        {a, b, sel} = 3'b101; check(1'b0, "sel1_a1b0");
        {a, b, sel} = 3'b111; check(1'b1, "sel1_a1b1");

        $display("=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        $finish;
    end

endmodule
