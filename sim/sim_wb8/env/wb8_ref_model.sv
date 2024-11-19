`ifndef WB8_REF_MODEL_SV
`define WB8_REF_MODEL_SV

class wb8_ref_model extends uvm_component;
	`uvm_component_utils(wb8_ref_model)
	
	//----------------------------------------------------------------------------
	// TLM Ports
	//----------------------------------------------------------------------------
	
	// inputs
	`uvm_analysis_imp_decl(_wb8)
	`uvm_analysis_imp_decl(_i2c)
	uvm_analysis_imp_wb8 #(wb8_seq_item, wb8_ref_model) wb8_imp;
	uvm_analysis_imp_i2c #(i2c_transaction, wb8_ref_model) i2c_imp;
	
	// outputs
	uvm_analysis_port#(wb8_seq_item) wb8_rm2sb_port;
	uvm_analysis_port#(i2c_transaction) i2c_rm2sb_port;

	//----------------------------------------------------------------------------
	// Input Queues
	//----------------------------------------------------------------------------
	
	protected wb8_seq_item wb8_queue[$];
	protected i2c_transaction i2c_queue[$];

	protected wb8_seq_item wb8_trans;
	protected i2c_transaction i2c_trans;

	//----------------------------------------------------------------------------
	// Class Properties
	//----------------------------------------------------------------------------

	// fifo buffer for wb8 to i2c read operations
	protected bit [7:0] read_data_queue[$];
	bit [6:0] slave_addr;

	// properties for the timing model
	protected time next_valid_read;

	// i2c transaction builder
	protected master_to_i2c_translator translator;

	//----------------------------------------------------------------------------
	// Methods
	//----------------------------------------------------------------------------

	function new(string name="wb8_ref_model", uvm_component parent);
		super.new(name, parent);
		wb8_rm2sb_port = new("wb8_rm2sb_port", this);
		i2c_rm2sb_port = new("i2c_rm2sb_port", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		wb8_imp = new("wb8_imp", this);
		i2c_imp = new("i2c_imp", this);
		translator = new("translator", this);
	endfunction

	//----------------------------------------------------------------------------
	// Analysis port write implementations
	//----------------------------------------------------------------------------

	function void write_wb8(wb8_seq_item trans);
		wb8_queue.push_back(trans);
	endfunction
	
	function void write_i2c(i2c_transaction trans);
		i2c_queue.push_back(trans);
	endfunction

	//----------------------------------------------------------------------------
	// Main Reference Model Process
	//----------------------------------------------------------------------------

	task run_phase(uvm_phase phase);
		forever begin
			wait ((wb8_queue.size() > 0) ||
				(translator.is_ready() && (i2c_queue.size() > 0)))
			
			if (wb8_queue.size() > 0) begin
				wb8_trans = wb8_queue.pop_front();
				`uvm_info(get_type_name(), {"Reference model receives wb8",
					wb8_trans.convert2string()}, UVM_HIGH)
				
				wb8_expected_transaction();
				
				wb8_rm2sb_port.write(wb8_trans);
				`uvm_info(get_type_name(), {"Reference model sends",
					wb8_trans.convert2string()}, UVM_MEDIUM)
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

	task wb8_expected_transaction();
		if (wb8_trans.read) begin
			case (wb8_trans.addr)
				FIFO_STATUS_REG: read_fifo_status();
				DATA_REG: read_data();
			endcase
		end
		else begin
			case (wb8_trans.addr)
				SLAVE_REG: write_slave_address();
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
		bit [4:0] flags = wb8_trans.data[4:0];

		// command to start i2c transaction
		if (flags & CMD_START) 
			handle_start_command(flags);
		else begin

		// command to read more bytes
		if (flags & CMD_READ) begin
			`uvm_info(get_type_name(), "Continue reading", UVM_HIGH)
			translator.add_read_byte(slave_addr);
		end else

		// command to end i2c transaction
		if (flags & CMD_STOP) begin
			`uvm_info(get_type_name(), "Stop bit detected", UVM_HIGH)
			translator.add_stop_bit();
		end
		end
	endtask

	// write slave address
	task write_slave_address();
		slave_addr = wb8_trans.data[6:0];
		translator.add_slave_addr(slave_addr);
	endtask

	// write to data register
	task write_data();
		// bit [1:0] flags = wb8_trans.data[9:8];

		`uvm_info(get_type_name(), $sformatf("Add to write queue %h",
			wb8_trans.data[7:0]), UVM_HIGH)
		translator.add_write_byte(wb8_trans.data[7:0]);

		// end of i2c write transaction
		// if (flags & DATA_LAST) begin
		// 	`uvm_info(get_type_name(), "Data is last", UVM_HIGH)
		// 	translator.add_stop_bit();
		// end
	endtask

	//----------------------------------------------------------------------------
	// AXI-Lite Register Reads
	//----------------------------------------------------------------------------

	task read_fifo_status();
		// todo: fix below
		bit [7:0] status = 0; 
		bit skip_first = 0;
		bit cmd_none = 1;
		foreach (wb8_queue[i]) begin
			if ((wb8_queue[i].addr == CMD_REG) && (wb8_queue[i].data & CMD_WRITE)) begin 
				cmd_none = 0;
				status |= 1 << 3;
				break;
			end
		end

		if (cmd_none) status |= 1 << 0;

		if (read_data_queue.size() > 0) status |= 1 << 6;

		wb8_trans.data = status;
	endtask

	// read data register
	task read_data();
		bit [7:0] data_from_i2c;

		`uvm_info(get_type_name(), $sformatf("start_time=%0d next_valid_read=%0d",
			wb8_trans.start_time, next_valid_read), UVM_HIGH)

		if (next_valid_read > wb8_trans.start_time) begin
			`uvm_info(get_type_name(), "Invalid read", UVM_HIGH)
			wb8_trans.data = {7'b0};
		end
		else begin
			`uvm_info(get_type_name(), "Valid read", UVM_HIGH)

			// todo: handle empty read queue
			assert(read_data_queue.size() > 0)
			else `uvm_fatal(get_type_name(),
				"Ref model has not implemented empty queue!")

			data_from_i2c = read_data_queue.pop_front();
			wb8_trans.data = {data_from_i2c};

			// todo: scale with prescaler register
			next_valid_read += 1010;
		end
	endtask

	//----------------------------------------------------------------------------
	// AXI-Lite Command Handlers
	//----------------------------------------------------------------------------

	task handle_start_command(bit [4:0] flags);
		// bit [6:0] slave_addr = wb8_trans.data[6:0];
		
		`uvm_info(get_type_name(), "Start bit detected", UVM_HIGH)

		translator.add_start_bit();
		// translator.add_slave_addr(slave_addr);
		
		// mark as a new i2c read transaction (1 byte)
		if (flags & CMD_READ)
			handle_start_read_command(slave_addr);

		// mark as a new i2c multiple write transaction (0 bytes)
		// TODO: implement single write command
		if (flags & CMD_WRITE) begin
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
		next_valid_read = wb8_trans.start_time + 1930;
	endtask

endclass

`endif