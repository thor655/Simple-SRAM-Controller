# Verilog SRAM Memory Controller

This repository contains the source code for a simple, robust, and parameterizable SRAM (Static Random-Access Memory) controller, written in Verilog. The project includes the controller itself, a behavioral model of an SRAM chip for simulation, and a comprehensive testbench to verify the design's functionality.

This project serves as a foundational exercise in digital logic design, demonstrating the principles of finite state machines (FSMs), synchronous memory interfacing, and hardware verification.

### Project Overview

The `sram_controller` acts as a bridge between a master device (like a CPU) and a physical SRAM chip. It translates simple read/write requests from the master into the precise, timed sequence of control signals that the SRAM requires to operate.

The core of the controller is a multi-state FSM that safely handles the timing for read and write operations, preventing common hardware issues like bus contention and data corruption.

### Features

* **Synchronous Design:** All operations are synchronized to a master clock.
* **Parameterizable:** The controller's address and data widths can be easily configured by changing top-level parameters, making it adaptable to different memory sizes.
* **Robust FSM:** A 5-state machine (`IDLE`, `WRITE`, `READ_SETUP`, `READ_CAPTURE`, `READ_ACK`) ensures clean and reliable timing for all memory accesses.
* **Complete Test Environment:** Includes a behavioral SRAM model and a self-checking testbench that verifies both write and read operations.
* **Simulation Ready:** Designed and tested to work with open-source tools like Icarus Verilog and GTKWave.

### Project Structure

The repository contains three essential Verilog files:

1.  `sram_controller.v`
    * **Purpose:** This is the **Device Under Test (DUT)**. It contains the actual synthesizable logic for the memory controller. Its FSM translates high-level requests into low-level SRAM control signals.

2.  `sram_model.v`
    * **Purpose:** This is a **behavioral model** of a generic SRAM chip. It acts as a "stunt double" for a real memory chip during simulation, allowing the controller to be tested. It stores data in an internal array and responds to the controller's signals. This file is for simulation only and is not part of the final hardware design.

3.  `tb_sram_controller.v`
    * **Purpose:** This is the **testbench**. It instantiates both the controller and the SRAM model, connecting them together. It then generates the clock and reset signals and runs a scripted sequence of write and read operations to verify that the controller works correctly. The testbench reports its success or failure to the console.

### How to Run the Simulation

To compile and run this project, you will need an open-source Verilog toolchain.

**Prerequisites:**

* **Icarus Verilog:** For compiling and simulating the design. (`iverilog` and `vvp` commands)
* **GTKWave:** For viewing the resulting waveforms.

**Steps:**

1.  **Clone the repository and navigate into the directory.**

2.  **Compile the Verilog files:**
    Open a terminal in the project directory and run the following command. This will compile all source files and create a simulation executable named `sram_sim`.
    ```
    iverilog -o sram_sim tb_sram_controller.v sram_controller.v sram_model.v
    ```

3.  **Run the simulation:**
    Execute the compiled file. You will see the testbench's log output in your terminal, confirming that the read/write tests have passed.
    ```
    vvp sram_sim
    ```

4.  **View the Waveforms:**
    The simulation will generate a file named `sram_controller_waves.vcd`. Open this file with GTKWave to visually inspect the signals and the FSM's behavior.
    ```
    gtkwave sram_controller_waves.vcd
    ```
