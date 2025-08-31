/*
 * Module: sram_controller
 * Description:
 * A robust, synchronous SRAM controller. It uses a multi-state Finite State
 * Machine (FSM) to handle read and write requests, ensuring correct timing
 * and stable data output. This is the fully debugged, working version.
 */
module sram_controller #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
    // Processor-side Interface
    input                       clk,
    input                       rst_n,
    input                       req_i,
    input                       wr_en_i,
    input      [ADDR_WIDTH-1:0] addr_i,
    input      [DATA_WIDTH-1:0] wdata_i,
    output reg                  ack_o,
    output reg [DATA_WIDTH-1:0] rdata_o,

    // SRAM-side Interface
    output reg [ADDR_WIDTH-1:0] sram_addr_o,
    inout      [DATA_WIDTH-1:0] sram_data_io,
    output reg                  sram_ce_o,
    output reg                  sram_we_o,
    output reg                  sram_oe_o
);

    // FSM State Definitions
    localparam IDLE           = 3'b001;
    localparam WRITE          = 3'b010;
    localparam READ_SETUP     = 3'b011;
    localparam READ_CAPTURE   = 3'b100;
    localparam READ_ACK       = 3'b101;
    
    reg [2:0] current_state, next_state;

    // Internal registers to hold request info
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;

    // Sequential Logic Block (State transitions and data latching)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            rdata_o <= 0;
        end else begin
            current_state <= next_state;
            
            // Latch inputs when a new request arrives
            if (current_state == IDLE && req_i) begin
                addr_reg <= addr_i;
                wdata_reg <= wdata_i;
            end

            // Capture data from SRAM at the end of the CAPTURE state
            if (current_state == READ_CAPTURE) begin
                rdata_o <= sram_data_io;
            end
        end
    end

    // Combinational Logic Block (State-based outputs and next state logic)
    always @(*) begin
        // Default values for signals
        next_state   = current_state;
        ack_o        = 1'b0;
        sram_addr_o  = addr_reg;
        sram_ce_o    = 1'b0;
        sram_we_o    = 1'b0;
        sram_oe_o    = 1'b0;
        
        case (current_state)
            IDLE: begin
                if (req_i) begin
                    if (wr_en_i) begin
                        next_state = WRITE;
                    end else begin
                        next_state = READ_SETUP;
                    end
                end
            end
            
            WRITE: begin
                sram_ce_o = 1'b1;
                sram_we_o = 1'b1;
                ack_o = 1'b1;
                next_state = IDLE;
            end
            
            READ_SETUP: begin
                sram_ce_o = 1'b1;
                sram_oe_o = 1'b1;
                next_state = READ_CAPTURE;
            end

            READ_CAPTURE: begin
                sram_ce_o = 1'b1;
                sram_oe_o = 1'b1;
                next_state = READ_ACK;
            end
            
            READ_ACK: begin
                ack_o = 1'b1;
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Drive data to SRAM only during a write operation
    assign sram_data_io = (current_state == WRITE) ? wdata_reg : {DATA_WIDTH{1'bz}};

endmodule

