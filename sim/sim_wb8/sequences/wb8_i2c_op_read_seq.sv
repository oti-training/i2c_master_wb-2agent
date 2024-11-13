`ifndef WB8_I2C_OP_READ_SEQ
`define WB8_I2C_OP_READ_SEQ

class wb8_i2c_op_read_seq extends master_i2c_op_base_seq;
    `uvm_object_utils(wb8_i2c_op_read_seq)

	task body();
		wb8_bus_seq api;
		api = wb8_bus_seq::type_id::create("api");
		api.configure(m_sequencer);

		// address phase and first byte	
		api.write_slaveaddr(slave_addr);
		api.write_command(CMD_START | CMD_READ);

		// rest of the bytes
		repeat (payload_data_length-1) begin
			api.write_command(CMD_READ);
		end

		// stop
		api.write_command(CMD_STOP);

		// read register
		repeat (payload_data_length)
			api.read_data_until_valid();
	endtask

    function new(string name = "wb8_i2c_op_read_seq");
        super.new(name);
    endfunction
endclass

`endif
