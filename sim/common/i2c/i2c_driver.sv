//------------------------------------------------------------------------------
// File: i2c_driver.sv
// Description: UVM Driver for I2C Slave Device
//
// This driver implements I2C slave behavior, responding to I2C master transactions
// on the bus. It supports both read and write operations, with configurable slave
// addressing. The driver monitors START/STOP conditions and handles address
// matching and data transfer according to the I2C protocol specification.
//
// Features:
//   - Responds to I2C START and STOP conditions
//   - Address matching for targeted slave operations
//   - Supports single and multiple read and write transfers
//   - Implements proper I2C acknowledgment handling
//   - Maintains protocol timing through SCL synchronization
//------------------------------------------------------------------------------

`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_transaction);
	`uvm_component_utils(i2c_driver)

	//--------------------------------------------------------------------------
	// Interface and Transaction Variables
	//--------------------------------------------------------------------------
	
	// Interface for driving I2C signals
	virtual i2c_interface vif;

	// Current transaction being processed
	protected i2c_transaction current_trans;

	// Port for reference model
	uvm_analysis_port#(i2c_transaction) drv2rm_port;

	// Buffer for driving read bytes
	protected bit [7:0] byte_buffer;
	
	//--------------------------------------------------------------------------
	// Protocol State Variables
	//--------------------------------------------------------------------------
	
	// Address received from master
	protected bit [7:0] captured_addr;
	
	// Tracks number of bits processed in current transfer
	protected int bit_count;
	
	// Indicates if current transaction is a read operation
	protected bit is_write_op;

	// Indicates if read transaction is ongoing
	protected bit is_ongoing = 0;

	//--------------------------------------------------------------------------
	// Methods
	//--------------------------------------------------------------------------
	
	// Constructor
	function new(string name = "i2c_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// Build phase - Get virtual interface
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", vif))
			`uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif"})
		drv2rm_port = new("drv2rm_port", this);
	endfunction

	//--------------------------------------------------------------------------
	// Main Driver Process
	//--------------------------------------------------------------------------
	
	// Main driver task - Initialize and handle I2C operations
	virtual task run_phase(uvm_phase phase);
		// Initialize I2C lines to idle state (both high)
		initialize_i2c_bus();
		
		forever begin
			@(vif.driver_cb);
			fork begin
				fork
					detect_start_condition();
					detect_stop_condition();
					handle_bit_transfer();
				join_any
				disable fork;
			end join
		end
	endtask

	// Initialize the I2C bus to idle state
	protected task initialize_i2c_bus();
		vif.driver_cb.scl_o <= 1;  // SCL released (pulled high)
		vif.driver_cb.sda_o <= 1;  // SDA released (pulled high)
	endtask

	//--------------------------------------------------------------------------
	// Protocol State Detection
	//--------------------------------------------------------------------------
	
	// Monitor for START condition (SDA falling while SCL high)
	protected task detect_start_condition();
		@(negedge vif.sda_i);
		if (vif.scl_i) begin
			`uvm_info(get_type_name(), "START condition detected", UVM_HIGH)
			bit_count = 0;
			if (current_trans == null) begin
				i2c_transaction to_rm;

				seq_item_port.get_next_item(current_trans);
				
				$cast(to_rm,current_trans.clone());
				to_rm.set_id_info(current_trans);
				drv2rm_port.write(to_rm);
				
				is_ongoing = 1;
			end
		end
		else wait(0);  // Not a valid START condition
	endtask

	// Monitor for STOP condition (SDA rising while SCL high)
	protected task detect_stop_condition();
		@(posedge vif.sda_i);
		if (vif.scl_i) begin
			`uvm_info(get_type_name(), "STOP condition detected", UVM_HIGH)
			if (current_trans != null) begin
				seq_item_port.item_done();
				current_trans = null;
			end
			bit_count = 0;
			vif.sda_o <= 1;  // Release SDA line
			is_ongoing = 0;
		end
		else wait(0);  // Not a valid STOP condition
	endtask

	// Main bit transfer handler - routes to appropriate phase handler
	protected task handle_bit_transfer();
		wait(!vif.scl_i);  // Synchronize to SCL low
		`uvm_info(get_type_name(), $sformatf("Processing bit %0d", bit_count), UVM_HIGH)

		if (bit_count < 9) begin
			handle_address_phase();
		end
		else begin
			if (is_write_op) handle_write_data_phase();
			else handle_read_data_phase();
		end
	endtask

	//--------------------------------------------------------------------------
	// Protocol Phase Handlers
	//--------------------------------------------------------------------------
	
	// Process address phase (7-bit address + R/W bit)
	protected task handle_address_phase();
		if (bit_count < 8) begin
			wait(vif.scl_i);  // Wait for clock to sample address bit
			captured_addr[7-bit_count] = vif.sda_i;
			
			`uvm_info(get_type_name(), 
					$sformatf("Address bit[%0d] = %b", 7-bit_count, captured_addr[7-bit_count]), 
					UVM_HIGH)
		end
		// Complete address reception
		if (bit_count == 8) begin
			is_write_op = !captured_addr[0];  // R/W bit
			captured_addr = captured_addr >> 1;  // Extract 7-bit address
			
			// Check if this slave is being addressed
			if (current_trans != null && captured_addr == current_trans.slave_addr) begin
				send_ack();  // Acknowledge if address matches
				`uvm_info(get_type_name(), "Address matched and acknowledged", UVM_HIGH)
			end
		end
		
		bit_count++;
	endtask

	// Handle read data phase (slave transmitting)
	protected task handle_read_data_phase();
		`uvm_info(get_type_name(), "Processing read transaction", UVM_HIGH)
		
		if (bit_count % 9 == 8) begin
			handle_read_byte_completion();
		end
		else if (current_trans != null) begin
			drive_read_data_bit();
		end
	endtask

	// Complete read byte transmission and check for ACK/NACK
	protected task handle_read_byte_completion();
		`uvm_info(get_type_name(), "Read byte transmission complete", UVM_HIGH)
		vif.sda_o <= 1;  // Release SDA for master ACK/NACK
		@(posedge vif.scl_i);
		
		if (vif.sda_i) begin  // NACK received
			`uvm_info(get_type_name(), "Master sent NACK - ending transfer", UVM_HIGH)
			return;
		end
		bit_count++;
	endtask

	// Drive individual bits during read operation
	protected task drive_read_data_bit();
		int bit_index = 7 - (bit_count % 9);
		
		if (is_ongoing) begin
			// Load new byte if starting a new byte transmission
			if (bit_index == 7)
				byte_buffer = current_trans.payload_data.pop_front();
				
			vif.sda_o <= byte_buffer[bit_index];
			wait(vif.scl_i);
			
			`uvm_info(get_type_name(), 
					$sformatf("Driving data bit[%0d] = %b", bit_index, byte_buffer[bit_index]), 
					UVM_HIGH)
			
			bit_count++;
		end
	endtask

	// Handle write data phase (slave receiving)
	protected task handle_write_data_phase();
		`uvm_info(get_type_name(), "Processing write transaction", UVM_HIGH)
		
		if (bit_count % 9 == 8) begin
			send_ack();  // ACK received byte
			`uvm_info(get_type_name(), "Write byte received and acknowledged", UVM_HIGH)
		end
		else wait(vif.scl_i);
		bit_count++;
	endtask

	// Send ACK by pulling SDA low for one clock cycle
	protected task send_ack();
		vif.sda_o <= 0;  // ACK by driving SDA low
		@(negedge vif.scl_i);
		vif.sda_o <= 1;  // Release SDA
	endtask

endclass

`endif
