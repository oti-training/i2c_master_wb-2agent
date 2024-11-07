/*
* File: i2c_master_test.sv
*
* This file defines the main test case for the I2C master verification.
* It extends the base test and implements specific test scenarios.
*
* TODO:
* - Implement more diverse test scenarios to cover edge cases
* - Add error injection mechanisms to test error handling
* - Consider parameterizing the test for different I2C speeds
*
* NOTE: This implementation could benefit from more modular sequence composition
* to enhance reusability and test coverage.
*/
`ifndef I2C_MASTER_TEST
`define I2C_MASTER_TEST

class i2c_master_test extends i2c_master_base_test;
    `uvm_component_utils(i2c_master_test)
    
    function new(string name = "i2c_master_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        config_seq config_seq_i;
        write_read_seq wr_seq_i;
        
        phase.raise_objection(this);
        
        config_seq_i = config_seq::type_id::create("config_seq");
        `uvm_info("TEST", "Starting config sequence", UVM_LOW)
        config_seq_i.start(env.axil_seqr);
        
        #1000;
        // TODO: Replace this check with a more robust mechanism
        if (env.axil_seqr == null)
        `uvm_fatal("test", "seqr null");
        
        wr_seq_i = write_read_seq::type_id::create("wr_seq");
        `uvm_info("TEST", "Starting write/read sequence", UVM_LOW)
        wr_seq_i.start(env.axil_seqr);

        // TODO: Add more diverse test scenarios here

        #10000; // TODO: Replace magic number with a calculated or configurable value
        
        phase.drop_objection(this);
    endtask
endclass

`endif
