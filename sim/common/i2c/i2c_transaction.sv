//------------------------------------------------------------------------------
// File: i2c_transaction.sv
// Description: UVM sequence item for AXI-Lite I2C transactions
//
// This sequence item models I2C transactions for verification of an I2C slave
// interface. It supports both read and write operations with configurable
// address and data payload. The class includes constraints to ensure valid
// configuration options for testing.
//
// Usage:
//   - Create and configure instances for I2C transaction scenarios
//   - Used by sequences to generate stimulus for I2C slave verification
//   - Supports configuration through external parameters
//------------------------------------------------------------------------------

`ifndef I2C_TRANSACTION_SV
`define I2C_TRANSACTION_SV

class i2c_transaction extends uvm_sequence_item;
    //--------------------------------------------------------------------------
    // Transaction Properties
    //--------------------------------------------------------------------------
    
    // Target I2C slave address (7-bit)
    rand bit [6:0] slave_addr;
    
    // Transaction data payload
    rand bit [7:0] payload_data[$];
    
    // Transaction direction flag
    rand bit is_write;
    
    //--------------------------------------------------------------------------
    // Configuration Parameters
    //--------------------------------------------------------------------------
    
    // External configuration for address matching
    bit [6:0] cfg_slave_addr;
    
    // External configuration for expected data length
    int cfg_payload_length;
    
    //--------------------------------------------------------------------------
    // UVM Automation Macros
    //--------------------------------------------------------------------------
    
    `uvm_object_utils_begin(i2c_transaction)
        `uvm_field_int(slave_addr, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_queue_int(payload_data, UVM_ALL_ON)
    `uvm_object_utils_end
    
    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------
    
    // Limit payload size to prevent unrealistic test scenarios
    constraint c_payload_size {
        payload_data.size() inside {[0:32]};
    }
    
    // Force slave address to match configuration
    constraint c_cfg_slave_addr {
        slave_addr == cfg_slave_addr;
    }
    
    // Force payload length to match configuration
    constraint c_cfg_payload_length {
        payload_data.size() == cfg_payload_length;
    }
    
    //--------------------------------------------------------------------------
    // Methods
    //--------------------------------------------------------------------------
    
    // Constructor
    function new(string name = "i2c_transaction");
        super.new(name);
    endfunction

	// Convert transaction to string representation
	function string convert2string();
		string s;
		s = $sformatf("\n----------------------------------------");
		s = {s, $sformatf("\nI2C Transaction: %s", get_name())};
		s = {s, $sformatf("\nSlave Address: 0x%0h (%0d)", slave_addr, slave_addr)};
		s = {s, $sformatf("\nOperation: %s", is_write ? "WRITE" : "READ")};
		s = {s, $sformatf("\nPayload Length: %0d bytes", payload_data.size())};
		
		if (payload_data.size() > 0) begin
			s = {s, "\nPayload Data (hex):"};
			for (int i = 0; i < payload_data.size(); i++) begin
				if (i % 8 == 0) s = {s, "\n"};
				s = {s, $sformatf(" %02h", payload_data[i])};
			end
		end
		
		s = {s, "\n----------------------------------------\n"};
		return s;
	endfunction

endclass

`endif // AXIL_I2C_SEQ_ITEM_SV