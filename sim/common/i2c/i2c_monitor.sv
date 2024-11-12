//------------------------------------------------------------------------------
// File: i2c_monitor.sv
// Description: UVM Monitor for I2C Bus Protocol
//
// This monitor observes I2C bus transactions and converts them into UVM transaction
// objects for analysis. It monitors START/STOP conditions, address phase, and data
// phase of I2C protocol, supporting both read and write operations.
//
// Features:
//   - Detects START and STOP conditions
//   - Decodes 7-bit addressing
//   - Supports single and multiple read and write operations
//   - Reports transactions via analysis port for scoreboarding
//------------------------------------------------------------------------------

`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

class i2c_monitor extends uvm_monitor;
	`uvm_component_utils(i2c_monitor)

	//--------------------------------------------------------------------------
	// Interface, Transaction Variables and Analysis Port
	//--------------------------------------------------------------------------
	
	// Interface to observe I2C signals
	virtual i2c_interface vif;

	// Current transaction being assembled
	protected i2c_transaction current_trans;

	// Buffer for collecting data bits
	protected bit [7:0] byte_buffer;

	// Port to broadcast observed transactions
	uvm_analysis_port #(i2c_transaction) analysis_port; // Renamed from analysis_port

	//--------------------------------------------------------------------------
	// Transaction and State Variables
	//--------------------------------------------------------------------------
	
	// Address received from master
	protected bit [7:0] captured_addr;

	// Tracks number of bits received in current transfer
	protected int       bits_received;

	//--------------------------------------------------------------------------
	// Methods
	//--------------------------------------------------------------------------
	
	// Constructor
	function new(string name = "i2c_monitor", uvm_component parent = null);
		super.new(name, parent);
		analysis_port = new("analysis_port", this);
	endfunction

	// Build phase - Get virtual interface
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", vif))
			`uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"})
	endfunction

	//--------------------------------------------------------------------------
	// Main Monitoring Process
	//--------------------------------------------------------------------------
	
	// Main monitoring task
	virtual task run_phase(uvm_phase phase);
		forever begin
			@(vif.monitor_cb);
			fork begin
				fork
					monitor_start_condition();
					monitor_stop_condition();
					monitor_bit_transfer();
				join_any
				disable fork;
			end join
		end
	endtask

	//--------------------------------------------------------------------------
	// Protocol State Monitoring
	//--------------------------------------------------------------------------
	
	// Detect START condition (SDA falling while SCL high)
	protected task monitor_start_condition();
		@(negedge vif.sda_i);
		if (vif.scl_i) begin
			`uvm_info(get_type_name(), "START condition detected", UVM_HIGH)
			bits_received = 0;
			current_trans = i2c_transaction::type_id::create("current_trans");
		end
		else wait(0);  // Wait for other tasks to finish
	endtask

	// Detect STOP condition (SDA rising while SCL high)
	protected task monitor_stop_condition();
		@(posedge vif.sda_i);
		if (vif.scl_i) begin
			`uvm_info(get_type_name(), "STOP condition detected", UVM_HIGH)
			if (current_trans != null) begin
				analysis_port.write(current_trans);
				`uvm_info(get_type_name(), $sformatf("I2C transaction finished %s", current_trans.convert2string()), UVM_LOW)
				current_trans = null;
			end
			bits_received = 0;
		end
		else wait(0);  // Wait for other tasks to finish
	endtask

	// Monitor data bits on SDA during SCL high
	protected task monitor_bit_transfer();
		wait(!vif.scl_i);  // Wait for SCL low before next bit
		
		`uvm_info(get_type_name(), $sformatf("Processing bit %0d", bits_received), UVM_HIGH)

		// Route to appropriate handler based on transaction phase
		if (bits_received < 8) begin
			handle_address_phase();
		end else begin
			handle_data_phase();
		end
	endtask

	//--------------------------------------------------------------------------
	// Protocol Phase Handlers
	//--------------------------------------------------------------------------
	
	// Process address phase (7-bit address + R/W bit)
	protected task handle_address_phase();
		@(posedge vif.scl_i);
		captured_addr[7-bits_received] = vif.sda_i;
		
		`uvm_info(get_type_name(), 
				$sformatf("Address bit[%0d] = %b", 7-bits_received, captured_addr[7-bits_received]), 
				UVM_HIGH)
		
		bits_received++;
		
		if (bits_received == 8) begin
			current_trans.is_write = !captured_addr[0];
			captured_addr = captured_addr >> 1;  // Extract 7-bit address
			current_trans.slave_addr = captured_addr;
		end
	endtask

	// Process data phase (8-bit data + ACK/NACK)
	protected task handle_data_phase();
		if (bits_received % 9 == 8) begin
			// Handle ACK/NACK bit
			@(posedge vif.scl_i);
			if (vif.sda_i) begin
				`uvm_info(get_type_name(), "NACK received", UVM_HIGH)
				return;
			end
			bits_received++;
		end
		else begin
			// Handle data bit
			int bit_index = 7 - (bits_received % 9);
			@(posedge vif.scl_i);
			byte_buffer[bit_index] = vif.sda_i;
			
			// Complete byte received
			if (bit_index == 0) begin
				current_trans.payload_data.push_back(byte_buffer);
				`uvm_info(get_type_name(), 
						$sformatf("Byte completed: 8'h%h", byte_buffer), 
						UVM_HIGH)
			end
			bits_received++;
		end
	endtask

endclass

`endif