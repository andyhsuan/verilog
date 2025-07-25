module vm (
    input clk, rst_n, in_coin_valid, in_rtn_coin,
    input in_item_valid,
    input [5:0] in_coin,
    input [5:0] in_item_price,
    input [2:0] in_buy_item,
    output reg [8:0] out_monitor,
    output reg out_valid,
    output reg [3:0] out_consumer,
    output reg [5:0] out_sell_num,

    // debug outputs for gtkwave
    output [5:0] debug_item1, debug_item2, debug_item3, debug_item4, debug_item5, debug_item6,
    output [2:0] debug_buy1, debug_buy2, debug_buy3, debug_buy4, debug_buy5, debug_buy6,
    output [2:0] debug_reg_array0, debug_reg_array1, debug_reg_array2, debug_reg_array3, debug_reg_array4, debug_reg_array5
);

    reg [2:0] cnt, cnt_2;
    reg [5:0] item [1:6];
    reg [2:0] buy [1:6];
    reg [2:0] reg_array [0:5];
    reg done;
    integer i;
    reg flag, flag2;

    // debug assign
    assign debug_item1 = item[1];
    assign debug_item2 = item[2];
    assign debug_item3 = item[3];
    assign debug_item4 = item[4];
    assign debug_item5 = item[5];
    assign debug_item6 = item[6];

    assign debug_buy1 = buy[1];
    assign debug_buy2 = buy[2];
    assign debug_buy3 = buy[3];
    assign debug_buy4 = buy[4];
    assign debug_buy5 = buy[5];
    assign debug_buy6 = buy[6];

    assign debug_reg_array0 = reg_array[0];
    assign debug_reg_array1 = reg_array[1];
    assign debug_reg_array2 = reg_array[2];
    assign debug_reg_array3 = reg_array[3];
    assign debug_reg_array4 = reg_array[4];
    assign debug_reg_array5 = reg_array[5];

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_monitor <= 0;
            out_valid <= 0;
            out_consumer <= 4'b0;
            out_sell_num <= 6'b0;
            cnt <= 3'b0;
            cnt_2 <= 3'b0;
            done <= 0;
            i <= 0;
            flag2 <= 0;
            for (i = 1; i <= 6; i = i + 1) begin
                item[i] <= 6'b0;
                buy[i] <= 3'b0;
            end
            for (i = 0; i < 6; i = i + 1)
                reg_array[i] <= 3'b0;
        end
        else begin
            if (in_item_valid && cnt < 6) begin
                item[cnt+1] <= in_item_price;
                cnt <= cnt + 1;
                out_sell_num <= 0;
                for (i = 0; i < 6; i = i + 1) begin
                    buy[i + 1] <= 0;
                end
            end
            else if (in_coin_valid) begin
                cnt <= 0;
                out_monitor <= out_monitor + in_coin;
            end
            else if (in_rtn_coin) begin
                reg_array[0] <= 3'b1;
                reg_array[1] <= out_monitor / 50;
                reg_array[2] <= (out_monitor % 50) / 20;
                reg_array[3] <= (out_monitor % 20) / 10;
                reg_array[4] <= (out_monitor % 10) / 5;
                reg_array[5] <= (out_monitor % 5) / 1;
                out_monitor <= 9'b0;
            end
            else if (in_buy_item != 0) begin
                reg_array[0] <= 3'b1;
                reg_array[1] <= (out_monitor - item[in_buy_item]) / 50;
                reg_array[2] <= ((out_monitor - item[in_buy_item]) % 50) / 20;
                reg_array[3] <= (((out_monitor - item[in_buy_item]) %50)%20) / 10;
                reg_array[4] <= ((((out_monitor - item[in_buy_item])%50)%20)%10) / 5;
                reg_array[5] <= (((((out_monitor - item[in_buy_item]) %50)%20)%10) %5) / 1;
                out_monitor <= 9'b0;
                buy[in_buy_item] <= buy[in_buy_item] + 1;
                flag <= 1;
                
            end
            else if (flag == 1) begin
                out_valid <= 1;
                flag <= 0;
                out_consumer <= reg_array[0];
                out_sell_num <= buy[1];
                
            end
            
            else if (out_valid && cnt_2 <= 4) begin
                out_consumer <= reg_array[cnt_2+1];
                cnt_2 <= cnt_2 + 1;
                out_sell_num <= buy[cnt_2 + 2];
                done <= 1;
            end
            else if (cnt_2 == 5) begin
                out_consumer <= 0;
                cnt_2 <= 0;
                out_valid <= 0;
                flag2 <= 1;
            
            end
            else if (flag2 == 1) begin
                for (i = 0; i < 6; i = i + 1) begin
                    reg_array[i] <= 0;
              
                         
                end
            end
        end
    end
endmodule