`ifndef AGENT_SLAVE
`define AGENT_SLAVE

// `include "driver_slave.svh"

class i2c_slave_agent extends uvm_agent;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(i2c_slave_agent);

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    // initialize handlers for agent components
    i2c_slave_driver i2c_slave_driver_handler;
    i2c_slave_sequencer i2c_slave_sequencer_handler;

    // create components
    function void build_phase(uvm_phase phase);
        i2c_slave_driver_handler = i2c_slave_driver::type_id::create("i2c_slave_driver_handler", this);
        i2c_slave_sequencer_handler = i2c_slave_sequencer::type_id::create("i2c_slave_sequencer_handler", this);
    endfunction

    // connect components
    function void connect_phase(uvm_phase phase);
        i2c_slave_driver_handler.seq_item_port.connect(i2c_slave_sequencer_handler.seq_item_export);
    endfunction
  
    // run phase task
    task run_phase (uvm_phase phase);
        // phase.raise_objection(this);
        begin
            i2c_slave_sequence i2c_slave_sequence_handler;
            i2c_slave_sequence_handler = i2c_slave_sequence::type_id::create("i2c_slave_sequence_handler");
            i2c_slave_sequence_handler.start(i2c_slave_sequencer_handler);
        end
        // phase.drop_objection(this);
    endtask

endclass

`endif