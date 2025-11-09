module SteuerFSM (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [3:0] digit,
    input wire enter,
    input wire [2:0] op,
    output reg [7:0] result,
    output reg done
);

    parameter IDLE = 3'd0,
            INPUT_A = 3'd1,
            INPUT_B = 3'd2,
            OP_SELECT = 3'd3,
            CALC = 3'd4,
            RESULT = 3'd5;
    
    reg [2:0] state, next_state;
    reg [7:0] A, B;

    // Zustandsregister
    always @(posedge clk or posedge rst) begin
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Übergangslogik
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if(start) next_state = INPUT_A;
            INPUT_A: if(enter) next_state = INPUT_B;
            INPUT_B: if(enter) next_state = OP_SELECT;
            OP_SELECT: next_state = CALC;
            CALC:  next_state = RESULT;
            RESULT: next_state = IDLE;
        endcase
    end

    // Speicherung
    always @(posedge clk) begin
        if(state == INPUT_A && enter)
            A <= digit;
        else if(state == INPUT_B && enter)
            B <= digit;
    end

    //Berechnung
    always @(*) begin
        result = 0;
        done = 0;
        case (state)
            CALC: begin
                case (op)
                    3'b000: result = A + B;
                    3'b001: result = A - B;
                    3'b010: result = A & B;
                    3'b011: result = A | B;
                    3'b100: result = A * B;
                    3'b101: result = A / B;
                    default: result = (B!=0) ? A / B : 8'hFF; //Div durch 0
                endcase
            end
            RESULT: begin
                done = 1;
            end 
        endcase
    end
endmodule