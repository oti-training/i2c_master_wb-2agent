`ifndef COVERAGE_CLASS
`define COVERAGE_CLASS

class wb8_i2c_coverage_collector extends uvm_component;

    // coverage groups
    // wishbone signals
    sequence_item_base_derived t;
    sequence_item_base t_primal;
    sequence_item wb_item;
    sequence_item_slave i2c_item;
    covergroup wb_cg;
        coverpoint wb_item.addr {
            bins wb_addr [] = {[0:7]};
        }
        coverpoint wb_item.data {
            bins wb_data [] = {[0:255]};
        }
        coverpoint wb_item.rw {
            bins wb_rw [] = {0,1};
        }
    endgroup
    // i2c signals
    covergroup i2c_cg;
        coverpoint i2c_item.addr {
            bins i2c_addr [] = {[0:255]};
        }
        coverpoint i2c_item.data {
            bins i2c_data [] = {[0:255]};
        }
        coverpoint i2c_item.rw {
            bins i2c_rw [] = {0,1};
        }
    endgroup

    // TLM FIFO (to receive data from multiple sources)
    uvm_tlm_analysis_fifo #(sequence_item_base) coverage_object_fifo;

    // register scoreboard to UVM factory
    `uvm_component_utils(wb8_i2c_coverage_collector)

    // default constructor
    function new (string name = "wb8_i2c_coverage_collector", uvm_component parent);
        super.new(name, parent);
        coverage_object_fifo = new("coverage_object_fifo", this);
        wb_cg = new();
        i2c_cg = new();
    endfunction

    // run phase
    task run_phase (uvm_phase phase);
        forever begin
            coverage_object_fifo.get(t_primal);
            if ($cast(wb_item, t_primal)) begin
                // Handle Wishbone-specific logic
                
                wb_cg.sample();
            end 
            else if ($cast(i2c_item, t_primal)) begin
                // Handle I2C-specific logic
                i2c_cg.sample();
            end
            else `uvm_error("ERROR", "ERROR DI COVERAGE WOY")
        end
    endtask
endclass

`endif