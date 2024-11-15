/*
* 
  * File: i2c_trans.sv
  * This file defines the I2C transaction class used in the UVM testbench for
  * the AXI-Lite to I2C Master Bridge.
*
* Key Features:
* - Extend the uvm_sequence_item to create a transaction object for I2C
*   operations.
* - Defines fields necessary to represent an I2C transaction:
*   - addr: 7-bit I2C slave address
*   - read: Flag indicating if it's a read (1) or write (0) operation
*   - data: 8-bit data for read or write
*   - nack: Flag indicating if a NACK was received
* - Implements UVM automation macros for field operations.
* - Provides a custom convert2string method for easy transaction printing
*
* This class is crucial for:
* 1. Generating stimulus for I2C operations in sequences.
* 2. Capturing and analyzing I2C transactions in the scoreboard.
* 3. Comparing expected vs. actual I2C transactions in the scoreboard.
*
* The randomization of fields allows for creation of various I2C scenarios,
* enhancing the coverage of the verification environment
  *
*/
`ifndef I2C_TRANS
`define I2C_TRANS

class i2c_trans extends uvm_sequence_item;

    // I2C transaction fields
    rand bit [6:0] addr;
    rand bit       read;
    rand bit [7:0] data;
    bit nack;   
    
    // UVM automation macros for field operations
    `uvm_object_utils_begin(i2c_trans)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(read, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(nack, UVM_DEFAULT)  
    `uvm_object_utils_end

    // Constructor
    function new(string name = "i2c_trans");
        super.new(name);
    endfunction

    // Custom string conversion for easy debug printing
    function string convert2string();
        return $sformatf("addr=%h read=%b data=%h", addr, read, data);
    endfunction
endclass

`endif