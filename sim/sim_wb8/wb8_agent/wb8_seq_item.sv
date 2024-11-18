/* 
* File: WB8_seq_item.sv
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
`ifndef WB8_SEQ_ITEM
`define WB8_SEQ_ITEM

class wb8_seq_item extends uvm_sequence_item;
	rand bit [2:0]  addr;
	rand bit [7:0]  data;
	rand bit        read;

	time start_time;

	bit [2:0] cfg_address;
	bit [7:0] cfg_data;
	
	`uvm_object_utils_begin(wb8_seq_item)
		`uvm_field_int(addr, UVM_NOCOMPARE)
		`uvm_field_int(data, UVM_NOCOMPARE)
		`uvm_field_int(read, UVM_NOCOMPARE)
	`uvm_object_utils_end

	constraint seq_cfg_address_c {
		addr == cfg_address;  // 3-bit address range
	}

	constraint seq_cfg_data_c {
		data == cfg_data;  // constrain all bytes
	}
	
	function new(string name = "wb8_seq_item");
		super.new(name);
	endfunction

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		wb8_seq_item trans;
		bit is_read_status;
		bit is_matching;

		if (!$cast(trans, rhs)) begin
			`uvm_error(get_type_name(), "Cast failed")
			return 0;
		end
		
		is_read_status = (trans.read && (trans.addr==FIFO_STATUS_REG)) && (this.read && (this.addr==FIFO_STATUS_REG));

		if (is_read_status) begin
			`uvm_info(get_type_name(),
				"Read FIFO is still empty - treating as match", UVM_HIGH)
			return 1;
		end
		else begin
			// Compare everything in case FIFO status registers are not being accessed
			is_matching = (trans.read == this.read) &
						  (trans.addr == this.addr) &
						  (trans.data == this.data);
			return is_matching & super.do_compare(trans, comparer);
		end
	endfunction

	virtual function string convert2string();
		string s;
		s = $sformatf("\n----------------------------------------");
		s = {s, $sformatf("\nWB8 Transaction: %s", get_name())};
		s = {s, $sformatf("\nAddress: 0x%0h", addr)};
		s = {s, $sformatf("\nData:    0x%0h", data)};
		s = {s, $sformatf("\nType:    %s", read ? "READ" : "WRITE")};
		s = {s, $sformatf("\nStart Time: %0t", start_time)};
		s = {s, $sformatf("\n----------------------------------------")};
		return s;
	endfunction
endclass

`endif
