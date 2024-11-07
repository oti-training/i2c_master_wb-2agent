/* 
* File: memory_slave_seq.sv
* 
* This file defines the memory_slave_seq class, which simulates I2C slave behavior
* for read and write operations.
*
* TODO:
* - Implement proper error handling for timeouts and unexpected responses
* - Consider adding randomization to simulate more realistic I2C slave behavior
* - Refactor to improve code reuse between read and write operations
*
* NOTE: This implementation directly accesses sequencer, which might not be the best 
* practice for maintainability. Consider using a more standardized approach for 
* starting sequences.
*/
`ifndef MEMORY_SLAVE_SEQ
`define MEMORY_SLAVE_SEQ

class memory_slave_seq extends uvm_sequence #(axil_seq_item);
	uvm_sequencer_base sequencer;
    bit is_write;
    bit [6:0] slave_address;
	bit [7:0] register_address, data;
    
	`uvm_object_utils(memory_slave_seq)
    
    function new(string name = "memory_slave_seq");
        super.new(name);
    endfunction

    task body();
		api_single_rw_seq api_rw_seq = api_single_rw_seq::type_id::create("req");
		int timeout_count = 0;

		api_rw_seq.configure(m_sequencer);
        
		if (is_write) begin
			`uvm_info("SEQ", $sformatf("Sending I2C write command: slave=%h reg=%h data=%h", slave_address, register_address, data), UVM_LOW)
			
      // TODO: Consider encapsulating this sequence of operations into a separate method
			api_rw_seq.write_register_command(slave_address,
				CMD_START | CMD_WR_M); // address and start
			api_rw_seq.write_register_data(register_address, DATA_DEFAULT); // register 0
			api_rw_seq.write_register_data(data, DATA_LAST); // for write_multiple
			api_rw_seq.write_register_command(7'h0, CMD_STOP); // stop
		end
		else begin
			`uvm_info("SEQ", $sformatf("Sending I2C read command: slave=%h reg=%h", slave_address, register_address), UVM_LOW);

      // TODO: Implement proper error handling for timeouts
			api_rw_seq.write_register_command(slave_address, CMD_START | CMD_WRITE | CMD_STOP);
			api_rw_seq.write_register_data(register_address, DATA_LAST); // register 0
			api_rw_seq.write_register_command(slave_address, CMD_START | CMD_READ | CMD_STOP);

			repeat(10) begin
				#1000
				api_rw_seq.read_register_data(); // register 0
				if (api_rw_seq.rsp.data[9:8] & DATA_VALID) break;
			end
			rsp = api_rw_seq.rsp;
			data = rsp.data[7:0];
		end
    endtask

	task configure(
		input uvm_sequencer_base sequencer,
		input bit [6:0] slave_address
		);

		this.sequencer = sequencer;
		this.slave_address = slave_address;
	endtask

	task register_write(
		input bit [7:0] register_address,
		input bit [7:0] data
		);

		is_write = 1;
		this.register_address = register_address;
		this.data = data;
		start(sequencer);
	endtask

	task register_read(
		input bit [7:0] register_address
		);

		is_write = 0;
		this.register_address = register_address;
		start(sequencer);
		this.data = rsp.data;
	endtask
endclass

`endif
