# Verilog SRAM Memory Controller with Clock Domain Crossing

This repository contains the source code for a robust and parameterizable SRAM (Static Random-Access Memory) controller, written in Verilog. The project has been enhanced to support **Clock Domain Crossing (CDC)**, allowing it to safely interface between modules operating on different, asynchronous clocks.

The project includes the dual-clock controller, a behavioral model of an SRAM chip, and a comprehensive testbench designed to verify the design's functionality in a dual-clock environment.

This project serves as a practical exercise in advanced digital logic design, demonstrating the principles of finite state machines (FSMs), asynchronous interfaces, CDC synchronization techniques, and hardware verification.

### Project Overview

The `sram_controller` acts as a bridge between a master device (like a CPU) running on a **processor clock** (`proc_clk`) and a physical SRAM chip running on its own **SRAM clock** (`sram_clk`). It translates simple read/write requests from the master's clock domain into the precise, timed sequence of control signals required by the SRAM in its own clock domain.

The controller uses 2-flop synchronizers and a robust FSM to safely handle the passing of control signals, preventing metastability and ensuring data integrity between the asynchronous domains.

### Features

* **Clock Domain Crossing (CDC) Support:** The controller safely manages communication between two asynchronous clock domains (`proc_clk` and `sram_clk`).
* **2-Flop Synchronizers:** Implements industry-standard synchronizers to prevent metastability on control signals passed between clock domains.
* **Robust Handshake Protocol:** The interface uses a request/acknowledge handshake that is essential for reliable operation in a CDC design.
* **Parameterizable:** The controller's address and data widths can be easily configured, making it adaptable to different memory sizes.
* **Race-Free FSM:** An optimized state machine (`IDLE`, `DECODE`, `WRITE`, `READ_SETUP`, `READ_CAPTURE`) includes a `DECODE` state to prevent internal race conditions when latching commands.
* **Complete Test Environment:** Includes a behavioral SRAM model and a self-checking, dual-clock testbench that verifies correct operation across the asynchronous boundary.
* **Simulation Ready:** Designed and tested to work with open-source tools like Icarus Verilog and GTKWave.

### Project Structure

The repository contains three essential Verilog files:

1.  `sram_controller.v`
    * **Purpose:** This is the **Device Under Test (DUT)**. It contains the synthesizable logic for the memory controller, including the dual-clock interface, CDC synchronizers, and the core FSM.

2.  `sram_model.v`
    * **Purpose:** This is a **behavioral model** of a generic SRAM chip. It acts as a "stunt double" for a real memory chip during simulation. It runs on the `sram_clk`. This file is for simulation only.

3.  `tb_sram_controller.v`
    * **Purpose:** This is the **testbench**. It instantiates both the controller and the SRAM model. It generates two asynchronous clocks (`proc_clk` and `sram_clk`) and runs a scripted sequence of requests to verify that the CDC logic works correctly.

### How to Run the Simulation

To compile and run this project, you will need an open-source Verilog toolchain.

**Prerequisites:**

* **Icarus Verilog:** For compiling and simulating the design. (`iverilog` and `vvp` commands)
* **GTKWave:** For viewing the resulting waveforms.

**Steps:**

1.  **Clone the repository and navigate into the directory.**

2.  **Compile the Verilog files:**
    Open a terminal in the project directory and run the following command. This will compile all source files and create a simulation executable named `sram_cdc_sim`.
    ```
    iverilog -o sram_cdc_sim tb_sram_controller.v sram_controller.v sram_model.v
    ```

3.  **Run the simulation:**
    Execute the compiled file. You will see the testbench's log output in your terminal, confirming that the read/write tests have passed.
    ```
    vvp sram_cdc_sim
    ```

4.  **View the Waveforms:**
    The simulation will generate a file named `sram_controller_cdc_waves.vcd`. Open this file with GTKWave to visually inspect the signals. Pay close attention to the two different clocks and how the `req_i` and `ack_o` signals cross between them.
    ```
    gtkwave sram_controller_cdc_waves.vcd
    ```
