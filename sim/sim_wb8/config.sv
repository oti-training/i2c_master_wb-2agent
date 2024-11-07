`ifndef CONFIG_OBJECT
`define CONFIG_OBJECT

class wb8_i2c_test_config extends uvm_object;

    // register to UVM factory
    `uvm_object_utils(wb8_i2c_test_config)

    // default constructor
    function new (string name="");
        super.new(name);
    endfunction

    /**********************
        Config Variables
    ***********************/
    // virtual interface
    virtual wb8_interface wb8_vif;
    virtual i2c_interface i2c_vif;
    // sequencer variables
    int test_type;

endclass

`endif