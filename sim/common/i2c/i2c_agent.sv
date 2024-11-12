//------------------------------------------------------------------------------
// File Name: i2c_agent.sv
// Description: UVM Agent class for I2C protocol verification
//
// This file implements a UVM agent for master I2C (Inter-Integrated Circuit)
// protocol verification. It encapsulates a driver, monitor, and sequencer to
// work as an active agent.
//
// Key Components:
// - Driver: Converts sequence items into pin-level I2C signaling
// - Monitor: Samples I2C interface and converts to transactions
// - Sequencer: Generates and coordinates transaction sequences
//------------------------------------------------------------------------------

`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

class i2c_agent extends uvm_agent;
	`uvm_component_utils(i2c_agent)

	//--------------------------------------------------------------------------
	// UVM Components
	//--------------------------------------------------------------------------
	
	i2c_driver driver;
	i2c_monitor monitor;
    uvm_sequencer #(i2c_transaction) sequencer;

	//--------------------------------------------------------------------------
	// Methods
	//--------------------------------------------------------------------------

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		driver = i2c_driver::type_id::create("driver", this);
        sequencer = uvm_sequencer#(i2c_transaction)::type_id::create("sequencer", this);
		monitor = i2c_monitor::type_id::create("monitor", this);
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
		driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction : connect_phase
 
endclass

`endif