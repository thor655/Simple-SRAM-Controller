/*

 * Module: tb_sram_controller (Final, Pipelined Test Version)

 * Description:

 * A testbench for the sram_controller. This version includes a corrected

 * test case that issues wide, back-to-back request pulses to verify 

 * the pipeline's functionality and avoid CDC pulse-width issues.

 */

`timescale 1ns/1ps



module tb_sram_controller;



  // Parameters and signals

  localparam ADDR_WIDTH = 8;

  localparam DATA_WIDTH = 16;

  localparam SRAM_CLK_PERIOD = 10;

  localparam PROC_CLK_PERIOD = 7;

  reg sram_clk, proc_clk, rst_n, req_i, wr_en_i;

  reg [ADDR_WIDTH-1:0] addr_i;

  reg [DATA_WIDTH-1:0] wdata_i;

  wire ack_o;

  wire [DATA_WIDTH-1:0] rdata_o;

  wire [ADDR_WIDTH-1:0] sram_addr;

  wire [DATA_WIDTH-1:0] sram_data;

  wire sram_ce, sram_we, sram_oe;



  // Instantiations

  sram_controller #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (

    .proc_clk(proc_clk), .sram_clk(sram_clk), .rst_n(rst_n),

    .req_i(req_i), .wr_en_i(wr_en_i), .addr_i(addr_i), .wdata_i(wdata_i),

    .ack_o(ack_o), .rdata_o(rdata_o), .sram_addr_o(sram_addr),

    .sram_data_io(sram_data), .sram_ce_o(sram_ce), .sram_we_o(sram_we),

    .sram_oe_o(sram_oe)

  );



  sram_model #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) sram_inst (

    .clk(sram_clk), .rst_n(rst_n), .sram_addr_i(sram_addr),

    .sram_data_io(sram_data), .sram_ce_i(sram_ce), .sram_we_i(sram_we),

    .sram_oe_i(sram_oe)

  );



  // Clocks

  initial begin

    sram_clk = 0;

    forever #(SRAM_CLK_PERIOD/2) sram_clk = ~sram_clk;

  end



  initial begin

    proc_clk = 0;

    forever #(PROC_CLK_PERIOD/2) proc_clk = ~proc_clk;

  end



  // Test Sequence (Corrected for Pulse Width)

  initial begin

    $dumpfile("sram_controller_cdc_waves.vcd");

    $dumpvars(0, tb_sram_controller);

    rst_n = 0;

    req_i = 0;

    #20;

    rst_n = 1;

    #40;



    $display("----------------------------------------");

    $display("Starting FINAL Pipelined Simulation (Wide Pulse)...");



    // Step 1: Pre-load memory

    write_mem(8'hA5, 16'hBEEF);

     

    // Step 2: Issue two separate, wide requests

    $display("[%0t] >> Issuing a wide Write pulse then a wide Read pulse.", $time);

     

    // Issue first request (Write) - hold req_i for 3 proc_clk cycles

    @(posedge proc_clk);

    req_i <= 1; wr_en_i <= 1; addr_i <= 8'h10; wdata_i <= 16'hFACE;

    @(posedge proc_clk);

    @(posedge proc_clk);

    @(posedge proc_clk);

    req_i <= 0;

     

    // Add a small gap between requests for clarity in the waveform

    @(posedge proc_clk);



    // Issue second request (Read) - hold req_i for 3 proc_clk cycles

    @(posedge proc_clk);

    req_i <= 1; wr_en_i <= 0; addr_i <= 8'hA5;

    @(posedge proc_clk);

    @(posedge proc_clk);

    @(posedge proc_clk);

    req_i <= 0;

     

    // Wait for pipelined operations to finish

    #200;



    // Step 3: Verify the results

    $display("[%0t] >> Verifying the results of the pipelined sequence.", $time);

    read_mem(8'h10, 16'hFACE);

    read_mem(8'hA5, 16'hBEEF);

     

    $display("----------------------------------------");

    $display("Simulation Finished.");

    $finish;

  end



  // Write task

  task write_mem(input [ADDR_WIDTH-1:0] address, input [DATA_WIDTH-1:0] data);

    begin

      $display("[%0t] >> Writing 0x%h to address 0x%h", $time, data, address);

      @(posedge proc_clk);

      req_i <= 1; wr_en_i <= 1; addr_i <= address; wdata_i <= data;

      while(!ack_o) @(posedge proc_clk);

      req_i <= 0;

      $display("[%0t] << Controller acknowledged the write request.", $time);

      @(posedge proc_clk);

    end

  endtask



  // Read task

  task read_mem(input [ADDR_WIDTH-1:0] address, input [DATA_WIDTH-1:0] expected_data);

    begin

      $display("[%0t] >> Reading from address 0x%h", $time, address);

      @(posedge proc_clk);

      req_i <= 1; wr_en_i <= 0; addr_i <= address;

      while(!ack_o) @(posedge proc_clk);

      req_i <= 0;

      @(posedge proc_clk);

      if (rdata_o == expected_data)

        $display("[%0t] << Read data: 0x%h (Correct!)", $time, rdata_o);

      else

        $display("[%0t] << Read data: 0x%h (ERROR! Expected: 0x%h)", $time, rdata_o, expected_data);

    end

  endtask



endmodule