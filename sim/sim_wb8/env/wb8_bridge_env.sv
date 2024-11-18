/*
* File: wb8_bridge_env.sv
*
* This file defines the 'wb8_bridge_env' class, which represents the top-level UVM environment
* for verifying the WB8 to I2C Master Bridge.
*
* Key Features:
* - Instantiates and connects all major components of the verification environment.
* - Includes WB8 driver, monitor, and sequencer for stimulating and observing the DUT.
* - Includes I2C monitor for observing I2C transactions.
* - Incorporates a scoreboard for checking the correctness of transactions.
* - Includes a coverage collector for tracking functional coverage.
* - Sets up an I2C responder to simulate I2C slave behavior.
*
* The environment coordinates the interaction between these components to enable
* comprehensive testing of the WB8 to I2C Master Bridge functionality.
*/

`ifndef WB8_BRIDGE_ENV
`define WB8_BRIDGE_ENV

class wb8_bridge_env extends uvm_env;
    `uvm_component_utils(wb8_bridge_env)

    wb8_driver    wb8_drv;
    wb8_monitor   wb8_mon;
    wb8_i2c_monitor    i2c_mon;
    uvm_sequencer #(wb8_seq_item) wb8_seqr;
    scoreboard #(wb8_seq_item) scbd;
    wb8_coverage cov;

	wb8_ref_model ref_model;
	i2c_agent i2c_agnt;

    // Constructor
    function new(string name = "wb8_bridge_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase: Create and configure all components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create instances of all components
        wb8_drv = wb8_driver::type_id::create("wb8_drv", this);
        wb8_mon = wb8_monitor::type_id::create("wb8_mon", this);
        i2c_mon = wb8_i2c_monitor::type_id::create("i2c_mon", this);
        wb8_seqr = uvm_sequencer#(wb8_seq_item)::type_id::create("wb8_seqr", this);
        cov = wb8_coverage::type_id::create("cov", this);

		ref_model = wb8_ref_model::type_id::create("ref_model", this);
        scbd = scoreboard#(wb8_seq_item)::type_id::create("scbd", this);
		i2c_agnt = i2c_agent::type_id::create("i2c_agent", this);
    endfunction
    
    // Connect phase: Establish connections between components
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect sequencer to driver
        wb8_drv.seq_item_port.connect(wb8_seqr.seq_item_export);

		// Connect drivers to reference model
		wb8_drv.drv2rm_port.connect(ref_model.wb8_imp);
		i2c_agnt.driver.drv2rm_port.connect(ref_model.i2c_imp);

		// Connect reference model to scoreboard
		ref_model.wb8_rm2sb_port.connect(scbd.master_exp_imp);
		ref_model.i2c_rm2sb_port.connect(scbd.i2c_exp_imp);

        // Connect monitors to scoreboard
        wb8_mon.ap.connect(scbd.master_act_imp);
        i2c_agnt.monitor.mon2sb.connect(scbd.i2c_act_imp);

        // Connect AXI-Lite monitor to coverage collector
        wb8_mon.ap.connect(cov.analysis_export);
        `uvm_info("ENV", "All connections completed", UVM_LOW)
    endfunction
endclass

`endif
