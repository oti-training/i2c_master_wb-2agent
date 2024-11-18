/* 
* File: scoreboard.sv
*
* This file implements the scoreboard for checking AXI-Lite/Wishbone
* and I2C transactions.
*
* - Implement more sophisticated checking for multi-byte transfers
* - Add checks for I2C timing compliance
* - Consider using a more structured approach for expected transaction storage
*
* COMPLIANCE ISSUES:
* - Ref model should model timing for read delay
*/

`ifndef SCOREBOARD_SV 
`define SCOREBOARD_SV

class scoreboard #(type T=uvm_sequence_item) extends uvm_scoreboard;
	`uvm_component_utils(scoreboard#(T))

	`uvm_analysis_imp_decl(_master_exp)
	`uvm_analysis_imp_decl(_master_act)
	`uvm_analysis_imp_decl(_i2c_exp)
	`uvm_analysis_imp_decl(_i2c_act)

	// Analysis imports
	uvm_analysis_imp_master_exp #(T, scoreboard#(T)) master_exp_imp;
	uvm_analysis_imp_master_act #(T, scoreboard#(T)) master_act_imp;
	uvm_analysis_imp_i2c_exp #(i2c_transaction, scoreboard#(T)) i2c_exp_imp;
	uvm_analysis_imp_i2c_act #(i2c_transaction, scoreboard#(T)) i2c_act_imp;

	// incoming transaction
	T master_exp_queue[$], master_act_queue[$];
	i2c_transaction i2c_exp_queue[$], i2c_act_queue[$];

	// Error flag
	bit error;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		master_exp_imp = new("master_exp_imp", this);
		master_act_imp = new("master_act_imp", this);
		i2c_exp_imp = new("i2c_exp_imp", this);
		i2c_act_imp = new("i2c_act_imp", this);
	endfunction: build_phase

	// Analysis port write implementations
	function void write_master_exp(T trans);
		`uvm_info(get_type_name(), {"Receive Master Expected", trans.convert2string()}, UVM_HIGH);
		master_exp_queue.push_back(trans);
	endfunction

	function void write_master_act(T trans);
		`uvm_info(get_type_name(), {"Receive Master Actual", trans.convert2string()}, UVM_HIGH);
		master_act_queue.push_back(trans);
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
			// Wait for either Master or I2C transactions to be available
			while(!((master_exp_queue.size() > 0 && master_act_queue.size() > 0) ||
					(i2c_exp_queue.size() > 0 && i2c_act_queue.size() > 0))) begin
						#1;
					end
			
			if (master_exp_queue.size() > 0 && master_act_queue.size() > 0) begin
				compare_master_trans();
			end
			if (i2c_exp_queue.size() > 0 && i2c_act_queue.size() > 0) begin
				compare_i2c_trans();
			end
		end
	endtask

	task compare_master_trans();
		T exp_trans, act_trans;
		
		exp_trans = master_exp_queue.pop_front();
		act_trans = master_act_queue.pop_front();

		if (!exp_trans.compare(act_trans)) begin

			`uvm_error(get_type_name(), $sformatf(
				"Master transaction mismatch:\nExpected:%s\nActual:%s",
				exp_trans.convert2string(), act_trans.convert2string()))
			
			error = 1;
		end else begin
			`uvm_info(get_type_name(), {"Master transaction matched",
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
		$display($sformatf("Master queue: %0d/%0d\nI2C queue: %0d/%0d", master_act_queue.size(), master_exp_queue.size(), i2c_act_queue.size(), i2c_exp_queue.size()));
		if ((master_act_queue.size() != 0) ||(master_exp_queue.size() != 0)
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
