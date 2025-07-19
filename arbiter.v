// this arbiter module operates as a finite state machine (FSM) that arbitrates access to the 
// slaves based on a fixed priority scheme and facilitates data transfer using a handshake 
// mechanism. It is synchronized with a clock signal and includes an asynchronous 
// active-low reset for initialization.

module arbiter (
    clk,
    rst_n,
    in_valid_1,
    in_valid_2,
    in_valid_3,
    data_in_1,
    data_in_2,
    data_in_3,
    ready_slave1,
    ready_slave2,
    valid_slave1,
    valid_slave2,
    addr_out,
    value_out,
    handshake_slave1,
    handshake_slave2
);

// Inputs
input clk;                    // 1-bit clock
input rst_n;                  // 1-bit asynchronous active-low reset
input in_valid_1;             // Valid signal from Master1
input in_valid_2;             // Valid signal from Master2
input in_valid_3;             // Valid signal from Master3
input [6:0] data_in_1;        // 7-bit data from Master1
input [6:0] data_in_2;        // 7-bit data from Master2
input [6:0] data_in_3;        // 7-bit data from Master3
input ready_slave1;           // Ready signal from slave1
input ready_slave2;           // Ready signal from slave2

// Outputs
output reg valid_slave1;      // Valid signal to slave1
output reg valid_slave2;      // Valid signal to slave2
output reg [2:0] addr_out;    // 3-bit address output
output reg [2:0] value_out;   // 3-bit value output
output reg handshake_slave1;  // Handshake signal for slave1 (high for 1 cycle)
output reg handshake_slave2;  // Handshake signal for slave2 (high for 1 cycle)

// State parameters
parameter S_idle      = 3'b000;  // Idle state
parameter S_master1   = 3'b001;  // Serving Master1
parameter S_master2   = 3'b010;  // Serving Master2
parameter S_master3   = 3'b011;  // Serving Master3
parameter S_handshake = 3'b100;  // Handshake state

// Registers
reg [2:0] state;              // Current state
reg [2:0] next_state;         // Next state
reg [6:0] selected_data;      // Latched data from the selected master

// Sequential logic for state and data latching
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= S_idle;
        selected_data <= 7'b0;
    end else begin
        state <= next_state;
        // Latch data when transitioning to a master state
        if (next_state == S_master1)
            selected_data <= data_in_1;
        else if (next_state == S_master2)
            selected_data <= data_in_2;
        else if (next_state == S_master3)
            selected_data <= data_in_3;
    end
end

// Combinational logic for next state
always @(*) begin
    case (state)
        S_idle: begin
            // Priority: Master1 > Master2 > Master3
            if (in_valid_1)
                next_state = S_master1;
            else if (in_valid_2)
                next_state = S_master2;
            else if (in_valid_3)
                next_state = S_master3;
            else
                next_state = S_idle;
        end
        S_master1: begin
            // Check handshake completion with the selected slave
            if ((selected_data[6] == 0 && ready_slave1) || (selected_data[6] == 1 && ready_slave2))
                next_state = S_handshake;
            else
                next_state = S_master1;
        end
        S_master2: begin
            if ((selected_data[6] == 0 && ready_slave1) || (selected_data[6] == 1 && ready_slave2))
                next_state = S_handshake;
            else
                next_state = S_master2;
        end
        S_master3: begin
            if ((selected_data[6] == 0 && ready_slave1) || (selected_data[6] == 1 && ready_slave2))
                next_state = S_handshake;
            else
                next_state = S_master3;
        end
        S_handshake: begin
            // After handshake, return to idle
            next_state = S_idle;
        end
        default: begin
            next_state = S_idle;
        end
    endcase
end
