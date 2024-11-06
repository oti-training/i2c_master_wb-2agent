`ifndef test
`define TEST

// `include "environment.svh"

// class wb_master_test_config extends uvm_object;

//     // register to UVM factory
//     `uvm_object_utils(wb_master_test_config)

//     // default constructor
//     function new (string name="");
//         super.new(name);
//     endfunction

//     /**********************
//         Config Variables
//     ***********************/
//     // virtual interface
//     virtual top_interface top_vinterface;
//     // sequencer variables
//     int test_type;

// endclass

class wb_master_test extends uvm_test;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_test);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // environment handler
    wb_master_environment wb_master_environment_handler;

    // config handler
    wb_master_test_config wb_master_test_config_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        // initialize environment
        wb_master_environment_handler = wb_master_environment::type_id::create("wb_master_environment_handler", this);
        // initialize config
        wb_master_test_config_handler = wb_master_test_config::type_id::create("wb_master_test_config_handler");
        if (!uvm_config_db#(virtual top_interface)::get(this, "", "top_vinterface", wb_master_test_config_handler.top_vinterface))
            `uvm_error("TEST", "Virtual interface cannot be loaded")
        wb_master_test_config_handler.test_type = 1;

        // register configured config object
        uvm_config_db#(wb_master_test_config)::set(null, "*", "wb_master_config", wb_master_test_config_handler);

    endfunction
  
endclass

`endif