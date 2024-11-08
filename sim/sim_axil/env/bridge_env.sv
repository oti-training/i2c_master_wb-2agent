/*
* File: bridge_env.sv
*
* This file defines the 'bridge_env' class, which represents the top-level UVM environment
* for verifying the AXI-Lite to I2C Master Bridge.
*
* Key Features:
* - Instantiates and connects all major components of the verification environment.
* - Includes AXI-Lite driver, monitor, and sequencer for stimulating and observing the DUT.
* - Includes I2C monitor for observing I2C transactions.
* - Incorporates a scoreboard for checking the correctness of transactions.
* - Includes a coverage collector for tracking functional coverage.
* - Sets up an I2C responder to simulate I2C slave behavior.
*
* The environment coordinates the interaction between these components to enable
* comprehensive testing of the AXI-Lite to I2C Master Bridge functionality.
*/

`ifndef BRIDGE_ENV
`define BRIDGE_ENV

class bridge_env extends uvm_env;
    axil_driver    axil_drv;
    axil_monitor   axil_mon;
    i2c_monitor    i2c_mon;
    uvm_sequencer #(axil_seq_item) axil_seqr;
    scoreboard scbd;
    axil_coverage cov;

    i2c_responder i2c_resp;
    
    `uvm_component_utils(bridge_env)
    
    // Constructor
    function new(string name = "bridge_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase: Create and configure all components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create instances of all components
        axil_drv = axil_driver::type_id::create("axil_drv", this);
        axil_mon = axil_monitor::type_id::create("axil_mon", this);
        i2c_mon = i2c_monitor::type_id::create("i2c_mon", this);
        axil_seqr = uvm_sequencer#(axil_seq_item)::type_id::create("axil_seqr", this);
        scbd = scoreboard::type_id::create("scbd", this);
        cov = axil_coverage::type_id::create("cov", this);

        i2c_resp = i2c_responder::type_id::create("i2c_resp", this);  
    endfunction
    
    // Connect phase: Establish connections between components
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect sequencer to driver
        axil_drv.seq_item_port.connect(axil_seqr.seq_item_export);

        // Connect monitors to scoreboard
        axil_mon.ap.connect(scbd.axil_export);
        i2c_mon.ap.connect(scbd.i2c_export);

        // Connect AXI-Lite monitor to coverage collector
        axil_mon.ap.connect(cov.analysis_export);
        `uvm_info("ENV", "All connections completed", UVM_LOW)
    endfunction
endclass

`endif
