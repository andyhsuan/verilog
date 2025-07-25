
module MIPS (
    // INPUT
    input  clk,
    input  rst_n,
    input  in_valid,
    input  [31:0] instruction,
    input  [19:0] output_reg,
    // OUTPUT
    output reg          out_valid,
    output reg  [31:0]  out_1,
    output reg  [31:0]  out_2,
    output reg  [31:0]  out_3,
    output reg  [31:0]  out_4,
    output reg          instruction_fail
);
// Internal declarations
wire  [5:0]  Opcode;
wire  [4:0]  rs, rt, rd_w;
wire  [15:0] immd_w;
wire         Format_w;          // 0 = I‑type, 1 = R‑type
reg          legal;
reg          rs_legal, rt_legal, rd_legal;
wire         legalAddress;
wire         instruction_fail_w;
// Pipeline registers
reg  [31:0]  instrn_reg;
reg  [19:0]  output_reg_1, output_reg_2, output_reg_3;
reg          out_valid_1, out_valid_2, out_valid_3;
reg          instruction_fail_1, instruction_fail_2;
// Register file (6 × 32‑bit) & next‑state
reg  [31:0]  rf0, rf1, rf2, rf3, rf4, rf5;
reg  [31:0]  rf0_n, rf1_n, rf2_n, rf3_n, rf4_n, rf5_n;
// Read ports
reg  [31:0]  x_rs, x_rt;
// ALU
reg  [31:0]  alu_result;
// Stage‑1 : fetch input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        instrn_reg    <= 32'd0;
        output_reg_1  <= 20'd0;
        out_valid_1   <= 1'b0;
    end else begin
        instrn_reg    <= (in_valid) ? instruction  : 32'd0;
        output_reg_1  <= (in_valid) ? output_reg   : 20'd0;
        out_valid_1   <=  in_valid;
    end
end
// Stage‑2 : decode
assign Opcode     = instrn_reg[31:26];
assign rs         = instrn_reg[25:21];
assign rt         = instrn_reg[20:16];
assign rd_w       = (Format_w) ? instrn_reg[15:11] : rt; // R : rd ，I : rt
assign immd_w     = instrn_reg[15:0];
assign Format_w   = ~Opcode[3];                         

