`ifndef AXIL_BUS_SEQ
`define AXIL_BUS_SEQ

class axil_bus_seq extends uvm_sequence #(axil_seq_item);
    `uvm_object_utils(axil_bus_seq)
	axil_seq_item req;
	bit is_write;
	uvm_sequencer_base sequencer;

    function new(string name = "axil_bus_seq");
        super.new(name);
        req = axil_seq_item::type_id::create("req");
    endfunction

    task body();
        start_item(req);
		if (!req.randomize() with {
			if (is_write) {
				req.read == 0;
				req.strb == 4'b0011;
			}
			else {
				req.read == 1;
				req.strb == 4'b0000;
			}
		})
			`uvm_error(get_type_name(), "Randomization failed")
		
        finish_item(req);
		get_response(rsp);
    endtask

	task configure(uvm_sequencer_base sequencer);
		this.sequencer = sequencer;
	endtask

	// write to data register
	task write_data(bit [1:0] flags);
		is_write = 1;
		req.seq_cfg_data_c.constraint_mode(0); // randomize first byte
		req.cfg_address = DATA_REG;
		req.cfg_data[9:8] = flags;
		start(sequencer);
		`uvm_info(get_type_name(), $sformatf("Write data register request %s", req.convert2string()), UVM_HIGH)
	endtask

	// write to command register
	task write_command(bit [6:0] slave_addr, bit [4:0] flags);
		is_write = 1;
		req.cfg_address = CMD_REG;
		req.cfg_data = {
			19'h0,
			flags,
			1'b0,
			slave_addr
		};
		start(sequencer);
	endtask

	// Check data register until it finds valid data
	task read_data_until_valid();
		is_write = 0;
		req.cfg_address = DATA_REG;
		do begin
			fork
				start(sequencer);
				#100;
			join
		end while ((rsp.data[9:8] & DATA_VALID) == 2'b00);
		`uvm_info(get_type_name(), $sformatf("Read data register response %s", rsp.convert2string()), UVM_HIGH)
	endtask

endclass

`endif
