/*
File: wb8_test_pkg.sv

This file defines the WB8 test package, which encapsulates all the test-related 
components and utilities for the WB8 to I2C Master Bridge verification environment.

Key Features:
- Imports necessary UVM packages and macros.
- Imports custom packages containing sequences, environment components, and other necessities.
- Includes test case files, defining the base test and specific test scenarios.

The package serves several important purposes:
1. Centralizes all test-related components, making them easily accessible to the testbench.
2. Provides a clear separation between test components and other verification components.
3. Allows for easy addition of new test cases by simply including them in this package.

By organizing test components in this package, we enhance modularity and make it easier
to manage and extend the test suite for the WB8 to I2C Master Bridge.
*/

`ifndef WB8_TEST_PKG
`define WB8_TEST_PKG

package wb8_test_pkg;
   
   // Import UVM package and include macros
  import uvm_pkg::*;
  `include "uvm_macros.svh"

   // Import custom packages
	import wb8_seq_list::*;
	import wb8_bridge_env_pkg::*;
	import common_seq_lib::basic_rd_wr_vseq;

   // Include test case files
  `include "wb8_basic_test.sv"

   // Note: Add new test case includes here as they are developed
endpackage

`endif


