/*

 * Module: sram_model

 * Description:

 * A behavioral model for a simple synchronous SRAM chip. It includes a reset

 * and has correctly named ports to interface with the controller and testbench.

 * This is the stable, working version for the SRAM-only project.

 */

module sram_model #(

  parameter DATA_WIDTH = 16,

  parameter ADDR_WIDTH = 8

)(

  input            clk,

  input            rst_n,

  inout [DATA_WIDTH-1:0]   sram_data_io,

  input [ADDR_WIDTH-1:0]   sram_addr_i,

  input            sram_ce_i,

  input            sram_we_i,

  input            sram_oe_i

);



  // Internal memory array

  reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

   

  // On the positive clock edge, perform writes

  always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

      // On reset, do nothing to the memory contents.

    end else begin

      if (sram_ce_i && sram_we_i && !sram_oe_i) begin

        memory[sram_addr_i] <= sram_data_io;

      end

    end

  end



  // Combinational logic to drive the data bus during a read

  assign sram_data_io = (sram_ce_i && !sram_we_i && sram_oe_i) ? memory[sram_addr_i] : {DATA_WIDTH{1'bz}};



endmodule