always @* begin
    if (Opcode == 6'b000000) begin
        case (instrn_reg[5:0])
            6'b100000, 6'b100100, 6'b100101,
            6'b100111, 6'b000000, 6'b000010: legal = 1'b1;
            default :                         legal = 1'b0;
        endcase
    end
    else if (Opcode == 6'b001000) begin
        legal = 1'b1;        // addi
    end
    else begin
        legal = 1'b0;
    end
end
// Register‑file read
always @* begin
    // rs
    case (rs)
        5'b10001: x_rs = rf5;
        5'b10010: x_rs = rf4;
        5'b01000: x_rs = rf3;
        5'b10111: x_rs = rf2;
        5'b11111: x_rs = rf1;
        5'b10000: x_rs = rf0;
        default : x_rs = 32'd0;
    endcase
    // rt
    case (rt)
        5'b10001: x_rt = rf5;
        5'b10010: x_rt = rf4;
        5'b01000: x_rt = rf3;
        5'b10111: x_rt = rf2;
        5'b11111: x_rt = rf1;
        5'b10000: x_rt = rf0;
        default : x_rt = 32'd0;
    endcase
end
always @* begin
    case (rs)
        5'b10001,5'b10010,5'b01000,5'b10111,5'b11111,5'b10000: rs_legal = 1'b1;
        default:                                              rs_legal = 1'b0;
    endcase
    case (rt)
        5'b10001,5'b10010,5'b01000,5'b10111,5'b11111,5'b10000: rt_legal = 1'b1;
        default:                                              rt_legal = 1'b0;
    endcase
    case (rd_w)
        5'b10001,5'b10010,5'b01000,5'b10111,5'b11111,5'b10000: rd_legal = 1'b1;
        default:                                              rd_legal = 1'b0;
    endcase
end

assign legalAddress        = rs_legal & rt_legal & rd_legal;
assign instruction_fail_w  = (out_valid_1) ? ~(legal & legalAddress) : 1'b0;
// Pipeline FF‑2
reg  [4:0] rd;
reg  [15:0] immd;
reg         Format;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        output_reg_2      <= 20'd0;
        out_valid_2       <= 1'b0;
        instruction_fail_1<= 1'b0;
        rd                <= 5'd0;
        immd              <= 16'd0;
        Format            <= 1'b0;
    end else begin
        output_reg_2      <= output_reg_1;
        out_valid_2       <= out_valid_1;
        instruction_fail_1<= instruction_fail_w;
        rd                <= rd_w;
        immd              <= immd_w;
        Format            <= Format_w;
    end
end
// Stage‑3 : ALU & write‑back
always @* begin
    if (!Format) begin              // I‑type : addi
        alu_result = x_rs + {{16{immd[15]}}, immd}; // sign‑extend
    end else begin                  // R‑type
        case (immd[5:0])            // funct field
            6'b100000: alu_result = x_rs + x_rt;               // add
            6'b100100: alu_result = x_rs & x_rt;               // and
            6'b100101: alu_result = x_rs | x_rt;               // or
            6'b100111: alu_result = ~(x_rs | x_rt);            // nor
            6'b000000: alu_result = x_rt << immd[10:6];        // sll
            6'b000010: alu_result = x_rt >> immd[10:6];        // srl
            default  : alu_result = 32'd0;
        endcase
    end
end
always @* begin
    {rf5_n, rf4_n, rf3_n, rf2_n, rf1_n, rf0_n} =
        {rf5,  rf4,  rf3,  rf2,  rf1,  rf0};      // default keep

    if (!instruction_fail_1) begin
        case (rd)
            5'b10001: rf5_n = alu_result;
            5'b10010: rf4_n = alu_result;
            5'b01000: rf3_n = alu_result;
            5'b10111: rf2_n = alu_result;
            5'b11111: rf1_n = alu_result;
            5'b10000: rf0_n = alu_result;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {rf5, rf4, rf3, rf2, rf1, rf0} <= 192'd0;
        output_reg_3      <= 20'd0;
        out_valid_3       <= 1'b0;
        instruction_fail_2<= 1'b0;
    end else begin
        {rf5, rf4, rf3, rf2, rf1, rf0} <=
            {rf5_n, rf4_n, rf3_n, rf2_n, rf1_n, rf0_n};
        output_reg_3      <= output_reg_2;
        out_valid_3       <= out_valid_2;
        instruction_fail_2<= instruction_fail_1;
    end
end
// Stage‑4 : output select
always @* begin
    if (instruction_fail_2) begin
        {out_1, out_2, out_3, out_4} = 128'd0;
    end else begin
        // 預設為 0
        {out_1, out_2, out_3, out_4} = 128'd0;
        case (output_reg_3[19:15])   // out_4
            5'b10001: out_4 = rf5;
            5'b10010: out_4 = rf4;
            5'b01000: out_4 = rf3;
            5'b10111: out_4 = rf2;
            5'b11111: out_4 = rf1;
            5'b10000: out_4 = rf0;
        endcase
        case (output_reg_3[14:10])   // out_3
            5'b10001: out_3 = rf5;
            5'b10010: out_3 = rf4;
            5'b01000: out_3 = rf3;
            5'b10111: out_3 = rf2;
            5'b11111: out_3 = rf1;
            5'b10000: out_3 = rf0;
        endcase
        case (output_reg_3[9:5])     // out_2
            5'b10001: out_2 = rf5;
            5'b10010: out_2 = rf4;
            5'b01000: out_2 = rf3;
            5'b10111: out_2 = rf2;
            5'b11111: out_2 = rf1;
            5'b10000: out_2 = rf0;
        endcase
        case (output_reg_3[4:0])     // out_1
            5'b10001: out_1 = rf5;
            5'b10010: out_1 = rf4;
            5'b01000: out_1 = rf3;
            5'b10111: out_1 = rf2;
            5'b11111: out_1 = rf1;
            5'b10000: out_1 = rf0;
        endcase
    end
end

// 最終 valid / fail
always @* begin
    out_valid        = out_valid_3;
    instruction_fail = instruction_fail_2;
end

endmodule
