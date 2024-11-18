/* 
* File: scoreboard.sv
*
* This file implements the scoreboard for checking AXI-Lite and I2C transactions.
*
* - Implement more sophisticated checking for multi-byte transfers
* - Add checks for I2C timing compliance
* - Consider using a more structured approach for expected transaction storage
*
* COMPLIANCE ISSUES:
* - Ref model should model timing for read delay
*/

`ifndef WB16_SCOREBOARD_SV 
`define WB16_SCOREBOARD_SV

class wb16_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(wb16_scoreboard)

	`uvm_analysis_imp_decl(_wb16_exp)
	`uvm_analysis_imp_decl(_wb16_act)
	`uvm_analysis_imp_decl(_i2c_exp)
	`uvm_analysis_imp_decl(_i2c_act)

	// Analysis imports
	uvm_analysis_imp_wb16_exp #(wb16_seq_item, wb16_scoreboard) wb16_exp_imp;
	uvm_analysis_imp_wb16_act #(wb16_seq_item, wb16_scoreboard) wb16_act_imp;
	uvm_analysis_imp_i2c_exp #(i2c_transaction, wb16_scoreboard) i2c_exp_imp;
	uvm_analysis_imp_i2c_act #(i2c_transaction, wb16_scoreboard) i2c_act_imp;

	// incoming transaction
	wb16_seq_item wb16_exp_queue[$], wb16_act_queue[$];
	i2c_transaction i2c_exp_queue[$], i2c_act_queue[$];

	// Error flag
	bit error;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		wb16_exp_imp = new("wb16_exp_imp", this);
		wb16_act_imp = new("wb16_act_imp", this);
		i2c_exp_imp = new("i2c_exp_imp", this);
		i2c_act_imp = new("i2c_act_imp", this);
	endfunction: build_phase

	// Analysis port write implementations
	function void write_wb16_exp(wb16_seq_item trans);
		`uvm_info(get_type_name(), {"Receive AXI-Lite Expected", trans.convert2string()}, UVM_HIGH);
		wb16_exp_queue.push_back(trans);
	endfunction

	function void write_wb16_act(wb16_seq_item trans);
		`uvm_info(get_type_name(), {"Receive AXI-Lite Actual", trans.convert2string()}, UVM_HIGH);
		wb16_act_queue.push_back(trans);
	endfunction

	function void write_i2c_exp(i2c_transaction trans);
		`uvm_info(get_type_name(), {"Receive I2C Expected", trans.convert2string()}, UVM_HIGH);
		i2c_exp_queue.push_back(trans);
	endfunction

	function void write_i2c_act(i2c_transaction trans);
		`uvm_info(get_type_name(), {"Receive I2C Actual", trans.convert2string()}, UVM_HIGH);
		i2c_act_queue.push_back(trans);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			// Wait for either AXI-Lite or I2C transactions to be available
			while(!((wb16_exp_queue.size() > 0 && wb16_act_queue.size() > 0) ||
					(i2c_exp_queue.size() > 0 && i2c_act_queue.size() > 0))) begin
						#1;
					end
			
			if (wb16_exp_queue.size() > 0 && wb16_act_queue.size() > 0) begin
				compare_wb16_trans();
			end
			if (i2c_exp_queue.size() > 0 && i2c_act_queue.size() > 0) begin
				compare_i2c_trans();
			end
		end
	endtask

	task compare_wb16_trans();
		wb16_seq_item exp_trans, act_trans;
		
		exp_trans = wb16_exp_queue.pop_front();
		act_trans = wb16_act_queue.pop_front();

		if (!exp_trans.compare_status(act_trans)) begin

			`uvm_error(get_type_name(), $sformatf(
				"AXI-Lite transaction mismatch:\nExpected:%s\nActual:%s",
				exp_trans.convert2string(), act_trans.convert2string()))
			
			error = 1;
		end else begin
			`uvm_info(get_type_name(), {"AXI-Lite transaction matched",
				act_trans.convert2string()}, UVM_MEDIUM)
		end
	endtask

	task compare_i2c_trans();
		i2c_transaction exp_trans, act_trans;
		
		exp_trans = i2c_exp_queue.pop_front();
		act_trans = i2c_act_queue.pop_front();

		if (!exp_trans.compare(act_trans)) begin
			`uvm_error(get_type_name(), $sformatf("I2C transaction mismatch:\nExpected:\n%s\nActual:\n%s", exp_trans.sprint(), act_trans.sprint()))
			error = 1;
		end else begin
			`uvm_info(get_type_name(), {"I2C transaction matched",
				act_trans.convert2string()}, UVM_MEDIUM)
		end
	endtask

	function void report_phase(uvm_phase phase);
		$display($sformatf("AXI-Lite queue: %0d/%0d\nI2C queue: %0d/%0d", wb16_act_queue.size(), wb16_exp_queue.size(), i2c_act_queue.size(), i2c_exp_queue.size()));
		if ((wb16_act_queue.size() != 0) ||(wb16_exp_queue.size() != 0)
		|| (i2c_act_queue.size() != 0) || (i2c_exp_queue.size() != 0)) begin
			`uvm_error(get_type_name(), $sformatf("Scoreboard queue not depleted"))
			error = 1;
		end
		if(error==0) begin
			$display("-------------------------------------------------");
			$display("------ INFO : TEST CASE PASSED ------------------");
			$display("-----------------------------------------");
		end else begin
			$display("---------------------------------------------------");
			$display("------ ERROR : TEST CASE FAILED ------------------");
			$display("---------------------------------------------------");
		end
	endfunction 
endclass

`endif
