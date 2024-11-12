//------------------------------------------------------------------------------
// File: master_i2c_op_base_seq.sv
// Description: Base sequence as an interface to share virtual sequences among
//				different bus protocols
//
//   Base sequence class for I2C master operations. This class defines the basic
//   structure and interface for all master I2C sequences. Derived classes must
//   implement the body() task to define specific I2C operations.
//
// Usage:
//   - Extend this class to create specific I2C master operation sequences
//   - Override body() task to implement desired I2C transaction behavior
//   - Configure payload_data_length and slave_addr before starting sequence
//------------------------------------------------------------------------------

`ifndef MASTER_I2C_OP_BASE_SEQ
`define MASTER_I2C_OP_BASE_SEQ

class master_i2c_op_base_seq extends uvm_sequence;
    `uvm_object_utils(master_i2c_op_base_seq)

    //--------------------------------------------------------------------------
    // Configuration Parameters
    //--------------------------------------------------------------------------
    int payload_data_length;           // Length of data payload
    bit [6:0] slave_addr;             // Target slave address

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "master_i2c_op_base_seq");
        super.new(name);
    endfunction
    
    //--------------------------------------------------------------------------
    // Virtual Methods
    //--------------------------------------------------------------------------
    // Must be overridden by derived classes to implement specific I2C operations
    virtual task body();
    endtask

endclass

`endif