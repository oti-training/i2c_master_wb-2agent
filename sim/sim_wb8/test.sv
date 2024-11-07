`ifndef TEST
`define TEST

class wb8_i2c_test extends uvm_test;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb8_i2c_test);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // environment handler
    wb8_i2c_environment wb8_i2c_environment_handler;

    // config handler
    wb8_i2c_test_config wb8_i2c_test_config_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        // initialize environment
        wb8_i2c_environment_handler = wb8_i2c_environment::type_id::create("wb8_i2c_environment_handler", this);
        // initialize config
        wb8_i2c_test_config_handler = wb8_i2c_test_config::type_id::create("wb8_i2c_test_config_handler");
        if (!uvm_config_db#(virtual wb8_interface)::get(this, "", "wb8_vif", wb8_i2c_test_config_handler.wb8_vif))
            `uvm_error("TEST", "Virtual interface cannot be loaded")
        if (!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", wb8_i2c_test_config_handler.i2c_vif))
            `uvm_error("TEST", "Virtual interface cannot be loaded")
        wb8_i2c_test_config_handler.test_type = 1;

        // register configured config object
        uvm_config_db#(wb8_i2c_test_config)::set(null, "*", "wb8_i2c_test_config", wb8_i2c_test_config_handler);

    endfunction
  
endclass

`endif