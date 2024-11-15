`ifndef WB16_I2C_OP_WRITE_SEQ
`define WB16_I2C_OP_WRITE_SEQ

class wb16_i2c_op_write_seq extends master_i2c_op_base_seq;
    `uvm_object_utils(wb16_i2c_op_write_seq)
	
	task body();
		wb16_bus_seq api;
		api = wb16_bus_seq::type_id::create("api");
		api.configure(m_sequencer);

		// address phase
		// api.write_slaveaddr(slave_addr);
		api.write_command(CMD_START | CMD_WRITE , slave_addr);

		// data phase
		repeat (payload_data_length-1) begin 
			api.write_data;//(DATA_DEFAULT);	
			api.write_command(CMD_WRITE , slave_addr);
		end
		// api.write_data(DATA_LAST);

		// stop
		api.write_data;
		api.write_command(CMD_STOP , slave_addr );
	endtask

    function new(string name = "wb16_i2c_op_write_seq");
        super.new(name);
    endfunction

endclass

`endif
