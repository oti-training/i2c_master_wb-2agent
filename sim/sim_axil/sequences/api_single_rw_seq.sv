/* 
* File: api_single_rw_seq.sv
* 
* This file defines the api_single_rw_seq class, which is a UVM sequence for performing
* single read or write operations on the AXI-Lite interface of the I2C master.
*
* Key Features:
* - Extends uvm_sequence to create AXI-Lite transactions.
* - Provides methods for configuring and executing read/write operations on specific registers.
* - Implements helper tasks for common operations like writing command and data registers.
*
* TODO:
* - Consider implementing more robust error handling and reporting.
* - Add constraints to ensure valid address ranges and data values.
* - Implement a response checking mechanism to verify successful transactions.
*
* Notes on current implementation:
* - The use of a separate 'trans' object alongside 'req' is somewhat redundant and could be simplified.
* - The 'configure' task takes a sequencer as an argument, which is not a common UVM practice. 
*   Consider using the built-in `set_sequencer` method instead.
* - The hardcoded register addresses (CMD_REG, DATA_REG, etc.) should ideally be parameterized 
*   or defined in a central location for easier maintenance.
* - The class could benefit from more comprehensive comments explaining the purpose and usage 
*   of each task.
*/
`ifndef API_SINGLE_RW_SEQ
`define API_SINGLE_RW_SEQ

class api_single_rw_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(api_single_rw_seq)

	axil_seq_item trans;
	uvm_sequencer_base sequencer;

    function new(string name = "api_single_rw_seq");
        super.new(name);
    endfunction

    task body();
        req = axil_seq_item::type_id::create("req");
        start_item(req);
		req.randomize();
		if (!trans.read)
	        req.data = trans.data;
        req.read = trans.read;
        req.addr = trans.addr;
        req.strb = trans.strb;
        finish_item(req);
		get_response(rsp);
    endtask

	task configure(input uvm_sequencer_base seqr_in);
        trans = axil_seq_item::type_id::create("req");
		this.sequencer = seqr_in;
	endtask

	task start_write(input bit [3:0] reg_addr, input bit [31:0] data);
		trans.read = 0;
		trans.addr = reg_addr;
		trans.data = data;
		trans.strb = 4'b0011;
		start(sequencer);
	endtask

	task write_register_command(input bit [6:0] addr, input bit [4:0] flags);
		start_write(CMD_REG, {19'h0, flags, 1'b0, addr});
	endtask

	task write_register_data(input bit [7:0] data, input bit [1:0] flags);
		start_write(DATA_REG, {22'h0, flags, data});
	endtask

	task start_read(input bit [3:0] reg_addr);
		trans.read = 1;
		trans.addr = reg_addr;
		trans.strb = 4'b0011;
		start(sequencer);
	endtask

	task read_register_status();
		start_read(STATUS_REG);
	endtask

	task read_register_data();
		start_read(DATA_REG);
	endtask

endclass

`endif
