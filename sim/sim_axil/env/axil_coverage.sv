/*
* File: axil_coverage.sv
*
* This file defines the coverage collection for AXI-Lite transactions.
*
* TODO:
* - Expand coverage to include more complex scenarios (e.g., back-to-back transactions)
* - Add functional coverage for specific DUT behaviors triggered by AXI-Lite transactions
* - Consider implementing cross-coverage between AXI-Lite and I2C transactions
*
* Improvement Opportunities:
* - The current coverage model is quite basic. It could benefit from more detailed bins
*   and cross-coverage between fields.
* - Consider adding coverage for protocol-specific sequences (e.g., write followed by read)
*/
`ifndef AXIL_COVERAGE
`define AXIL_COVERAGE

class axil_coverage extends uvm_subscriber #(axil_seq_item);
    `uvm_component_utils(axil_coverage)
    
    covergroup axil_cg;
        addr_cp: coverpoint trans.addr {
            bins data = {DATA_REG};
            bins status = {STATUS_REG};
            bins prescale = {PRESCALE_REG};
            bins command = {CMD_REG};
        }
        
        direction_cp: coverpoint trans.read;
        
        // TODO: Add coverage for data values, especially for command register

        addr_dir_cross: cross addr_cp, direction_cp;
        // TODO: Add cross coverage with data values for write transactions
    endgroup
    
    axil_seq_item trans;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axil_cg = new();
    endfunction
    
    function void write(axil_seq_item t);
        trans = t;
        axil_cg.sample();
    endfunction
    // TODO: Implement report_phase to provide coverage summary
endclass

`endif
