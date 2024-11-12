//------------------------------------------------------------------------------
// File Name: i2c_response_seq.sv
// Description: Sequence class for generating I2C slave responses
//
// This file implements the API response sequence for an I2C slave simulator
// in a verification environment targeting an AXIL-to-I2C bridge DUT. The DUT 
// operates as an I2C master requiring our testbench to provide I2C slave
// responses.
//
// Response Sequence Strategy:
// 1. Current Implementation
//    - Configurable slave address and payload length
//    - Provides randomized data responses for I2C read operations
//
// 2. Future Extensibility
//    This base sequence establishes a framework that can be extended for:
//    - NACK response scenarios
//    - Error injection cases
//    - Timing variation testing
//    - Protocol violation testing
//
// Usage:
// This sequence is typically started from a virtual sequence using:
//	i2c_response_seq seq = i2c_response_seq::type_id::create("seq");
//	i2c_api.req.cfg_slave_addr = slave_addr;
//	i2c_api.req.cfg_payload_length = payload_length;
//	seq.start(i2c_sequencer);
//------------------------------------------------------------------------------

`ifndef I2C_RESPONSE_SEQ
`define I2C_RESPONSE_SEQ

class i2c_response_seq extends uvm_sequence #(i2c_transaction);
    `uvm_object_utils(i2c_response_seq)
	i2c_transaction req;

    function new(string name = "i2c_response_seq");
        super.new(name);
		req = i2c_transaction::type_id::create("req");
    endfunction
  
	task body();
		start_item(req);
		if (!req.randomize())
			`uvm_error(get_type_name(), "Randomization failed");
		finish_item(req);
	endtask

endclass

`endif
