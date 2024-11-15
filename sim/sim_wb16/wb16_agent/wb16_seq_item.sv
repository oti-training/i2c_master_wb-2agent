/* 
* File: WB16_seq_item.sv
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
`ifndef WB16_SEQ_ITEM
`define WB16_SEQ_ITEM

class wb16_seq_item extends uvm_sequence_item;
	rand bit [2:0]  addr;
	rand bit [15:0]  data;
	rand bit        read;

	bit [2:0] cfg_address;
	bit [15:0] cfg_data;
	
	`uvm_object_utils_begin(wb16_seq_item)
		`uvm_field_int(addr, UVM_ALL_ON)
		`uvm_field_int(data, UVM_ALL_ON)
		`uvm_field_int(read, UVM_ALL_ON)
	`uvm_object_utils_end

	constraint seq_cfg_address_c {
		addr == cfg_address;  // 3-bit address range
	}

	constraint seq_cfg_data_c {
		data == cfg_data;  // constrain all bytes
	}
	
	function new(string name = "wb16_seq_item");
		super.new(name);
	endfunction

	virtual function string convert2string();
		string s;
		s = $sformatf("\n----------------------------------------");
		s = {s, $sformatf("\nWB16 Transaction: %s", get_name())};
		s = {s, $sformatf("\nAddress: 0x%0h", addr)};
		s = {s, $sformatf("\nData:    0x%0h", data)};
		s = {s, $sformatf("\nType:    %s", read ? "READ" : "WRITE")};
		s = {s, $sformatf("\n----------------------------------------")};
		return s;
	endfunction
endclass

`endif
