// 設計 fsm 去檢查1個序列是否至少有3個0 1個 1
// 初次設計

module seq(
    input clk,
    input rst_n,
    input in_data,
    input in_state_reset,
    output reg [2:0] state,
    output reg [2:0] next_state,
    output reg out
);

parameter s0 = 0;
parameter s1 = 1;
parameter s2 = 2;
parameter s3 = 3;
parameter s4 = 4;
parameter s5 = 5;
parameter s6 = 6;
parameter s7 = 7;


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= s0;
    end
    else begin
       state <= next_state;
    end
end
always @(*) begin
    
    case (state) 
    s0: begin
        if (in_data) begin
            next_state = s1;
            out = 0;
        end
        else begin 
            next_state = s2;
            out = 0;
        end
    end
    s1: begin
        if (in_data) begin
            next_state = s1;
            out = 0;
        end
        else begin 
            next_state = s4;
            out = 0;
        end
    end
    s2: begin
        if (in_data) begin
            next_state = s4;
            out = 0;
        end
        else begin 
            next_state = s3;
            out = 0;
        end
    end
    s3: begin
        if (in_data) begin
            next_state = s5;
            out = 0;
        end
        else begin 
            next_state = s6;
            out = 0;
        end
    end
    s4: begin
        if (in_data) begin
            next_state = s4;
            out = 0;
        end
        else begin 
            next_state = s5;
            out = 0;
        end
    end
    s5: begin
        if (in_data) begin
            next_state = s5;
            out = 0;
        end
        else begin 
            next_state = s7;
            out = 1;
        end
    end
    s6: begin
        if (in_data) begin
            next_state = s7;
            out = 1;
        end
        else begin 
            next_state = s6;
            out = 0;
        end
    end
    s7: begin
        if (in_data) begin
            next_state = s7;
            out = 1;
        end
        else begin 
            next_state = s7;
            out = 1;
        end
    end
    if (in_state_reset) begin
         out = 0;
         state = s0;
    end
    endcase
end
endmodule

// 錯誤點 1 讓state multi driven
// 以下為更正後

module seq(
    input clk,
    input rst_n,
    input in_data,
    input in_state_reset,
    output reg [2:0] state,
    output reg out
);

parameter s0 = 3'd0,
          s1 = 3'd1,
          s2 = 3'd2,
          s3 = 3'd3,
          s4 = 3'd4,
          s5 = 3'd5,
          s6 = 3'd6,
          s7 = 3'd7;

reg [2:0] next_state;

// 時序 always：只負責狀態轉移與reset
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= s0;
    end else if (in_state_reset) begin
        state <= s0;
    end else begin
        state <= next_state;
    end
end

// 組合 always：只負責next_state, out
always @(*) begin
    //next_state = state;
   // out = 0;
    case (state)
        s0: if (in_data) next_state = s1; else next_state = s2;
        s1: if (in_data) next_state = s1; else next_state = s4;
        s2: if (in_data) next_state = s4; else next_state = s3;
        s3: if (in_data) next_state = s5; else next_state = s6;
        s4: if (in_data) next_state = s4; else next_state = s5;
        s5: if (in_data) next_state = s5; else next_state = s7;
        s6: if (in_data) next_state = s7; else next_state = s6;
        s7: next_state = s7;
        default: next_state = s0;
    endcase
    // output logic
    case (state)
 
        s7: out = 1;
        default: out = 0;
    endcase
end

endmodule