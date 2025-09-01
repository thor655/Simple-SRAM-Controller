/*
 * Module: tb_sram_controller (With Debug Probes)
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
    sram_controller #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) dut (.proc_clk(proc_clk), .sram_clk(sram_clk), .rst_n(rst_n), .req_i(req_i), .wr_en_i(wr_en_i), .addr_i(addr_i), .wdata_i(wdata_i), .ack_o(ack_o), .rdata_o(rdata_o), .sram_addr_o(sram_addr), .sram_data_io(sram_data), .sram_ce_o(sram_ce), .sram_we_o(sram_we), .sram_oe_o(sram_oe));
    sram_model #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) sram_inst (.clk(sram_clk), .rst_n(rst_n), .sram_addr_i(sram_addr), .sram_data_io(sram_data), .sram_ce_i(sram_ce), .sram_we_i(sram_we), .sram_oe_i(sram_oe));

    // Clocks and Test Sequence
    initial begin sram_clk = 0; forever #(SRAM_CLK_PERIOD/2) sram_clk = ~sram_clk; end
    initial begin proc_clk = 0; forever #(PROC_CLK_PERIOD/2) proc_clk = ~proc_clk; end
    initial begin
        $dumpfile("sram_controller_cdc_waves.vcd");
        $dumpvars(0, tb_sram_controller);
        rst_n = 0; req_i = 0; #20; rst_n = 1; #40;
        $display("----------------------------------------");
        $display("Starting CDC Simulation...");
        write_mem(8'h10, 16'hFACE);
        write_mem(8'hA5, 16'hBEEF);
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

    // Read task with debug statements
    task read_mem(input [ADDR_WIDTH-1:0] address, input [DATA_WIDTH-1:0] expected_data);
        begin
            $display("[%0t] >> Reading from address 0x%h", $time, address);
            @(posedge proc_clk);
            req_i <= 1; wr_en_i <= 0; addr_i <= address;
            
            // DEBUG: Show when the ack is received
            while(!ack_o) @(posedge proc_clk);
            $display("[%0t] TB-PROC-CLK: Ack received. Sampling data on next edge.", $time);
            
            req_i <= 0;
            @(posedge proc_clk);

            // DEBUG: Show what data is being sampled
            $display("[%0t] TB-PROC-CLK: Sampling rdata_o, value is %h", $time, rdata_o);
            if (rdata_o == expected_data)
                $display("[%0t] << Read data: 0x%h (Correct!)", $time, rdata_o);
            else
                $display("[%0t] << Read data: 0x%h (ERROR! Expected: 0x%h)", $time, rdata_o, expected_data);
        end
    endtask
endmodule