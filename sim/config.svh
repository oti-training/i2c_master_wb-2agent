`ifndef CONFIG_OBJECT
`define CONFIG_OBJECT

class wb_master_test_config extends uvm_object;

    // register to UVM factory
    `uvm_object_utils(wb_master_test_config)

    // default constructor
    function new (string name="");
        super.new(name);
    endfunction

    /**********************
        Config Variables
    ***********************/
    // virtual interface
    virtual top_interface top_vinterface;
    // sequencer variables
    int test_type;

endclass

`endif