//------------------------------------------------------------------------------
// File: common_utils_pkg.sv
// Description: Common Package for I2C Bridge UVM Verification
//
// This package contains rest of the common components for I2C protocol
// verification that is master protocol agnostic.
//
// Components Included:
//	 - Master to I2C translator class (master_to_i2c_translator.sv)
//
// Dependencies:
//   - UVM Package
//	 - I2C transaction
//------------------------------------------------------------------------------

`ifndef COMMON_UTILS_PKG_SV
`define COMMON_UTILS_PKG_SV

package common_utils_pkg;

//--------------------------------------------------------------------------
// UVM Package Import and Macro Inclusion
//--------------------------------------------------------------------------

// Import UVM base package - required for all UVM components
import uvm_pkg::*;

// Include UVM macros for component automation
`include "uvm_macros.svh"

import common_i2c_pkg::i2c_transaction;

//--------------------------------------------------------------------------
// Component Hierarchy
//--------------------------------------------------------------------------

`include "master_to_i2c_translator.sv"

endpackage

`endif // COMMON_I2C_PKG_SV