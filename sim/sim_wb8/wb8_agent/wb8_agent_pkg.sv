/*
* File: wb8_agent_pkg.sv
*
* This package encapsulates all components related to the WB8 agent in the verification environment.
* It imports necessary UVM packages and includes files for WB8 specific components.
*
* Components included:
* - wb8_seq_item.sv: Defines the transaction item for WB8 operations
* - wb8_driver.sv: Implements the driver for sending WB8 transactions
* - wb8_monitor.sv: Monitors and records WB8 interface activity
*
* TODO:
* - Consider adding a separate sequencer class if custom sequencer functionality is needed
* - Implement a configuration object for the WB8 agent to allow for runtime configuration
* - Add assertions or checks within the monitor to verify WB8 protocol compliance
*
* Notes on current implementation:
* - The package structure follows UVM methodology, but could be improved:
*   - Consider using `uvm_object_utils_begin/end` macros for more robust factory registration
*   - Implement a proper build_phase in the agent to construct its sub-components
* - The current implementation lacks error handling and reporting mechanisms
* - Coverage collection should be added to ensure all aspects of the WB8 protocol are exercised
* - The agent should ideally be parameterized to support different WB8 configurations (data width, address width)
*
* Best practice violations:
* - Naming convention for files and classes could be more consistent (e.g., wb8_driver vs axi_lite_driver)
* - Missing documentation for individual methods and classes within the included files
* - Lack of clear hierarchy in the agent structure (missing top-level agent class)
*
* Performance considerations:
* - Evaluate the need for a separate analysis port in the monitor for performance-critical simulations
*
* Compatibility:
* - Ensure compatibility with both UVM 1.1 and 1.2 by using appropriate compile guards
*/
`ifndef WB8_AGENT_PKG
`define WB8_AGENT_PKG

package wb8_agent_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
   import i2c_master_wb8_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "wb8_seq_item.sv"
  `include "wb8_driver.sv"
  `include "wb8_monitor.sv"

   // TODO: Include additional files like sequencer, config, etc.
endpackage

`endif


