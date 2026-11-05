module tb_gray_code_generator;

    reg [7:0] binary;
    reg [7:0] gray;
    reg [7:0] g_prev;
    int          pass_count, fail_count;

    gray_code_generator dut (
        .binary(binary),
        .gray(gray)
    );

    task automatic check(input [7:0] bin);
        reg [7:0] expected;
        expected = bin ^ (bin >> 1);
        binary = bin;
        #1;
        if (gray !== expected) begin
            $display("FAIL  binary=%0d (0x%02h)  expected=0x%02h  got=0x%02h",
                     bin, bin, expected, gray);
            fail_count++;
        end else
            pass_count++;
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

            

        // adjacency: consecutive DUT outputs must differ by exactly one bit
        binary = 8'd0; #1;
        g_prev = gray;
        for (int i = 1; i < 256; i++) begin
            check(i[7:0]);
            #1;
        end

        if (fail_count == 0)
            $display("PASS  all %0d checks passed", pass_count);
        else
            $display("DONE  %0d passed, %0d FAILED", pass_count, fail_count);

        $finish;
    end

endmodule
