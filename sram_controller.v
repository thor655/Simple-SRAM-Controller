/*
 * Module: sram_controller (Final, Robust CDC Version with FSM Race Fix)
 */
module sram_controller #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
    // Processor-side Interface (on proc_clk)
    input                       proc_clk,
    input                       req_i,
    input                       wr_en_i,
    input      [ADDR_WIDTH-1:0] addr_i,
    input      [DATA_WIDTH-1:0] wdata_i,
    output                      ack_o,

    // SRAM-side Interface (on sram_clk)
    input                       sram_clk,
    input                       rst_n,
    output reg [DATA_WIDTH-1:0] rdata_o,
    output reg [ADDR_WIDTH-1:0] sram_addr_o,
    inout      [DATA_WIDTH-1:0] sram_data_io,
    output reg                  sram_ce_o,
    output reg                  sram_we_o,
    output reg                  sram_oe_o
);

    // FINAL FIX: Added DECODE state to FSM
    localparam IDLE=4'b0001, DECODE=4'b0010, WRITE=4'b0100, READ_SETUP=4'b1000, READ_CAPTURE=4'b1001;
    
    reg [3:0] current_state, next_state;

    // Internal registers for latched command
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg wr_en_reg;
    reg ack_internal;

    // CDC: Synchronize the request signal ONLY
    reg req_s1, req_s2, req_s3;
    always @(posedge sram_clk or negedge rst_n) begin
        if (!rst_n) {req_s1, req_s2, req_s3} <= 3'b0;
        else        {req_s1, req_s2, req_s3} <= {req_i, req_s1, req_s2};
    end
    
    wire req_event = req_s2 & ~req_s3;

    // CDC: Synchronize the ack signal back
    reg ack_p1, ack_p2;
    always @(posedge proc_clk or negedge rst_n) begin
        if (!rst_n) {ack_p1, ack_p2} <= 2'b0;
        else        {ack_p1, ack_p2} <= {ack_internal, ack_p1};
    end
    assign ack_o = ack_p2;

    // Core FSM Sequential Logic (runs on sram_clk)
    always @(posedge sram_clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            rdata_o       <= 0;
        end else begin
            current_state <= next_state;
            if (current_state == IDLE && req_event) begin
                addr_reg  <= addr_i;
                wdata_reg <= wdata_i;
                wr_en_reg <= wr_en_i;
            end
            
            if (current_state == READ_CAPTURE) begin
                rdata_o <= sram_data_io;
            end
        end
    end

    // Core FSM Combinational Logic (runs on sram_clk)
    always @(*) begin
        next_state   = current_state;
        ack_internal = 1'b0;
        sram_addr_o  = addr_reg;
        sram_ce_o    = 1'b0;
        sram_we_o    = 1'b0;
        sram_oe_o    = 1'b0;
        
        case (current_state)
            IDLE: begin
                if (req_event) begin
                    next_state = DECODE;
                end
            end
            // FINAL FIX: Added DECODE state to safely check the latched command
            DECODE: begin
                next_state = wr_en_reg ? WRITE : READ_SETUP;
            end
            WRITE: begin
                sram_ce_o    = 1'b1;
                sram_we_o    = 1'b1;
                ack_internal = 1'b1;
                next_state   = IDLE;
            end
            READ_SETUP: begin
                sram_ce_o  = 1'b1;
                sram_oe_o  = 1'b1;
                next_state = READ_CAPTURE;
            end
            READ_CAPTURE: begin
                sram_ce_o    = 1'b1;
                sram_oe_o    = 1'b1;
                ack_internal = 1'b1;
                next_state   = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    assign sram_data_io = (current_state == WRITE) ? wdata_reg : {DATA_WIDTH{1'bz}};
endmodule