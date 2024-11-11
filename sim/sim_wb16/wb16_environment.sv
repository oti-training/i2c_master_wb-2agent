`ifndef ENVIRONMENT
`define ENVIRONMENT

class wb16_i2c_environment extends uvm_env;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb16_i2c_environment);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    wb_master_agent wb_master_agent_handler;
    i2c_slave_agent i2c_slave_agent_handler;
    wb16_i2c_scoreboard wb16_i2c_scoreboard_handler;
    wb16_i2c_coverage_collector wb16_i2c_coverage_collector_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        wb_master_agent_handler = wb_master_agent::type_id::create("wb_master_agent_handler", this);
        i2c_slave_agent_handler = i2c_slave_agent::type_id::create("i2c_slave_agent_handler", this);
        wb16_i2c_scoreboard_handler = wb16_i2c_scoreboard::type_id::create("wb16_i2c_scoreboard_handler", this);
        wb16_i2c_coverage_collector_handler = wb16_i2c_coverage_collector::type_id::create("wb16_i2c_coverage_collector_handler", this);
    endfunction
    
    // connect phase
    function void connect_phase(uvm_phase phase);
        wb_master_agent_handler.wb_master_monitor_handler.monitor_to_scoreboard_ap.connect(wb16_i2c_scoreboard_handler.wb_to_i2c.analysis_export);
        i2c_slave_agent_handler.i2c_slave_driver_handler.driver_slave_ap.connect(wb16_i2c_scoreboard_handler.i2c_observer.analysis_export);
        i2c_slave_agent_handler.i2c_slave_driver_handler.driver_slave_ap.connect(wb16_i2c_coverage_collector_handler.coverage_object_fifo.analysis_export);
        wb_master_agent_handler.wb_master_monitor_handler.monitor_to_coverage_ap.connect(wb16_i2c_coverage_collector_handler.coverage_object_fifo.analysis_export);
    endfunction
  
endclass

`endif