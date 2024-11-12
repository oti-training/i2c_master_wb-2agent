/* 
* File: wb8_seq_list.sv
*
* This file defines a package containing various WB8 and I2C sequences used in the testbench.
* 
* Key Features:
* - Imports necessary packages and includes required files for sequence definitions.
* - Defines a package 'wb8_seq_list' which encapsulates all the sequences.
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
* - The package structure could be improved to separate WB8 and I2C specific sequences.
*/
`ifndef WB8_SEQ_LIST
`define WB8_SEQ_LIST

package wb8_seq_list;
   
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // importing packages : agent,ref model, register ...
   /////////////////////////////////////////////////////////
	import i2c_master_wb8_pkg::*;
	import wb8_bridge_env_pkg::*;
	import wb8_agent_pkg::wb8_seq_item;
	import common_i2c_pkg::i2c_transaction;
	import common_seq_lib::*;
   //////////////////////////////////////////////////////////
   // include top env files 
   /////////////////////////////////////////////////////////
	// APIs
	`include "wb8_bus_seq.sv"

	// AXI-Lite workers
	`include "wb8_i2c_op_write_seq.sv" // write to i2c
	`include "wb8_i2c_op_read_seq.sv" // read to i2c

endpackage

`endif


