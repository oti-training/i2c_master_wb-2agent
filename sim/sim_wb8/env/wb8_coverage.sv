/*
* File: wb8_coverage.sv
*
* This file defines the coverage collection for WB8 transactions.
*
* TODO:
* - Expand coverage to include more complex scenarios (e.g., back-to-back transactions)
* - Add functional coverage for specific DUT behaviors triggered by WB8 transactions
* - Consider implementing cross-coverage between WB8 and I2C transactions
*
* Improvement Opportunities:
* - The current coverage model is quite basic. It could benefit from more detailed bins
*   and cross-coverage between fields.
* - Consider adding coverage for protocol-specific sequences (e.g., write followed by read)
*/
`ifndef WB8_COVERAGE
`define WB8_COVERAGE

class wb8_coverage extends uvm_subscriber #(wb8_seq_item);
    `uvm_component_utils(wb8_coverage)
    
    covergroup wb8_cg;
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
    
    wb8_seq_item trans;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        wb8_cg = new();
    endfunction
    
    function void write(wb8_seq_item t);
        trans = t;
        wb8_cg.sample();
    endfunction
    // TODO: Implement report_phase to provide coverage summary
endclass

`endif
