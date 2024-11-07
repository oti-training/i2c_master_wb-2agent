/*
* File: i2c_master_base_test.sv
*
* This file defines the base test class for the I2C master verification.
*
* TODO:
* - Implement more sophisticated configuration sequences
* - Add error injection mechanisms for robust testing
* - Consider parameterizing the test for different DUT configurations
*
* Improvement Opportunities:
* - The current implementation lacks comments explaining the purpose of each phase
* - Error handling and reporting could be improved
* - Consider adding more flexible configuration options
*/
`ifndef I2C_MASTER_BASE_TEST
`define I2C_MASTER_BASE_TEST

class i2c_master_base_test extends uvm_test;
    bridge_env env;
    
    `uvm_component_utils(i2c_master_base_test)
    
    function new(string name = "i2c_master_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = bridge_env::type_id::create("env", this);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        // TODO: Consider moving this to a separate configuration class
        // responder initial values
        env.i2c_resp.set_memory(7'h50, 8'hAA);  // example: set address 0x50 to value 0xaa
        env.i2c_resp.my_address = 7'h50;        // set responder's i2c address
    endfunction

    task run_phase(uvm_phase phase);
        config_seq config_seq_i;
        
        phase.raise_objection(this);

        config_seq_i = config_seq::type_id::create("config_seq");
        config_seq_i.start(env.axil_seqr);
        
        // TODO: Add more sophisticated test scenarios
        #1000;
        phase.drop_objection(this);
    endtask
    // TODO: Implement other phases as needed (e.g., extract_phase for results checking)
endclass

`endif
