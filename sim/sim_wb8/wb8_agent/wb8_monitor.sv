/*
* File: axil_monitor.sv
*
* This file defines the AXI-Lite monitor component for the verification environment.
* The monitor observes transactions on the AXI-Lite interface and broadcasts them
* to other components in the testbench via analysis ports.
*
* Key Features:
* - Implements the UVM monitor class for AXI-Lite protocol.
* - Captures both read and write transactions on the AXI-Lite bus.
* - Uses a virtual interface to access DUT signals.
* - Broadcasts observed transactions through an analysis port.
*
* TODO:
* - Implement configurable verbosity levels for transaction reporting.
* - Add checks for AXI-Lite protocol compliance (e.g., handshake timing).
* - Consider separating read and write transaction monitoring for better modularity.
*
* NOTE: This implementation could benefit from some improvements:
* - Error handling and corner cases could be more robust.
* - Consider adding coverage collection directly in the monitor.
*/
`ifndef WB8_MONITOR
`define WB8_MONITOR

class wb8_monitor extends uvm_monitor;
    virtual wb8_if vif;
    uvm_analysis_port #(wb8_seq_item) ap;
    
    `uvm_component_utils(wb8_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual wb8_if)::get(this, "", "wb8_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            collect_transaction;
            // ap.write(tr);
        end
    endtask

    task collect_transaction;
        // initialize transaction as invalid
        bit txn_valid = 0;
        // error mitigation counter
        int counter;
        // transaction level object item for output
        wb8_seq_item tr = wb8_seq_item::type_id::create("tr");
        // wait for start cycle
        wait(vif.wbs_cyc_i);
        // get ack or terminate if nack
        for (counter=0; counter<20; counter=counter+1) begin
            // wishbone is acknowledged
            if (vif.wbs_ack_o) begin
                txn_valid = 1;
                // check operation mode
                #1; tr.read = ~vif.wbs_we_i;
                // retrieve address and data
                tr.addr = vif.wbs_adr_i;
                if (tr.read == 1) tr.data = vif.wbs_dat_o;
                else tr.data = vif.wbs_dat_i;
                break; // break from the ack wait
            end
            @(vif.clk);
        end

        // only if we get a valid data that was acknowledged
        if (txn_valid == 1) begin
            // wait until cycle done
            for (counter=0; counter<20; counter=counter+1) begin
                // transfer cycle is done
                if (vif.wbs_cyc_i==0) begin
                    txn_valid = 1;
                    break;
                end
                // transfer cycle not done, wait for another cycle
                txn_valid = 0;
                @(vif.clk);
            end
        end

        if (txn_valid) begin
            // send the data through the analysis port
            ap.write(tr);
        end
    endtask
    // TODO: Add coverage collection method
    // function void collect_coverage(wb8_seq_item item);
    //     // Implement coverage collection logic here
    // endfunction

    // TODO: Add method to check for protocol violations
    // function void check_protocol_compliance(wb8_seq_item item);
    //     // Implement protocol checking logic here
    // endfunction
endclass

`endif
