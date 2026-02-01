module simple_fsm (
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  done
);
    localparam IDLE  = 2'b00;
    localparam BUSY  = 2'b01;
    localparam DONE  = 2'b10;
    
    reg [1:0] state, next_state;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE: next_state = start ? BUSY : IDLE;
            BUSY: next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(*) begin
        done = (state == DONE);
    end
endmodule
