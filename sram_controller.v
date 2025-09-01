/*

 * Module: sram_controller (Pipelined Version)

 * Description:

 * A two-stage pipelined SRAM controller to improve throughput.

 * Stage 1 (Command): Latches incoming requests.

 * Stage 2 (Execution): Executes the SRAM read/write operation.

 * A valid/ready handshake connects the two stages.

 */

module sram_controller #(

  parameter ADDR_WIDTH = 8,

  parameter DATA_WIDTH = 16

)(

  // Processor-side Interface (on proc_clk)

  input            proc_clk,

  input            req_i,

  input            wr_en_i,

  input   [ADDR_WIDTH-1:0] addr_i,

  input   [DATA_WIDTH-1:0] wdata_i,

  output           ack_o,



  // SRAM-side Interface (on sram_clk)

  input            sram_clk,

  input            rst_n,

  output reg [DATA_WIDTH-1:0] rdata_o,

  output   [ADDR_WIDTH-1:0] sram_addr_o, // Now driven by pipeline reg

  inout   [DATA_WIDTH-1:0] sram_data_io,

  output reg         sram_ce_o,

  output reg         sram_we_o,

  output reg         sram_oe_o

);



  // FSM states for the Execution Stage (Stage 2)

  localparam EXEC_IDLE=4'b0001, EXEC_DECODE=4'b0010, EXEC_WRITE=4'b0100, EXEC_READ_SETUP=4'b1000, EXEC_READ_CAPTURE=4'b1001;

  reg [3:0] exec_current_state, exec_next_state;



  // Internal register for acknowledgement

  reg ack_internal;



  // --- CDC Logic (Unchanged) ---

  // Synchronize the request signal (proc_clk -> sram_clk)

  reg req_s1, req_s2, req_s3;

  always @(posedge sram_clk or negedge rst_n) begin

    if (!rst_n) {req_s1, req_s2, req_s3} <= 3'b0;

    else    {req_s1, req_s2, req_s3} <= {req_i, req_s1, req_s2};

  end

  wire req_event = req_s2 & ~req_s3;



  // Synchronize the ack signal back (sram_clk -> proc_clk)

  reg ack_p1, ack_p2;

  always @(posedge proc_clk or negedge rst_n) begin

    if (!rst_n) {ack_p1, ack_p2} <= 2'b0;

    else    {ack_p1, ack_p2} <= {ack_internal, ack_p1};

  end

  assign ack_o = ack_p2;



  // --- Pipeline Handshake and Registers ---

  // Pipeline Register between Stage 1 and Stage 2

  reg cmd_valid_reg;

  reg [ADDR_WIDTH-1:0] cmd_addr_reg;

  reg [DATA_WIDTH-1:0] cmd_wdata_reg;

  reg cmd_wr_en_reg;



  // Handshake Control Signals

  wire exec_ready; // Is the Execution Stage ready for a new command?

  wire cmd_fire;  // Signal to transfer command from Stage 1 to Stage 2



  // --- Stage 1: Command Stage ---

  // Latches a new request from the processor domain.

  always @(posedge sram_clk or negedge rst_n) begin

    if (!rst_n) begin

      cmd_valid_reg <= 1'b0;

    end else begin

      // If Stage 2 accepts the command, the pipeline register becomes free

      if (cmd_fire) begin

        cmd_valid_reg <= 1'b0;

      end

      // A new request arrives, latch it if the pipeline register is free.

      // If not free, the request is effectively stalled (req_event will be ignored

      // in subsequent cycles until the pipeline is free).

      if (req_event && !cmd_valid_reg) begin

        cmd_addr_reg <= addr_i;

        cmd_wdata_reg <= wdata_i;

        cmd_wr_en_reg <= wr_en_i;

        cmd_valid_reg <= 1'b1;

      end

    end

  end

   

  // --- Stage 2: Execution Stage ---

  // Executes the SRAM transaction.

  assign exec_ready = (exec_current_state == EXEC_IDLE);

  assign cmd_fire = cmd_valid_reg && exec_ready;



  // Execution FSM Sequential Logic (runs on sram_clk)

  always @(posedge sram_clk or negedge rst_n) begin

    if (!rst_n) begin

      exec_current_state <= EXEC_IDLE;

      rdata_o      <= 0;

    end else begin

      exec_current_state <= exec_next_state;

      if (exec_current_state == EXEC_READ_CAPTURE) begin

        rdata_o <= sram_data_io;

      end

    end

  end



  // Execution FSM Combinational Logic (runs on sram_clk)

  always @(*) begin

    exec_next_state = exec_current_state;

    ack_internal  = 1'b0;

    sram_ce_o    = 1'b0;

    sram_we_o    = 1'b0;

    sram_oe_o    = 1'b0;



    case (exec_current_state)

      EXEC_IDLE: begin

        if (cmd_fire) begin // Start a new transaction

          exec_next_state = cmd_wr_en_reg ? EXEC_WRITE : EXEC_READ_SETUP;

        end

      end

      EXEC_WRITE: begin

        sram_ce_o  = 1'b1;

        sram_we_o  = 1'b1;

        ack_internal = 1'b1;

        exec_next_state  = EXEC_IDLE; // Done, go back to idle

      end

      EXEC_READ_SETUP: begin

        sram_ce_o = 1'b1;

        sram_oe_o = 1'b1;

        exec_next_state = EXEC_READ_CAPTURE;

      end

      EXEC_READ_CAPTURE: begin

        sram_ce_o  = 1'b1;

        sram_oe_o  = 1'b1;

        ack_internal = 1'b1;

        exec_next_state  = EXEC_IDLE; // Done, go back to idle

      end

      default: exec_next_state = EXEC_IDLE;

    endcase

  end



  // --- Data Path Assignments ---

  assign sram_addr_o = cmd_addr_reg;

  assign sram_data_io = (exec_current_state == EXEC_WRITE) ? cmd_wdata_reg : {DATA_WIDTH{1'bz}};



endmodule