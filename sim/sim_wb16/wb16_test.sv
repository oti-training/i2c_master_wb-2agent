`ifndef TEST
`define TEST

class wb16_i2c_test extends uvm_test;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb16_i2c_test);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // environment handler
    wb16_i2c_environment wb16_i2c_environment_handler;

    // config handler
    wb16_i2c_test_config wb16_i2c_test_config_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        // initialize environment
        wb16_i2c_environment_handler = wb16_i2c_environment::type_id::create("wb16_i2c_environment_handler", this);
        // initialize config
        wb16_i2c_test_config_handler = wb16_i2c_test_config::type_id::create("wb16_i2c_test_config_handler");
        if (!uvm_config_db#(virtual wb16_interface)::get(this, "", "wb16_vif", wb16_i2c_test_config_handler.wb16_vif))
            `uvm_error("TEST", "Virtual interface cannot be loaded")
        if (!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", wb16_i2c_test_config_handler.i2c_vif))
            `uvm_error("TEST", "Virtual interface cannot be loaded")
        wb16_i2c_test_config_handler.test_type = 1;

        // register configured config object
        uvm_config_db#(wb16_i2c_test_config)::set(null, "*", "wb16_i2c_test_config", wb16_i2c_test_config_handler);

    endfunction
  
endclass

`endif