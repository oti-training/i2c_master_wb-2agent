`ifndef DRIVER
`define DRIVER

class wb_master_driver extends uvm_driver#(sequence_item);

    // register object to UVM Factory
    `uvm_component_utils(wb_master_driver);

    // constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // set driver-DUT interface
    virtual wb16_interface.driver wb16_vif;
    wb16_i2c_test_config config_obj;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(wb16_i2c_test_config)::get(this, "", "wb16_i2c_test_config", config_obj)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
        wb16_vif = config_obj.wb16_vif;
    endfunction

    /** the read sequence is constructed of 3 procedures:
            - start cycle
            - read operation
            - end cycle
        
        several parameters that will be used:
        - Tp: WB_PERIOD=10
        - Tsetup: 3
        - Thold: 1
    **/

    /**
        -- wait init clock (1 clock)
        START CYCLE:
            CYC_I <- #(Tp - Tsetup) 1'b1
            CAB_I <- #(Tp - Tsetup) 1'b0 (deactivate burst transfer)
            WE_I  <- #(Tp - Tsetup) 1'b0
        -- wait init clock (arbitrary)
        READ OPERATION:
            ADR_I <- #(Tp - Tsetup) address
            SEL_I <- #(Tp - Tsetup) 0
            TAG_I <- #(Tp - Tsetup) 0, cti and bte are not used due to inactive burst
            STB_I <- #(Tp - Tsetup) 1'b1
        -- wait until ACK_O, RTY_O, or ERR_O give response(s)
        -- at this stage, the data response data is valid OR error has been asserted
            ADR_I <- #(Thold) 32{1'bx}
            SEL_I <- #(Thold) x
            TAG_I <- #(Thold) x
            STB_I <- #(Thold) 0
        END CYCLE:
            CYC_I <- #(Thold) 1'b0
            CAB_I <- #(Thold) 1'b0
    **/

    integer wait_retry;
    // define driver behavior
    task run_phase (uvm_phase phase);
        
        // reset routine
        wb16_vif.rst = 1;
        @wb16_vif.clk;
        wb16_vif.rst = 0; 
        @wb16_vif.clk;

        // fetch test sequences, pass it to the DUT as signals
        forever begin
            @(posedge wb16_vif.clk);
            seq_item_port.get_next_item(req);
            //****************** DRIVE THE INTERFACE ********************/
            //----------- WRITE ROUTINE -----------//
            @wb16_vif.clk;

                // start cycle
                wb16_vif.wbs_cyc_i = #(7) 1'b1;
                wb16_vif.wbs_we_i = #(7) req.rw;

            @wb16_vif.clk;

                // write cycle
                wait_retry = 20;
                wb16_vif.wbs_sel_i = #(7) 2'b11;
                wb16_vif.wbs_adr_i = #(7) req.addr;
                wb16_vif.wbs_dat_i = #(7) req.data;
                wb16_vif.wbs_stb_i = #(7) 1'b1;
                @wb16_vif.clk;
                while ( (wait_retry > 0) && ~(wb16_vif.wbs_ack_o) )
                begin
                    @(posedge wb16_vif.clk) ;
                    wait_retry = wait_retry - 1 ;
                end
                // fetch data during read mode
                if (req.rw == 0) req.data = wb16_vif.wbs_dat_o;
                
                wb16_vif.wbs_adr_i = #(1) 3'hx;
                wb16_vif.wbs_dat_i = #(1) 16'hxxxx;
                wb16_vif.wbs_stb_i = #(1) 1'b0;

                // check response validity
                if (wait_retry == 0) begin
                    `uvm_warning("DRIVER", "Handshake no response") 
                end
                
                // end cycle
                wb16_vif.wbs_cyc_i = #(1) 1'b0;
                wb16_vif.wbs_we_i = #(1) 1'b0;

            @wb16_vif.clk;
            // ****************************************************************
            seq_item_port.item_done();
        end
    endtask

endclass

`endif