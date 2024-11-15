/*
* File: axil_bridge_env.sv
*
* This file defines the 'axil_bridge_env' class, which represents the top-level UVM environment
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

`ifndef AXIL_BRIDGE_ENV
`define AXIL_BRIDGE_ENV

class axil_bridge_env extends uvm_env;
    `uvm_component_utils(axil_bridge_env)

    axil_driver    axil_drv;
    axil_monitor   axil_mon;
    axil_i2c_monitor    i2c_mon;
    uvm_sequencer #(axil_seq_item) axil_seqr;
    axil_scoreboard scbd;
    axil_coverage cov;

	axil_ref_model ref_model;
	i2c_agent i2c_agnt;

    // Constructor
    function new(string name = "axil_bridge_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase: Create and configure all components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create instances of all components
        axil_drv = axil_driver::type_id::create("axil_drv", this);
        axil_mon = axil_monitor::type_id::create("axil_mon", this);
        i2c_mon = axil_i2c_monitor::type_id::create("i2c_mon", this);
        axil_seqr = uvm_sequencer#(axil_seq_item)::type_id::create("axil_seqr", this);
        cov = axil_coverage::type_id::create("cov", this);

		ref_model = axil_ref_model::type_id::create("ref_model", this);
        scbd = axil_scoreboard::type_id::create("scbd", this);
		i2c_agnt = i2c_agent::type_id::create("i2c_agent", this);
    endfunction
    
    // Connect phase: Establish connections between components
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect sequencer to driver
        axil_drv.seq_item_port.connect(axil_seqr.seq_item_export);

		// Connect drivers to reference model
		axil_drv.drv2rm_port.connect(ref_model.axil_imp);
		i2c_agnt.driver.drv2rm_port.connect(ref_model.i2c_imp);

		// Connect reference model to scoreboard
		ref_model.axil_rm2sb_port.connect(scbd.axil_exp_imp);
		ref_model.i2c_rm2sb_port.connect(scbd.i2c_exp_imp);

        // Connect monitors to scoreboard
        axil_mon.ap.connect(scbd.axil_act_imp);
        i2c_agnt.monitor.mon2sb.connect(scbd.i2c_act_imp);

        // Connect AXI-Lite monitor to coverage collector
        axil_mon.ap.connect(cov.analysis_export);
        `uvm_info("ENV", "All connections completed", UVM_LOW)
    endfunction
endclass

`endif
