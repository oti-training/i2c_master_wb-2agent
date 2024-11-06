`ifndef AGENT
`define AGENT

// `include "driver.svh"
// `include "monitor.svh"
// `include "sequence.svh"

class wb_master_agent extends uvm_agent;
  
    // register agent as component to UVM Factory
    uvm_analysis_port #(monitor_sequence_item) bypass_port;
    `uvm_component_utils(wb_master_agent);

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    // initialize handlers for agent components
    wb_master_sequencer wb_master_sequencer_handler;
    wb_master_driver wb_master_driver_handler;
    wb_master_monitor wb_master_monitor_handler;
    wb_master_vsequence wb_master_vsequence_handler;

    // create components
    function void build_phase(uvm_phase phase);
        wb_master_sequencer_handler = wb_master_sequencer::type_id::create("wb_master_sequencer_handler", this);
        wb_master_driver_handler = wb_master_driver::type_id::create("wb_master_driver_handler", this);
        wb_master_monitor_handler = wb_master_monitor::type_id::create("wb_master_monitor_handler", this);
        bypass_port = new("bypass_port", this);
    endfunction

     // connect phase function
    function void connect_phase(uvm_phase phase);
        wb_master_driver_handler.seq_item_port.connect(wb_master_sequencer_handler.seq_item_export);
        wb_master_monitor_handler.ap.connect(bypass_port);
    endfunction
  
    // run phase task
    task run_phase (uvm_phase phase);
    phase.raise_objection(this);
    begin
        /********Using Worker Task Example********/
        // write_i2c_worker seq;
        // read_i2c_worker seq2;

        // /*******Write Example*******/
        // seq = write_i2c_worker::type_id::create("seq");
        // // seq.set_property(7'h6, 8'ha, 8'h33, 1);
        // // seq.start(wb_master_sequencer_handler);
        // seq.write_i2c(7'h6, 8'ha, 8'h33, 1, wb_master_sequencer_handler);
        
        // /*******Read Example*******/
        // seq2 = read_i2c_worker::type_id::create("seq2");
        // // seq2.set_property(7'h6, 8'ha, 1);
        // // seq2.start(wb_master_sequencer_handler);
        // seq2.read_i2c(7'h6, 8'ha, 1, wb_master_sequencer_handler);


        /********Using Virtual Sequence Example********/
        wb_master_vsequence_handler = wb_master_vsequence::type_id::create("wb_master_vsequence_handler");
        wb_master_vsequence_handler.sequencer_1 = wb_master_sequencer_handler;
        wb_master_vsequence_handler.start(null);

    end
    phase.drop_objection(this);

    endtask

endclass

`endif