/* 
* File: scoreboard.sv
*
* This file implements the scoreboard for checking AXI-Lite and I2C transactions.
*
* TODO:
* - Implement more sophisticated checking for multi-byte transfers
* - Add checks for I2C timing compliance
* - Consider using a more structured approach for expected transaction storage
*
* COMPLIANCE ISSUES:
* - The fixed slave address (7'h50) should be configurable
* - Error messages should use UVM macros consistently
* - Consider using separate classes for AXI and I2C transaction storage
*/
`ifndef SCOREBOARD
`define SCOREBOARD

class scoreboard extends uvm_scoreboard;
    `uvm_analysis_imp_decl(_axil)  // Add this line
    `uvm_analysis_imp_decl(_i2c)   // Add this line
    
    uvm_analysis_imp_axil #(axil_seq_item, scoreboard) axil_export;
    uvm_analysis_imp_i2c #(i2c_trans, scoreboard) i2c_export;
    
    i2c_trans expected_i2c_queue[$];
    bit [31:0] expected_seq[$];
	bit [6:0] current_slave;
    
    `uvm_component_utils(scoreboard)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axil_export = new("axil_export", this);
        i2c_export = new("i2c_export", this);
    endfunction
    
    function void write_axil(axil_seq_item item);

      `uvm_info("SCBD", $sformatf("Received AXI transaction: addr=%h data=%h read=%b strb=%h", 
                item.addr, item.data, item.read, item.strb), UVM_DEBUG)
        
        if (!item.read) begin // Write transaction
            if (item.addr == DATA_REG) begin
                // Create expected I2C write transaction
                i2c_trans expected = i2c_trans::type_id::create("expected");
                expected.addr = 7'h50; // Fixed slave address for now
                expected.read = 1'b0;  // Write transaction
                expected.data = item.data & 8'hFF; // Data byte
                expected_i2c_queue.push_back(expected);
                
                `uvm_info("SCBD", $sformatf("Queued expected I2C write transaction: addr=%h read=%b data=%h", 
                          expected.addr, expected.read, expected.data), UVM_MEDIUM)
			end 
			// else if ((item.addr == CMD_REG) & item.data[:])
            else if (item.addr == CMD_REG && (item.data[15] == 1'b1)) begin
                // Create expected I2C read transaction only if read bit is set
                i2c_trans expected = i2c_trans::type_id::create("expected");
                expected.addr = 7'h50; // Fixed slave address
                expected.read = 1'b1;  // Read transaction
                expected_i2c_queue.push_back(expected);
                
                `uvm_info("SCBD", $sformatf("Queued expected I2C read transaction: addr=%h read=%b", 
                          expected.addr, expected.read), UVM_MEDIUM)
            // TODO: Handle other register writes (CMD_REG, etc.)
            end
        end
        expected_seq.push_back(item.data);
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCBD", $sformatf("Total AXI transactions: %0d", expected_seq.size()), UVM_MEDIUM)
        `uvm_info("SCBD", $sformatf("Remaining expected I2C transactions: %0d", 
                  expected_i2c_queue.size()), UVM_MEDIUM)
        
        if(expected_i2c_queue.size() != 0) begin
            foreach(expected_i2c_queue[i]) begin
                `uvm_error("SCBD", $sformatf("Missing I2C transaction: %s", 
                          expected_i2c_queue[i].convert2string()))
            end
        end
    endfunction

    function void write_i2c(i2c_trans item);
        if(expected_i2c_queue.size() > 0) begin
            i2c_trans expected = expected_i2c_queue.pop_front();
            `uvm_info("SCBD", $sformatf("Comparing I2C transaction - Expected: %s, Got: %s",
                                       expected.convert2string(), item.convert2string()), UVM_MEDIUM)
            
            if(item.nack) begin
                `uvm_info("SCBD", "I2C NACK received - Transaction failed", UVM_MEDIUM)
                expected_i2c_queue.push_front(expected);
                return;
            end

            if(item.addr != expected.addr || item.read != expected.read || 
               (!item.read && item.data != expected.data)) begin
                `uvm_error("SCBD", $sformatf("I2C Mismatch! Expected: %s, Got: %s", 
                                           expected.convert2string(), item.convert2string()))
            end else begin
                `uvm_info("SCBD", "I2C transaction matched!", UVM_LOW)
            end
        end else begin
            `uvm_error("SCBD", $sformatf("Unexpected I2C transaction received: %s", 
                                        item.convert2string()))
        end
    endfunction
    
endclass

`endif
