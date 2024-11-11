`ifndef CONFIG_OBJECT
`define CONFIG_OBJECT

class wb16_i2c_test_config extends uvm_object;

    // register to UVM factory
    `uvm_object_utils(wb16_i2c_test_config)

    // default constructor
    function new (string name="");
        super.new(name);
    endfunction

    /**********************
        Config Variables
    ***********************/
    // virtual interface
    virtual wb16_interface wb16_vif;
    virtual i2c_interface i2c_vif;
    // sequencer variables
    int test_type;

endclass

`endif