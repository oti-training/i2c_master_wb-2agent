/*
* File: axil_driver.sv
*
* This file contains the AXI-Lite driver class, responsible for driving transactions
* to the DUT via the AXI-Lite interface.
*
* Key Features:
* - Extends uvm_driver with axil_seq_item as the transaction type.
* - Uses a virtual interface to drive AXI-Lite signals.
* - Implements the UVM run_phase to continuously process and drive transactions.
*
* TODO:
* 1. Implement proper reset handling in the driver.
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
`ifndef AXIL_DRIVER
`define AXIL_DRIVER

class axil_driver extends uvm_driver #(axil_seq_item);
    virtual axil_if vif;  // Make sure this matches your interface type
    
    `uvm_component_utils(axil_driver)

	// port for reference model
	uvm_analysis_port#(axil_seq_item) drv2rm_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axil_if)::get(this, "", "axil_vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface not found for %s", get_full_name()))
        end
		drv2rm_port = new("drv2rm_port", this);
    endfunction

    task run_phase(uvm_phase phase);
		// initialize outputs
        vif.driver_cb.bready <= 0;
        vif.driver_cb.rready <= 0;
        vif.driver_cb.araddr <= 0;
        vif.driver_cb.arprot <= 0;
        vif.driver_cb.arvalid <= 0;

        forever begin
			axil_seq_item to_rm;
			
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
        // TODO: Add proper reset handling here

        if(req.read) begin
            @(vif.driver_cb);
            vif.driver_cb.araddr <= req.addr;
            vif.driver_cb.arvalid <= 1;
            vif.driver_cb.arprot <= 0;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.arready) @(vif.driver_cb);
            vif.driver_cb.arvalid <= 0;
            
            vif.driver_cb.rready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.rvalid) @(vif.driver_cb);
			
            req.data = vif.driver_cb.rdata;

            vif.driver_cb.rready <= 0;
        end else begin
            @(vif.driver_cb);
            vif.driver_cb.awaddr <= req.addr;
            vif.driver_cb.awvalid <= 1;
            vif.driver_cb.awprot <= 0;
            vif.driver_cb.wdata <= req.data;
            vif.driver_cb.wstrb <= req.strb;
            vif.driver_cb.wvalid <= 1;
            
            @(vif.driver_cb);
            while(!vif.driver_cb.awready || !vif.driver_cb.wready) @(vif.driver_cb);
            vif.driver_cb.awvalid <= 0;
            vif.driver_cb.wvalid <= 0;
            
            vif.driver_cb.bready <= 1;
            @(vif.driver_cb);
            while(!vif.driver_cb.bvalid) @(vif.driver_cb);
            vif.driver_cb.bready <= 0;
        end
        // TODO: Add configurable delays between transactions
    endtask
endclass

`endif
