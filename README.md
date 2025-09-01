# Verilog Pipelined SRAM Controller with Clock Domain Crossing

This repository contains the source code for a high-throughput, parameterizable SRAM (Static Random-Access Memory) controller, written in Verilog. The design features a **two-stage pipeline** to increase performance and supports **Clock Domain Crossing (CDC)**, allowing it to safely interface between modules operating on different, asynchronous clocks.

The project includes the pipelined controller, a behavioral model of an SRAM chip, and a comprehensive testbench designed to verify the design's concurrency and CDC functionality. This project serves as a practical exercise in advanced digital logic design, demonstrating pipelining, FSMs, asynchronous interfaces, and hardware verification.

### Project Overview

The `sram_controller` acts as a high-performance bridge between a master device (like a CPU) running on a **processor clock** (`proc_clk`) and a physical SRAM chip running on its own **SRAM clock** (`sram_clk`).

The key architectural feature is a two-stage pipeline that decouples the process of accepting a command from executing it. This allows the controller to accept a new request while the previous one is still being processed, significantly increasing the command throughput. The controller uses robust synchronizers to safely handle the passing of control signals, preventing metastability and ensuring data integrity between the asynchronous domains.

### Features

* **Two-Stage Pipeline:** Decouples command acceptance (Stage 1) from command execution (Stage 2) to increase instruction throughput. It can accept a new request before the previous one is complete.
* **Clock Domain Crossing (CDC) Support:** Safely manages communication between two asynchronous clock domains (`proc_clk` and `sram_clk`).
* **Robust Handshake Protocol:** The pipeline stages use a valid/ready handshake, and the external interface uses a request/acknowledge protocol for reliable operation.
* **Parameterizable:** The controller's address and data widths can be easily configured, making it adaptable to different memory sizes.
* **Complete Test Environment:** Includes a behavioral SRAM model and a self-checking, dual-clock testbench that verifies correct pipelined operation across the asynchronous boundary.
* **Simulation Ready:** Designed and tested to work with open-source tools like Icarus Verilog and GTKWave.

### Project Structure

The repository contains three essential Verilog files:

1.  `sram_controller.v`
    * **Purpose:** This is the **Device Under Test (DUT)**. It contains the synthesizable logic for the pipelined memory controller, including the CDC synchronizers and the two-stage FSM.

2.  `sram_model.v`
    * **Purpose:** This is a **behavioral model** of a generic SRAM chip. It acts as a "stunt double" for a real memory chip during simulation and runs on the `sram_clk`.

3.  `tb_sram_controller.v`
    * **Purpose:** This is the **testbench**. It instantiates the controller and SRAM model, generates two asynchronous clocks, and runs a sequence of back-to-back requests to verify the pipeline's concurrency.

### How to Run the Simulation

To compile and run this project, you will need an open-source Verilog toolchain.

**Prerequisites:**

* **Icarus Verilog:** For compiling and simulating the design (`iverilog` and `vvp` commands).
* **GTKWave:** For viewing the resulting waveforms.

**Steps:**

1.  **Navigate into the project directory.**

2.  **Compile the Verilog files:**
    Open a terminal and run the following command. This will compile all three source files and create a simulation executable named `pipelined_sim`.
    ```sh
    iverilog -o pipelined_sim tb_sram_controller.v sram_controller.v sram_model.v
    ```

3.  **Run the simulation:**
    Execute the compiled file. You will see the testbench's log output confirming that the read/write tests have passed.
    ```sh
    vvp pipelined_sim
    ```

4.  **View the Waveforms:**
    The simulation will generate a file named `sram_controller_cdc_waves.vcd`. Open this file with GTKWave to visually inspect the signals.
    ```sh
    gtkwave sram_controller_cdc_waves.vcd
    ```
