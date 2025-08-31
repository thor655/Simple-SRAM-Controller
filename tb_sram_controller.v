/*
 * Module: tb_sram_controller
 * Description:
 * A simple, effective testbench for the sram_controller. It writes two
 * values to the SRAM model via the controller and then reads them back
 * to verify the data integrity. This is the stable, working version for
 * the SRAM-only project.
 */
`timescale 1ns/1ps

module tb_sram_controller;

    // Parameters
    localparam ADDR_WIDTH = 8;
    localparam DATA_WIDTH = 16;
    localparam CLK_PERIOD = 10;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg req_i;
    reg wr_en_i;
    reg [ADDR_WIDTH-1:0] addr_i;
    reg [DATA_WIDTH-1:0] wdata_i;
    wire ack_o;
    wire [DATA_WIDTH-1:0] rdata_o;

    // Wires to connect controller to model
    wire [ADDR_WIDTH-1:0] sram_addr;
    wire [DATA_WIDTH-1:0] sram_data;
    wire sram_ce, sram_we, sram_oe;
    
    // Instantiate the Controller (DUT)
    sram_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk), .rst_n(rst_n), .req_i(req_i), .wr_en_i(wr_en_i), .addr_i(addr_i),
        .wdata_i(wdata_i), .ack_o(ack_o), .rdata_o(rdata_o),
        .sram_addr_o(sram_addr), .sram_data_io(sram_data), .sram_ce_o(sram_ce),
        .sram_we_o(sram_we), .sram_oe_o(sram_oe)
    );

    // Instantiate the SRAM Model
    sram_model #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sram_inst (
        .clk(clk), .rst_n(rst_n), .sram_addr_i(sram_addr), .sram_data_io(sram_data),
        .sram_ce_i(sram_ce), .sram_we_i(sram_we), .sram_oe_i(sram_oe)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("sram_controller_waves.vcd");
        $dumpvars(0, tb_sram_controller);
        
        rst_n = 0;
        req_i = 0;
        #20;
        rst_n = 1;
        #40;

        $display("----------------------------------------");
        $display("Starting Simulation...");
        
        write_mem(8'h10, 16'hFACE);
        write_mem(8'hA5, 16'hBEEF);

        read_mem(8'h10, 16'hFACE);
        read_mem(8'hA5, 16'hBEEF);

        $display("----------------------------------------");
        $display("Simulation Finished.");
        $finish;
    end

    // Helper task for writing to memory
    task write_mem(input [ADDR_WIDTH-1:0] address, input [DATA_WIDTH-1:0] data);
        begin
            $display("[%0t] >> Writing 0x%h to address 0x%h", $time, data, address);
            @(posedge clk);
            req_i <= 1;
            wr_en_i <= 1;
            addr_i <= address;
            wdata_i <= data;
            @(posedge clk);
            while(!ack_o) @(posedge clk);
            req_i <= 0;
            $display("[%0t] << Controller acknowledged the write request.", $time);
        end
    endtask

    // Helper task for reading from memory
    task read_mem(input [ADDR_WIDTH-1:0] address, input [DATA_WIDTH-1:0] expected_data);
        begin
            $display("[%0t] >> Reading from address 0x%h", $time, address);
            @(posedge clk);
            req_i <= 1;
            wr_en_i <= 0;
            addr_i <= address;
            @(posedge clk);
            while(!ack_o) @(posedge clk);
            if (rdata_o == expected_data)
                $display("[%0t] << Read data: 0x%h (Correct!)", $time, rdata_o);
            else
                $display("[%0t] << Read data: 0x%h (ERROR! Expected: 0x%h)", $time, rdata_o, expected_data);
            req_i <= 0;
        end
    endtask

endmodule

