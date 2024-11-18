/*
* File: axil_agent_pkg.sv
*
* This package encapsulates all components related to the AXI-Lite agent in the verification environment.
* It imports necessary UVM packages and includes files for AXI-Lite specific components.
*
* Components included:
* - axil_seq_item.sv: Defines the transaction item for AXI-Lite operations
* - axil_driver.sv: Implements the driver for sending AXI-Lite transactions
* - axil_monitor.sv: Monitors and records AXI-Lite interface activity
*
* TODO:
* - Consider adding a separate sequencer class if custom sequencer functionality is needed
* - Implement a configuration object for the AXI-Lite agent to allow for runtime configuration
* - Add assertions or checks within the monitor to verify AXI-Lite protocol compliance
*
* Notes on current implementation:
* - The package structure follows UVM methodology, but could be improved:
*   - Consider using `uvm_object_utils_begin/end` macros for more robust factory registration
*   - Implement a proper build_phase in the agent to construct its sub-components
* - The current implementation lacks error handling and reporting mechanisms
* - Coverage collection should be added to ensure all aspects of the AXI-Lite protocol are exercised
* - The agent should ideally be parameterized to support different AXI-Lite configurations (data width, address width)
*
* Best practice violations:
* - Naming convention for files and classes could be more consistent (e.g., axil_driver vs axi_lite_driver)
* - Missing documentation for individual methods and classes within the included files
* - Lack of clear hierarchy in the agent structure (missing top-level agent class)
*
* Performance considerations:
* - Evaluate the need for a separate analysis port in the monitor for performance-critical simulations
*
* Compatibility:
* - Ensure compatibility with both UVM 1.1 and 1.2 by using appropriate compile guards
*/
`ifndef AXIL_AGENT_PKG
`define AXIL_AGENT_PKG

package axil_agent_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
   import i2c_master_axil_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "axil_seq_item.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"

   // TODO: Include additional files like sequencer, config, etc.
endpackage

`endif


