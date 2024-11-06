`ifndef MONITOR
`define MONITOR

// `include "config.svh"

class monitor_sequence_item extends uvm_sequence_item;

    bit   [7:0]  addr;
    bit   [7:0]  data;
    bit          rw;

    // register object to UVM Factory
    `uvm_object_utils(monitor_sequence_item);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

endclass

class wb_master_monitor extends uvm_monitor;
  
    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_monitor)

    // default constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // analysis port
    uvm_analysis_port #(monitor_sequence_item) ap;

    // set driver-DUT interface
    virtual top_interface top_vinterface;
    monitor_sequence_item monitor_item;
    wb_master_test_config config_obj;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(wb_master_test_config)::get(this, "", "wb_master_config", config_obj)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
        top_vinterface = config_obj.top_vinterface;
        ap = new("ap", this);
    endfunction

    // wishbone command decoder
    bit [6:0] i2c_devaddr;
    bit [7:0] i2c_regaddr;
    bit [7:0] i2c_data;
    bit       i2c_rw;
    bit       i2c_stop = 0;
    bit       i2c_increment = 0, i2c_prev_increment = 0;
    int       increment_val = 0;

    bit [6:0] temp_devaddr;
    bit [7:0] temp_data;
    // bit       temp_rw;
    typedef enum {IDLE, RW_WAIT, READ, WRITE} state_t;
    state_t state = IDLE;

    task communicate_to_sb;
        increment_val = (i2c_increment & i2c_prev_increment) ? increment_val + 1 : 0;
        monitor_item = monitor_sequence_item::type_id::create("monlog");
        monitor_item.addr = i2c_regaddr + increment_val;
        monitor_item.data = i2c_data;
        monitor_item.rw = i2c_rw;
        ap.write(monitor_item);
    endtask

    task wb_i2c_decode;
    // TO BE DONE!!!
    // 1. Be aware that WB finishes first, way before I2C due to FIFO implementation, so don't take read data from WB
    // 2. WB read needs to be delayed until read data is set from I2C, same reason as (1)
    // 3. Don't forget to implement address increment (check)
        input bit [2:0] wb_addr;
        input bit [7:0] wb_data;
        input bit       wb_rw;
        begin
            // `uvm_info("MONITOR TASK LOG", $sformatf("data:0x%2h, addr:0x%2h, wb_rw:0x%1h", wb_data, wb_addr, wb_rw), UVM_MEDIUM);
            

            // only wishbone write operation will affect I2C ports
            if (wb_rw) begin
                i2c_prev_increment = i2c_increment;
                case (state) 
                    IDLE: begin
                        i2c_increment = 0;
                        case (wb_addr)
                            // 0: 
                            // 1: 
                            // device address reg
                            2: begin
                                temp_devaddr = wb_data[6:0];
                            end
                            // command reg
                            3: begin
                                if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                    if (wb_data[2]) begin // write
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;

                                        if (i2c_devaddr == 7'h6) begin
                                            if (wb_data[4]) begin// stop
                                                state = IDLE;
                                            end
                                            else begin
                                                state = RW_WAIT;
                                                i2c_stop = 0;
                                            end
                                        end
                                    end
                                    else if (wb_data[1]) begin // read
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;

                                        if (i2c_devaddr == 7'h6) begin
                                            if (wb_data[4]) begin
                                                i2c_stop = 1;
                                                state = READ;
                                            end
                                            else begin
                                                i2c_stop = 0;
                                                state = READ;
                                            end
                                        end
                                    end
                                end
                            end
                            // data reg
                            4: begin
                                temp_data = wb_data;
                            end
                        endcase
                    end
                    RW_WAIT: begin
                        i2c_increment = 0;
                        i2c_rw = 0; 
                        case (wb_addr)
                            // 0:
                            // 1:
                            // device address reg
                            2: begin
                                temp_devaddr = wb_data[6:0];
                            end
                            // command reg
                            3: begin
                                if (wb_data[2] ^ wb_data[1]) begin // only either read or write command
                                    if (wb_data[0] && wb_data[1]) begin
                                        // next is read
                                        if (temp_devaddr!=i2c_devaddr) begin
                                            i2c_devaddr = temp_devaddr;
                                            i2c_regaddr = temp_data;
                                            state = IDLE;
                                        end
                                        else begin
                                            i2c_data = temp_data;
                                            i2c_rw = 0;

                                            // log read
                                            i2c_increment = 1;
                                            // communicate_to_sb;

                                            if (wb_data[4]) state = IDLE;
                                            else begin
                                                state = READ;
                                            end
                                        end
                                    end
                                    else if (wb_data[2]) begin
                                        // next is write
                                        if (temp_devaddr!=i2c_devaddr) begin
                                            i2c_devaddr = temp_devaddr;
                                            i2c_regaddr = temp_data;
                                            state = IDLE;
                                        end
                                        else begin
                                            i2c_data = temp_data;
                                            i2c_rw = 1;

                                            // log read
                                            i2c_increment = 1;
                                            communicate_to_sb;

                                            if (wb_data[4]) state = IDLE;
                                            else begin
                                                state = WRITE;
                                            end
                                        end
                                    end
                                    else begin
                                        // invalid command
                                        state = IDLE;
                                    end
                                end
                            end
                            // data reg
                            4: begin
                                temp_data = wb_data;
                            end
                        endcase
                        if (i2c_stop) begin
                            state = IDLE;
                        end
                    end
                    READ: begin
                        i2c_rw = 0; 
                        case (wb_addr)
                            // 0:
                            // 1:
                            // device address reg
                            2: begin
                                temp_devaddr = wb_data[6:0];
                            end
                            // command reg
                            3: begin
                                if (wb_data[4]) i2c_stop = 1;
                                if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                    if (temp_devaddr!=i2c_devaddr) begin
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;
                                        state = IDLE;
                                    end
                                    else if (wb_data[0]) begin // start
                                        if (wb_data[1]) begin // read
                                            i2c_data = temp_data;

                                            // log read
                                            i2c_increment = 1;
                                            // communicate_to_sb;
                                        end
                                        else if (wb_data[2]) begin //write
                                            i2c_regaddr = temp_data;
                                            state = RW_WAIT;
                                            i2c_increment = 0;
                                        end
                                    end
                                    else begin // no start
                                        if (wb_data[1]) begin // read
                                            i2c_data = temp_data;

                                            // the address should be incrementing
                                            i2c_increment = 1;

                                            // log read
                                            // communicate_to_sb;
                                        end
                                        else if (wb_data[2]) begin //write
                                            i2c_regaddr = temp_data;
                                            state = RW_WAIT;
                                            i2c_increment = 0;
                                        end
                                    end
                                end
                            end
                            // data reg
                            4: begin
                                temp_data = wb_data;
                            end
                        endcase
                        if (i2c_stop) begin
                            state = IDLE;
                        end
                    end
                    WRITE: begin
                        i2c_rw = 1; 
                        case (wb_addr)
                            // 0:
                            // 1:
                            // device address reg
                            2: begin
                                temp_devaddr = wb_data[6:0];
                                // i2c_increment = i2c_increment;
                            end
                            // command reg
                            3: begin
                                if (wb_data[4]) i2c_stop = 1;
                                if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                    if (temp_devaddr!=i2c_devaddr) begin
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;
                                        state = IDLE;
                                    end
                                    else if (wb_data[0]) begin // start
                                        if (wb_data[2]) begin // write
                                            i2c_devaddr = temp_devaddr;
                                            i2c_data = temp_data;
                                            i2c_increment = 0;

                                            state = RW_WAIT;

                                            // // log write
                                            // communicate_to_sb;
                                        end
                                        else if (wb_data[1]) begin // read
                                            i2c_regaddr = temp_data;
                                            state = READ;
                                            i2c_increment = 0;
                                        end
                                    end
                                    else begin // no start
                                        if (wb_data[2]) begin // write
                                            i2c_data = temp_data;

                                            // the address should be incrementing
                                            i2c_increment = 1;

                                            // log write
                                            communicate_to_sb;
                                        end
                                        else if (wb_data[1]) begin // read
                                            i2c_regaddr = temp_data;
                                            state = READ;
                                            i2c_increment = 0;
                                        end
                                    end
                                end
                            end
                            // data reg
                            4: begin
                                temp_data = wb_data;
                                // i2c_increment = i2c_increment;
                            end
                        endcase
                        if (i2c_stop) begin
                            state = IDLE;
                        end
                    end
                endcase
            end
            else if (wb_rw == 0) begin
                if (wb_addr == 4) begin
                    i2c_data = wb_data;
                    i2c_increment = 1;
                    communicate_to_sb;
                end
            end
        end
    endtask

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
            wait(top_vinterface.wbs_cyc_i);
            // get ack or terminate if nack
            for (counter=0; counter<20; counter=counter+1) begin
                // wishbone is acknowledged
                if (top_vinterface.wbs_ack_o) begin
                    txn_valid = 1;
                    // check operation mode
                    #1; wb_rw = top_vinterface.wbs_we_i;
                    // retrieve data
                    wb_addr = top_vinterface.wbs_adr_i;
                    if (wb_rw == 0) wb_data = top_vinterface.wbs_dat_o; /*************change later***********/
                    else wb_data = top_vinterface.wbs_dat_i;
                    break; // break from the ack wait
                end
                @(top_vinterface.clk);
            end

            // only if we get a valid data that was acknowledged
            if (txn_valid == 1) begin
                // wait until cycle done
                for (counter=0; counter<20; counter=counter+1) begin
                    // transfer cycle is done
                    if (top_vinterface.wbs_cyc_i==0) begin
                        txn_valid = 1;
                        break;
                    end
                    // transfer cycle not done, wait for another cycle
                    txn_valid = 0;
                    @(top_vinterface.clk);
                end
            end

            // decode the process based on the data
            if (txn_valid) wb_i2c_decode (wb_addr, wb_data, wb_rw);
        end
    endtask

endclass

`endif