/*
* File: wb16_coverage.sv
*
* This file defines the coverage collection for WB16 transactions.
*
* TODO:
* - Expand coverage to include more complex scenarios (e.g., back-to-back transactions)
* - Add functional coverage for specific DUT behaviors triggered by WB16 transactions
* - Consider implementing cross-coverage between WB16 and I2C transactions
*
* Improvement Opportunities:
* - The current coverage model is quite basic. It could benefit from more detailed bins
*   and cross-coverage between fields.
* - Consider adding coverage for protocol-specific sequences (e.g., write followed by read)
*/
`ifndef WB16_COVERAGE
`define WB16_COVERAGE

class wb16_coverage extends uvm_subscriber #(wb16_seq_item);
    `uvm_component_utils(wb16_coverage)
    
    covergroup wb16_cg;
        addr_cp: coverpoint trans.addr {
            bins data = {DATA_REG};
            // bins status = {STATUS_REG};
            bins prescale = {PRESCALE_REG};
            bins command = {CMD_REG};
        }
        
        direction_cp: coverpoint trans.read;
        
        // TODO: Add coverage for data values, especially for command register

        addr_dir_cross: cross addr_cp, direction_cp;
        // TODO: Add cross coverage with data values for write transactions
    endgroup
    
    wb16_seq_item trans;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        wb16_cg = new();
    endfunction
    
    function void write(wb16_seq_item t);
        trans = t;
        wb16_cg.sample();
    endfunction
    // TODO: Implement report_phase to provide coverage summary
endclass

`endif