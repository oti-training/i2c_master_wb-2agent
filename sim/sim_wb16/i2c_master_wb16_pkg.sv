/*
* File: i2c_master_wb16_pkg.sv
* 
* This file defines the i2c_master_wb16_pkg package, which serves as a central package for the I2C Master with WB16 interface verification environment.
* 
* Key Features:
*   - Imports the i2c_master_wb16_pkg, which serves as a central package for the I2C Master with WB16 interface verification environment.
*   - Includes essential definitions from register_defines.svh, making them available to all components that import this package.
*   - Acts as a hub for importing other necessary packages (though currently commented out).
*   - Provides a centralized location for adding project-wide typedefs, parameters, or other shared declarations.
* 
* Usage:
* This package should be imported in all major components of the verification environment to ensure consistent access to shared definition and types.
* 
* Note: The commented-out import suggest room for expansion as the project grows, allowing for easy integration of additional packages.
*/
`ifndef I2C_MASTER_WB16_PKG
`define I2C_MASTER_WB16_PKG

package i2c_master_wb16_pkg;
   
   // Import UVM package and include UVM macros
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   // Placeholder for importing additional packages
   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////

   // Include files containing shared definitions
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "wb16_register_defines.svh"

   // This space can be used for additional package-wide declarations
   // such as typedefs, parameters, or constants that are used across
   // multiple components in the verification environment.

endpackage

`endif


