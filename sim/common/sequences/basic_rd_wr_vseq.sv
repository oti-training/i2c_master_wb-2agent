//------------------------------------------------------------------------------
// File: basic_rd_wr_vseq.sv
// 
// Description:
//   This file implements a basic read/write virtual sequence for I2C operations.
//   It coordinates master and slave sequences to perform I2C transactions with
//   configurable slave addresses and payload lengths. The sequence supports both
//   single operation mode (1 byte) and multiple operation mode (up to 16 bytes).
//
// Key Features:
//   - Random slave address (7-bit)
//	 - Support for multiple operation modes with random length (1-16 bytes)
//   - Support for single operation modes
//   - Parallel execution of master and slave sequences
//
// Usage:
//   1. Define master sequence for i2c read or write using master_i2c_op_base_seq
//		as base
//   2. Configure with master and I2C sequencers using configure()
//   3. Start sequence using either start_single() or start_multiple()
//   4. Sequence will automatically coordinate master and slave operations
//------------------------------------------------------------------------------

`ifndef BASIC_RD_WR_VSEQ_SV
`define BASIC_RD_WR_VSEQ_SV

class basic_rd_wr_vseq #(type T=master_i2c_op_base_seq) extends uvm_sequence;

    //--------------------------------------------------------------------------
    // Class Properties
    //--------------------------------------------------------------------------
    // Sequencers for master and slave operations
    uvm_sequencer_base master_sequencer;
    uvm_sequencer_base i2c_sequencer;
    
    // Sequence instances
    T master_sequence;                  // Parameterized master sequence
    i2c_response_seq i2c_api;          // Slave response sequence
	
    // Randomized variables for I2C transaction configuration
    protected rand bit [6:0] slave_addr;           // Target slave address
    protected rand int payload_data_length;        // Number of bytes to transfer
    protected bit single_op_mode = 0;             // Single vs multiple operation mode flag

    // Constraints for payload length based on operation mode
    constraint cfg_c {
        if (single_op_mode) {
            payload_data_length == 1;
        } else {
            // limit maximum length to 16 bytes
            payload_data_length inside {[2:16]};
        }
    }

    //--------------------------------------------------------------------------
    // Factory Registration
    //--------------------------------------------------------------------------
    `uvm_object_utils_begin(basic_rd_wr_vseq#(T))
        `uvm_field_int(slave_addr, UVM_DEFAULT)
        `uvm_field_int(payload_data_length, UVM_DEFAULT)
    `uvm_object_utils_end

    //--------------------------------------------------------------------------
    // Class Properties
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "basic_rd_wr_vseq");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Main Sequence Methods
    //--------------------------------------------------------------------------
    task body();
        // create subsequences
        master_sequence = T::type_id::create("master_sequence");
        i2c_api = i2c_response_seq::type_id::create("i2c_api");

        // do a part of the randomization in vseq level
        randomize_this();

        // run subsequences in parallel
        fork
            master_sequence.start(master_sequencer);
            i2c_api.start(i2c_sequencer);
        join
    endtask

    //--------------------------------------------------------------------------
    // Configuration and Control Methods
    //--------------------------------------------------------------------------
    task configure(
        input uvm_sequencer_base master_sequencer,
        input uvm_sequencer_base i2c_sequencer
        );

        this.master_sequencer = master_sequencer;
        this.i2c_sequencer = i2c_sequencer;
    endtask

    task start_single();
        single_op_mode = 1;
        start(null);
    endtask

    task start_multiple();
        single_op_mode = 0;
        start(null);
    endtask

    //--------------------------------------------------------------------------
    // Internal Helper Methods
    //--------------------------------------------------------------------------
    // Handles randomization and propagation of configuration to worker sequences
    protected task randomize_this();
        if (!this.randomize())
            `uvm_error(get_type_name(), "Randomization failed");
        `uvm_info(get_type_name(), $sformatf("slave_addr=%0h payload_data_length=%0d", slave_addr, payload_data_length), UVM_LOW)

        // apply randomized to each workers
        i2c_api.req.cfg_slave_addr = slave_addr;
        master_sequence.slave_addr = slave_addr;
        master_sequence.payload_data_length = payload_data_length;
        i2c_api.req.cfg_payload_length = payload_data_length;
    endtask

endclass

`endif