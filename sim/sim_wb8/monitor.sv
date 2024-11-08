`ifndef MONITOR
`define MONITOR

class wb_master_monitor extends uvm_monitor;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_monitor)

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // analysis port
    uvm_analysis_port #(sequence_item_base) monitor_ap;

    // set driver-DUT interface
    virtual wb8_interface wb8_vif;
    monitor_sequence_item monitor_item;
    sequence_item wb_tlm_obj;
    wb8_i2c_test_config config_obj;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(wb8_i2c_test_config)::get(this, "", "wb8_i2c_test_config", config_obj)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
        wb8_vif = config_obj.wb8_vif;
        monitor_ap = new("monitor_ap", this);
    endfunction

    // monitor behavior
    task run_phase(uvm_phase phase);
        bit [2:0] wb_addr;
        bit [7:0] wb_data;
        bit       wb_rw;
        bit       txn_valid;
        int       counter;
        monitor_sequence_item monitor_item;
        monitor_item = monitor_sequence_item::type_id::create("monitor_item");

        forever begin
            // initialize transaction as invalid
            txn_valid = 0;
            // wait for start cycle
            wait(wb8_vif.wbs_cyc_i);
            // get ack or terminate if nack
            for (counter=0; counter<20; counter=counter+1) begin
                // wishbone is acknowledged
                if (wb8_vif.wbs_ack_o) begin
                    txn_valid = 1;
                    // check operation mode
                    #1; wb_rw = wb8_vif.wbs_we_i;
                    // retrieve data
                    wb_addr = wb8_vif.wbs_adr_i;
                    if (wb_rw == 0) wb_data = wb8_vif.wbs_dat_o;
                    else wb_data = wb8_vif.wbs_dat_i;
                    break; // break from the ack wait
                end
                @(wb8_vif.clk);
            end

            // only if we get a valid data that was acknowledged
            if (txn_valid == 1) begin
                // wait until cycle done
                for (counter=0; counter<20; counter=counter+1) begin
                    // transfer cycle is done
                    if (wb8_vif.wbs_cyc_i==0) begin
                        txn_valid = 1;
                        break;
                    end
                    // transfer cycle not done, wait for another cycle
                    txn_valid = 0;
                    @(wb8_vif.clk);
                end
            end

            // decode the process based on the data
            if (txn_valid) begin
                // send the data to coverage collector
                wb_tlm_obj = sequence_item::type_id::create("monitor_ap");
                wb_tlm_obj.addr = wb_addr;
                wb_tlm_obj.data = wb_data;
                wb_tlm_obj.rw = wb_rw;
                monitor_ap.write(wb_tlm_obj);
            end
        end
    endtask

endclass

`endif