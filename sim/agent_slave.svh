`ifndef AGENT_SLAVE
`define AGENT_SLAVE

`include "driver_slave.svh"

class wb_master_agent_slave extends uvm_agent;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_agent_slave);

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    // initialize handlers for agent components
    wb_master_driver_slave wb_master_driver_slave_handler;
    sequencer_slave sequencer_slave_handler;

    // create components
    function void build_phase(uvm_phase phase);
        wb_master_driver_slave_handler = wb_master_driver_slave::type_id::create("wb_master_driver_slave_handler", this);
        sequencer_slave_handler = sequencer_slave::type_id::create("sequencer_slave_handler", this);
    endfunction

    // connect components
    function void connect_phase(uvm_phase phase);
        wb_master_driver_slave_handler.seq_item_port.connect(sequencer_slave_handler.seq_item_export);
    endfunction
  
    // run phase task
    task run_phase (uvm_phase phase);
        // phase.raise_objection(this);
        begin
            sequence_slave sequence_slave_handler;
            sequence_slave_handler = sequence_slave::type_id::create("seq_slave");
            sequence_slave_handler.start(sequencer_slave_handler);
        end
        // phase.drop_objection(this);
    endtask

endclass

`endif