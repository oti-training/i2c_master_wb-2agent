`ifndef WB16_BUS_SEQ
`define WB16_BUS_SEQ

class wb16_bus_seq extends uvm_sequence #(wb16_seq_item);
    `uvm_object_utils(wb16_bus_seq)
	wb16_seq_item req;
	bit is_write;
	bit [15:0] cmd_data;
	uvm_sequencer_base sequencer;

    function new(string name = "wb16_bus_seq");
        super.new(name);
        req = wb16_seq_item::type_id::create("req");
    endfunction

    task body();
        start_item(req);
		if (!req.randomize() with {
			req.read == !is_write;
		})
			`uvm_error(get_type_name(), "Randomization failed")
		
        finish_item(req);
		get_response(rsp);
    endtask

	task configure(uvm_sequencer_base sequencer);
		this.sequencer = sequencer;
	endtask

	// write to data register
	task write_data;//(bit [1:0] flags);
		is_write = 1;
		// req.seq_cfg_data_c.constraint_mode(0); // randomize first byte
		req.cfg_address = DATA_REG;
		// req.cfg_data[9:16] = flags;
		start(sequencer);
		`uvm_info(get_type_name(), $sformatf("Write data register request %s", req.convert2string()), UVM_LOW)
	endtask

	// write to command register
	task write_command(bit [4:0] command, bit [6:0] dev_addr);
		is_write		= 1;
		cmd_data [12:8]	= command;
		cmd_data [6:0]	= dev_addr;
		req.cfg_address = CMD_REG;
		req.cfg_data = {
			cmd_data
		};
		start(sequencer);
	endtask

	// write to slaveaddr register
	// task write_slaveaddr(bit [6:0] slave);
	// 	is_write = 1;
	// 	req.cfg_address = SLAVE_REG;
	// 	req.cfg_data = {
	// 		slave
	// 	};
	// 	start(sequencer);
	// endtask

	// Check data register until it finds valid data
	task read_data_until_valid();
		begin
		is_write = 0;
		// read status register
		req.cfg_address = FIFO_STATUS_REG;
		do begin
			start(sequencer);
		end while ((rsp.data[14]));
		// read data
		req.cfg_address = DATA_REG;
		start(sequencer);
		`uvm_info(get_type_name(), $sformatf("Read data register response %s", rsp.convert2string()), UVM_LOW)
		end
	endtask

endclass

`endif
