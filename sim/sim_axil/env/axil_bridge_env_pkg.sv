/*
* File: axil_bridge_env_pkg.sv
* 
* This package encapsulates the components and definitions required for the 
* AXI-Lite to I2C Master Bridge verification environment.
* 
* Key Features:
* - Imports necessary UVM packages and macros.
* - Imports custom packages for I2C master, AXI-Lite, and I2C agents.
* - Includes key environment components: scoreboard, coverage, and the main environment class.
* 
* The axil_bridge_env_pkg serves as a central point for organizing all the components
* needed in the verification environment. By grouping these elements together,
* it simplifies the top-level testbench and ensures consistent use of components
* across different tests and sequences.
* 
* Components included:
* 1. Scoreboard: For checking the correctness of DUT operations.
* 2. Coverage: To track the functional coverage of the verification process.
* 3. Bridge Environment: The main environment class that instantiates and connects all sub-components.
* 
* Usage:
* This package should be imported in the top-level testbench and in any files
* that need access to the verification environment components.
*/
`ifndef AXIL_BRIDGE_ENV_PKG
`define AXIL_BRIDGE_ENV_PKG

package axil_bridge_env_pkg;
   
  // Import UVM package and include macros
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import required custom packages
	import i2c_master_axil_pkg::*;
	import i2c_agent_pkg::*;
	import common_i2c_pkg::i2c_agent;
	import axil_agent_pkg::*;

  // Include environment components
  `include "axil_scoreboard.sv"
  `include "axil_coverage.sv"
  `include "axil_bridge_env.sv"

endpackage

`endif


