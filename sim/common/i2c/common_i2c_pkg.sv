//------------------------------------------------------------------------------
// File: common_i2c_pkg.sv
// Description: Common Package for I2C UVM Verification Slave Agent
//
// This package contains all the common components needed for I2C protocol
// verification. It serves as a central location for all I2C-related verification
// components, ensuring consistent usage across the testbench hierarchy.
//
// Components Included:
//   - I2C Transaction Class (i2c_transaction.sv)
//   - I2C Slave Driver Class (i2c_driver.sv)
//   - I2C Protocol Monitor Class (i2c_monitor.sv)
//	 - I2C Response Sequence Class (i2c_response_seq.sv)
//
// Dependencies:
//   - UVM Package
//   - Interface file i2c_interface.sv must be compiled before this package
//
// Usage:
//   - Import this package in your testbench/test files
//   - All I2C verification components will be available
//------------------------------------------------------------------------------

`ifndef COMMON_I2C_PKG_SV
`define COMMON_I2C_PKG_SV

package common_i2c_pkg;

//--------------------------------------------------------------------------
// UVM Package Import and Macro Inclusion
//--------------------------------------------------------------------------

// Import UVM base package - required for all UVM components
import uvm_pkg::*;

// Include UVM macros for component automation
`include "uvm_macros.svh"

//--------------------------------------------------------------------------
// Component Hierarchy
//--------------------------------------------------------------------------

// Include files in dependency order - base classes first

// Basic transaction object - foundation for stimulus and monitoring
`include "i2c_transaction.sv"

// Core verification components
`include "i2c_driver.sv"      // Drives I2C slave protocol
`include "i2c_monitor.sv"   // Monitors I2C bus activity
`include "i2c_agent.sv" // Encapsulate driver and monitor

//--------------------------------------------------------------------------
// Future Extensions
//--------------------------------------------------------------------------
/*
	* Planned/Suggested additions:
	* - I2C Configuration Object
	* - I2C Scoreboard
	* - Protocol Coverage Collection
	* - Reference Model
	*/

endpackage

`endif // COMMON_I2C_PKG_SV