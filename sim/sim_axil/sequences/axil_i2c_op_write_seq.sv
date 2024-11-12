`ifndef AXIL_I2C_OP_WRITE_SEQ
`define AXIL_I2C_OP_WRITE_SEQ

class axil_i2c_op_write_seq extends master_i2c_op_base_seq;
    `uvm_object_utils(axil_i2c_op_write_seq)
	
	task body();
		axil_bus_seq api;
		api = axil_bus_seq::type_id::create("api");
		api.configure(m_sequencer);

		// address phase
		api.write_command(slave_addr, CMD_START | CMD_WR_M);

		// data phase
		repeat (payload_data_length-1) api.write_data(DATA_DEFAULT);	
		api.write_data(DATA_LAST);

		// stop
		api.write_command(slave_addr, CMD_STOP);
	endtask

    function new(string name = "axil_i2c_op_write_seq");
        super.new(name);
    endfunction

endclass

`endif
