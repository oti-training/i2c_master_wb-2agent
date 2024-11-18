/*
* File: wb16_driver.sv
*
* This file contains the AXI-Lite driver class, responsible for driving transactions
* to the DUT via the AXI-Lite interface.
*
* Key Features:
* - Extends uvm_driver with wb16_seq_item as the transaction type.
* - Uses a virtual interface to drive AXI-Lite signals.
* - Implements the UVM run_phase to continuously process and drive transactions.
*
* TODO:
* 1. Implement proper reset handling in the driaver.
* 2. Add configurable delays between transactions for more realistic scenarios.
* 3. Implement error injection capabilities for robust testing.
*
* Note on Compliance:
* This implementation is functional but could be improved for better adherence 
* to UVM best practices:
* - Consider separating the driving logic into smaller, more focused tasks.
* - Implement proper response handling and reporting.
* - Add more comprehensive error checking and recovery mechanisms.
*/
`ifndef WB16_DRIVER
`define WB16_DRIVER

class wb16_driver extends uvm_driver #(wb16_seq_item);
    virtual wb16_if vif;  // Make sure this matches your interface type
    
    `uvm_component_utils(wb16_driver)

    uvm_analysis_port#(wb16_seq_item) drv2rm_port;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual wb16_if)::get(this, "", "wb16_vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface not found for %s", get_full_name()))
        end
        drv2rm_port = new("drv2rm_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            wb16_seq_item to_rm;
            
            // receive from sequencer
            seq_item_port.get_next_item(req);
            drive_transaction();
			// send out to reference model
			$cast(to_rm,req.clone());
			to_rm.start_time = $time;
			drv2rm_port.write(to_rm);
			// return to sequencer
			$cast(rsp,req.clone());
			rsp.set_id_info(req);
            seq_item_port.item_done();
			seq_item_port.put(rsp);
        end
    endtask

    task drive_transaction();
        // counter for stall error mitigation
        int wait_retry;
        // TODO: Add proper reset handling here
        //----------- WRITE ROUTINE -----------//
        @vif.clk;

        // start cycle
        vif.wbs_cyc_i = #(7) 1'b1;
        vif.wbs_we_i = #(7) ~req.read;
        vif.wbs_sel_i = #(7) 2'b11;
        @vif.clk;

        // write cycle
        wait_retry = 20;
        vif.wbs_adr_i = #(7) req.addr;
        vif.wbs_dat_i = #(7) req.data;
        vif.wbs_stb_i = #(7) 1'b1;
        @vif.clk;
        while ( (wait_retry > 0) && ~(vif.wbs_ack_o) )
        begin
            @(posedge vif.clk) ;
            wait_retry = wait_retry - 1 ;
        end

        // fetch data during read mode
        if (req.read == 1) req.data = vif.wbs_dat_o;

        vif.wbs_adr_i = #(1) 3'hx;
        vif.wbs_dat_i = #(1) 16'hxx;
        vif.wbs_stb_i = #(1) 1'b0;

        // check response validity
        if (wait_retry == 0) begin
            `uvm_warning("WB16_DRIVER", "Handshake no response") 
        end

        // end cycle
        vif.wbs_cyc_i = #(1) 1'b0;
        vif.wbs_we_i = #(1) 1'b0;

        @vif.clk;
        // TODO: Add configurable delays between transactions
    endtask
endclass

`endif
