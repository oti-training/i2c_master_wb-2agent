/* 
* File: axil_seq_list.sv
*
* This file defines a package containing various AXI-Lite and I2C sequences used in the testbench.
* 
* Key Features:
* - Imports necessary packages and includes required files for sequence definitions.
* - Defines a package 'axil_seq_list' which encapsulates all the sequences.
* 
* Sequences included:
* - api_single_rw_seq: For single register read/write operations
* - memory_slave_seq: Simulates interactions with an I2C slave
* - config_seq: Configures the DUT via register writes
* - write_read_seq: Performs a write followed by a read I2C transaction through the DUT
*
* TODO:
* - Consider splitting sequences into separate files for better maintainability
* - Add more comprehensive documentation for each sequence
* - Implement parameter randomization for more diverse test scenarios
*
* NOTES:
* - The current implementation mixes different types of sequences in a single package,
*   which may not adhere to best practices for larger projects.
* - Consider implementing a base sequence class to promote code reuse among sequences.
* - The package structure could be improved to separate AXI-Lite and I2C specific sequences.
*/
`ifndef AXIL_SEQ_LIST
`define AXIL_SEQ_LIST

package axil_seq_list;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	import i2c_master_axil_pkg::*;
	import bridge_env_pkg::*;
	import axil_agent_pkg::axil_seq_item;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
   // TODO: Group related sequences and consider using separate files for complex sequences
	`include "api_single_rw_seq.sv"

	`include "memory_slave_seq.sv"

	`include "config_seq.sv"
	`include "write_read_seq.sv"

   // TODO: Add factory registration for all sequences if not done in individual files
endpackage

`endif


