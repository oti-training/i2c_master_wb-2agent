`ifndef COVERAGE_CLASS
`define COVERAGE_CLASS

class wb16_i2c_coverage_collector extends uvm_component;

    // Coverage groups
    covergroup wb_cg;
        wb_addr: coverpoint wb_item.addr {
            bins wb_addr[] = {[0:7]};
        }
        wb_data: coverpoint wb_item.data {
            bins wb_data[] = {[0:255]};
        }
        wb_rw: coverpoint wb_item.rw {
            bins wb_rw[] = {0,1};
        }
    endgroup

    covergroup i2c_cg;
        i2c_addr: coverpoint i2c_item.addr {
            bins i2c_addr[] = {[0:255]};
        }
        i2c_data: coverpoint i2c_item.data {
            bins i2c_data[] = {[0:255]};
        }
        i2c_rw: coverpoint i2c_item.rw {
            bins i2c_rw[] = {0,1};
        }
    endgroup

    // Sequence items
    sequence_item_base t_primal;
    sequence_item wb_item;
    sequence_item_slave i2c_item;

    // TLM FIFO
    uvm_tlm_analysis_fifo #(sequence_item_base) coverage_object_fifo;

    // Register coverage collector to UVM factory
    `uvm_component_utils(wb16_i2c_coverage_collector)

    // Constructor
    function new(string name = "wb16_i2c_coverage_collector", uvm_component parent);
        super.new(name, parent);
        coverage_object_fifo = new("coverage_object_fifo", this);
        wb_cg = new();
        i2c_cg = new();
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
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
            else `uvm_error("COVERAGE_ERROR", "Received unknown transaction type")
        end
    endtask

    // Final phase
    function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        
        // Display coverage for wb_cg
        $display("Wishbone Coverage:");
        $display("  Overall coverage: %0f%%", wb_cg.get_coverage());
        $display("  Address coverage: %0f%%", wb_cg.wb_addr.get_coverage());
        $display("  Data coverage: %0f%%", wb_cg.wb_data.get_coverage());
        $display("  Read/Write coverage: %0f%%", wb_cg.wb_rw.get_coverage());
        
        // Display coverage for i2c_cg
        $display("I2C Coverage:");
        $display("  Overall coverage: %0f%%", i2c_cg.get_coverage());
        $display("  Address coverage: %0f%%", i2c_cg.i2c_addr.get_coverage());
        $display("  Data coverage: %0f%%", i2c_cg.i2c_data.get_coverage());
        $display("  Read/Write coverage: %0f%%", i2c_cg.i2c_rw.get_coverage());
    endfunction

endclass

`endif
