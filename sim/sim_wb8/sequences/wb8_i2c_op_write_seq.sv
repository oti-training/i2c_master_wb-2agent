`ifndef WB8_I2C_OP_WRITE_SEQ
`define WB8_I2C_OP_WRITE_SEQ

class wb8_i2c_op_write_seq extends master_i2c_op_base_seq;
    `uvm_object_utils(wb8_i2c_op_write_seq)
	
	task body();
		wb8_bus_seq api;
		api = wb8_bus_seq::type_id::create("api");
		api.configure(m_sequencer);

		// address phase
		api.write_slaveaddr(slave_addr);
		api.write_command(CMD_START | CMD_WRITE);

		// data phase
		repeat (payload_data_length-1) begin 
			api.write_data;//(DATA_DEFAULT);	
			api.write_command(CMD_WRITE);
		end
		// api.write_data(DATA_LAST);

		// stop
		api.write_data;
		api.write_command(CMD_STOP);
	endtask

    function new(string name = "wb8_i2c_op_write_seq");
        super.new(name);
    endfunction

endclass

`endif
