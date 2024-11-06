`ifndef ENVIRONMENT
`define ENVIRONMENT

`include "agent.svh"
`include "agent_slave.svh"
`include "scoreboard.svh"

class wb_master_environment extends uvm_env;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_environment);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    wb_master_agent wb_master_agent_handler;
    wb_master_agent_slave wb_master_agent_slave_handler;
    top_scoreboard top_scoreboard_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        wb_master_agent_handler = wb_master_agent::type_id::create("wb_master_agent_handler", this);
        wb_master_agent_slave_handler = wb_master_agent_slave::type_id::create("wb_master_agent_slave_handler", this);
        top_scoreboard_handler = top_scoreboard::type_id::create("top_scoreboard_handler", this);
    endfunction
    
    // connect phase
    function void connect_phase(uvm_phase phase);
        // wb_master_agent_handler.wb_master_monitor_handler.ap.connect(top_scoreboard_handler.ae);
        wb_master_agent_handler.bypass_port.connect(top_scoreboard_handler.wb_to_i2c.analysis_export);
        wb_master_agent_slave_handler.wb_master_driver_slave_handler.ap.connect(top_scoreboard_handler.i2c_observer.analysis_export);
    endfunction
  
endclass

`endif