/* 
* File: axil_seq_item.sv
*
* This file defines the AXI-Lite sequence item, which represents a single AXI-Lite transaction.
* 
* Key Features:
* - Extends uvm_sequence_item for use in UVM sequences and drivers.
* - Defines fields for AXI-Lite address, data, write strobe, and read/write indicator.
* - Implements UVM automation macros for easy field access and manipulation.
* - Includes a constraint to limit address values.
*
* TODO:
* - Consider adding more sophisticated constraints for realistic AXI-Lite behavior.
* - Implement a proper print() method for better debug output.
* - Add methods for easier data manipulation (e.g., set_byte(), get_byte()).
*
* Notes:
* - The current implementation uses a 4-bit address, which may not be sufficient
*   for all use cases. Consider parameterizing the address width for more flexibility.
* - The use of rand for all fields might lead to unnecessary randomization overhead.
*   Consider making some fields non-rand if they're always explicitly set.
* - The addr_c constraint might be too restrictive. Ensure it aligns with the 
*   actual register map of the DUT.
*/
`ifndef AXIL_SEQ_ITEM
`define AXIL_SEQ_ITEM

class axil_seq_item extends uvm_sequence_item;
	rand bit [3:0]  addr;
	rand bit [31:0] data;
	rand bit [3:0]  strb;
	rand bit        read;

	time start_time;

	bit [3:0] cfg_address;
	bit [31:0] cfg_data;
	
	`uvm_object_utils_begin(axil_seq_item)
		`uvm_field_int(addr, UVM_ALL_ON)
		`uvm_field_int(data, UVM_ALL_ON)
		`uvm_field_int(strb, UVM_ALL_ON)
		`uvm_field_int(read, UVM_ALL_ON)
	`uvm_object_utils_end

	constraint seq_cfg_address_c {
		addr == cfg_address;  // 7-bit address range
	}

	constraint seq_cfg_data_c {
		data == cfg_data;  // constrain all bytes
	}

	constraint seq_cfg_data_0_c {
		data[15:8] == cfg_data[15:8];  // constrain 2nd byte
	}
	
	function new(string name = "axil_seq_item");
		super.new(name);
	endfunction

	// if both read data is invalid, exempt from comparison
	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		axil_seq_item trans;
		bit is_invalid_read_data_reg;
		
		if (!$cast(trans, rhs)) begin
			`uvm_error(get_type_name(), "Cast failed")
			return 0;
		end
		
		// Check our special case first
		is_invalid_read_data_reg =
			!(trans.data[15:8] & DATA_VALID) && trans.read && (trans.addr==DATA_REG) &&
			!(this.data[15:8] & DATA_VALID) && this.read && (this.addr==DATA_REG);
			
		if (is_invalid_read_data_reg) begin
			`uvm_info(get_type_name(),
				"Invalid read data reg detected - treating as match", UVM_HIGH)
			// Clear any miscompares that may have been recorded
			comparer.result = 0;
			comparer.miscompares = "";
			return 1;
		end
		
		// Not our special case, do normal comparison
		return super.do_compare(rhs, comparer);
	endfunction

	virtual function string convert2string();
		string s;
		s = $sformatf("\n----------------------------------------");
		s = {s, $sformatf("\nAXI-Lite Transaction: %s", get_name())};
		s = {s, $sformatf("\nAddress: 0x%0h", addr)};
		s = {s, $sformatf("\nData:    0x%0h", data)};
		s = {s, $sformatf("\nStrobe:  0x%0h", strb)};
		s = {s, $sformatf("\nType:    %s", read ? "READ" : "WRITE")};
		s = {s, $sformatf("\nStart Time: %0t", start_time)};
		s = {s, $sformatf("\n----------------------------------------")};
		return s;
	endfunction
endclass

`endif
