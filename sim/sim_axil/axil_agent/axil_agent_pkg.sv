`ifndef AXIL_AGENT_PKG
`define AXIL_AGENT_PKG

package axil_agent_pkg;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	// import dut_params_pkg::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
  `include "axil_seq_item.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"

endpackage

`endif


