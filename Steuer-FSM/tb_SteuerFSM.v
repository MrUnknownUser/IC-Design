`timescale 1ns/1ps

module tb_SteuerFSM;
    reg clk, rst, start, enter;
    reg [3:0] digit;
    reg [2:0] op;
    wire [7:0] result;
    wire done;

    SteuerFSM uut (.clk(clk), .rst(rst), .start(start), .enter(enter), .digit(digit), .op(op), .result(result), .done(done));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("steuerFsm.vcd");
        $dumpvars(0, tb_SteuerFSM);

        $monitor("t=%0t digit=%d op=%b result=%d done=%b", $time, digit, op, result, done);

        clk=0; rst=1; start=0; enter=0; digit=0; op=0;
        #12 rst=0;

        start=1; #10; start=0;
        digit=4; enter=1; #10; enter=0; #10;
        digit=3; enter=1; #10; enter=0; #10;
        op=3'b000; #10
        #20;

        $display("Result=%d done=%d", result, done);

        #10 $finish;
    end
endmodule