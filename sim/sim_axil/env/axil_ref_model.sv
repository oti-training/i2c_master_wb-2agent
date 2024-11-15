`ifndef AXIL_REF_MODEL_SV
`define AXIL_REF_MODEL_SV

class axil_ref_model extends uvm_component;
	`uvm_component_utils(axil_ref_model)
	
	//----------------------------------------------------------------------------
	// TLM Ports
	//----------------------------------------------------------------------------
	
	// inputs
	`uvm_analysis_imp_decl(_axil)
	`uvm_analysis_imp_decl(_i2c)
	uvm_analysis_imp_axil #(axil_seq_item, axil_ref_model) axil_imp;
	uvm_analysis_imp_i2c #(i2c_transaction, axil_ref_model) i2c_imp;
	
	// outputs
	uvm_analysis_port#(axil_seq_item) axil_rm2sb_port;
	uvm_analysis_port#(i2c_transaction) i2c_rm2sb_port;

	//----------------------------------------------------------------------------
	// Input Queues
	//----------------------------------------------------------------------------
	
	protected axil_seq_item axil_queue[$];
	protected i2c_transaction i2c_queue[$];

	protected axil_seq_item axil_trans;
	protected i2c_transaction i2c_trans;

	//----------------------------------------------------------------------------
	// Class Properties
	//----------------------------------------------------------------------------

	// fifo buffer for axil to i2c read operations
	protected bit [7:0] read_data_queue[$];

	// properties for the timing model
	protected time next_valid_read;

	// i2c transaction builder
	protected master_to_i2c_translator translator;

	//----------------------------------------------------------------------------
	// Methods
	//----------------------------------------------------------------------------

	function new(string name="axil_ref_model", uvm_component parent);
		super.new(name, parent);
		axil_rm2sb_port = new("axil_rm2sb_port", this);
		i2c_rm2sb_port = new("i2c_rm2sb_port", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		axil_imp = new("axil_imp", this);
		i2c_imp = new("i2c_imp", this);
		translator = new("translator", this);
	endfunction

	//----------------------------------------------------------------------------
	// Analysis port write implementations
	//----------------------------------------------------------------------------

	function void write_axil(axil_seq_item trans);
		axil_queue.push_back(trans);
	endfunction
	
	function void write_i2c(i2c_transaction trans);
		i2c_queue.push_back(trans);
	endfunction

	//----------------------------------------------------------------------------
	// Main Reference Model Process
	//----------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
		forever begin
			wait ((axil_queue.size() > 0) ||
				(translator.is_ready() && (i2c_queue.size() > 0)))
			
			if (axil_queue.size() > 0) begin
				axil_trans = axil_queue.pop_front();
				`uvm_info(get_type_name(), {"Reference model receives axil",
					axil_trans.convert2string()}, UVM_HIGH)
				
				axil_expected_transaction();
				
				axil_rm2sb_port.write(axil_trans);
				`uvm_info(get_type_name(), {"Reference model sends",
					axil_trans.convert2string()}, UVM_MEDIUM)
			end

			if (translator.is_ready() && (i2c_queue.size() > 0)) begin
				i2c_trans = i2c_queue.pop_front();
				`uvm_info(get_type_name(), {"Reference model receives i2c",
					i2c_trans.convert2string()}, UVM_HIGH)

				i2c_expected_transaction();
				
				i2c_rm2sb_port.write(i2c_trans);
				`uvm_info(get_type_name(), {"Reference model sends",
					i2c_trans.convert2string()}, UVM_MEDIUM)
			end

		end
	endtask

	//----------------------------------------------------------------------------
	// Task for processing transactions
	//----------------------------------------------------------------------------

	task axil_expected_transaction();
		if (axil_trans.read) begin
			case (axil_trans.addr)
				DATA_REG: read_data();
			endcase
		end
		else begin
			case (axil_trans.addr)
				CMD_REG: write_command();
				DATA_REG: write_data();
			endcase
		end
	endtask
	
	task i2c_expected_transaction();
		i2c_trans = translator.get_transaction(i2c_trans);

		if (!i2c_trans.is_write) begin
			// Copy payload to internal queue
			foreach(i2c_trans.payload_data[i]) begin
				read_data_queue.push_back(i2c_trans.payload_data[i]);
			end
		end
	endtask

	//----------------------------------------------------------------------------
	// AXI-Lite Register Writes
	//----------------------------------------------------------------------------

	// write to command register
	task write_command();
		bit [4:0] flags = axil_trans.data[12:8];

		// command to start i2c transaction
		if (flags & CMD_START) 
			handle_start_command(flags);
		else begin

		// command to read more bytes
		if (flags & CMD_READ) begin
			`uvm_info(get_type_name(), "Continue reading", UVM_HIGH)
			translator.add_read_byte(axil_trans.data[6:0]);
		end else

		// command to end i2c transaction
		if (flags & CMD_STOP) begin
			`uvm_info(get_type_name(), "Stop bit detected", UVM_HIGH)
			translator.add_stop_bit();
		end
		end
	endtask

	// write to data register
	task write_data();
		bit [1:0] flags = axil_trans.data[9:8];

		`uvm_info(get_type_name(), $sformatf("Add to write queue %h",
			axil_trans.data[15:0]), UVM_HIGH)
		translator.add_write_byte(axil_trans.data[7:0]);

		// end of i2c write transaction
		if (flags & DATA_LAST) begin
			`uvm_info(get_type_name(), "Data is last", UVM_HIGH)
			translator.add_stop_bit();
		end
	endtask

	//----------------------------------------------------------------------------
	// AXI-Lite Register Reads
	//----------------------------------------------------------------------------

	// read data register
	task read_data();
		bit [7:0] data_from_i2c;

		`uvm_info(get_type_name(), $sformatf("start_time=%0d next_valid_read=%0d",
			axil_trans.start_time, next_valid_read), UVM_HIGH)

		if (next_valid_read > axil_trans.start_time) begin
			`uvm_info(get_type_name(), "Invalid read", UVM_HIGH)
			axil_trans.data = {22'h0, 2'b00, 8'h00};
		end
		else begin
			`uvm_info(get_type_name(), "Valid read", UVM_HIGH)

			// todo: handle empty read queue
			assert(read_data_queue.size() > 0)
			else `uvm_fatal(get_type_name(),
				"Ref model has not implemented empty queue!")

			data_from_i2c = read_data_queue.pop_front();
			axil_trans.data = {22'h0, DATA_VALID, data_from_i2c};

			// todo: scale with prescaler register
			next_valid_read += 1010;
		end
	endtask

	//----------------------------------------------------------------------------
	// AXI-Lite Command Handlers
	//----------------------------------------------------------------------------

	task handle_start_command(bit [4:0] flags);
		bit [6:0] slave_addr = axil_trans.data[6:0];
		
		`uvm_info(get_type_name(), "Start bit detected", UVM_HIGH)

		translator.add_start_bit();
		translator.add_slave_addr(slave_addr);
		
		// mark as a new i2c read transaction (1 byte)
		if (flags & CMD_READ)
			handle_start_read_command(slave_addr);

		// mark as a new i2c multiple write transaction (0 bytes)
		// TODO: implement single write command
		if (flags & CMD_WR_M) begin
			`uvm_info(get_type_name(), $sformatf("Starting a new write for %h",
				slave_addr), UVM_HIGH)
			translator.add_direction(1);
		end
	endtask

	task handle_start_read_command(input bit [6:0] slave_addr);
		`uvm_info(get_type_name(), $sformatf("Starting a new read for %h",
			slave_addr), UVM_HIGH)

		translator.add_direction(0);
		translator.add_read_byte(slave_addr);

		// TODO: Scale with prescaler register
		next_valid_read = axil_trans.start_time + 1930;
	endtask

endclass

`endif