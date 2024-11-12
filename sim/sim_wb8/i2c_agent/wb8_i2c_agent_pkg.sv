/* 
* File: i2c_agent_pkg.sv
* 
* This package encapsulates all components related to the I2C agent in our verification environment.
* It imports necessary UVM packages and includes files for I2C transactions, monitor, and responder.
* 
* Key Components:
* - i2c_trans: Defines the structure of I2C transactions
* - axil_i2c_monitor: Monitors I2C bus activity
* - i2c_responder: Simulates an I2C slave device
*
* COMPLIANCE ISSUES:
* - The package doesn't follow the UVM naming convention for packages (should end with '_pkg')
* - Consider using `uvm_object_utils_begin/end` macros in transaction objects for better consistency
* - Lack of parameterization might limit reusability with different I2C configurations (e.g., 10-bit addressing)
*/

`ifndef wb8_I2C_AGENT_PKG
`define wb8_I2C_AGENT_PKG

package wb8_i2c_agent_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
   // TODO: Add imports for any dependent packages

   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "i2c_trans.sv"
  `include "wb8_i2c_monitor.sv"
  // `include "i2c_responder.sv"

  // TODO: Consider adding i2c_config.sv for agent configuration
  // TODO: Add i2c_seq_lib.sv for common I2C sequences

endpackage

`endif