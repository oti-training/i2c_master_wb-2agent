`ifndef DRIVER_SLAVE
`define DRIVER_SLAVE

// `include "sequence_slave.svh"
// `include "config.svh"

class wb_master_driver_slave extends uvm_driver#(sequence_item_slave);

    /*************************
    * Component Initialization
    **************************/
    // register object to UVM Factory
    `uvm_component_utils(wb_master_driver_slave);

    // constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // analysis port
    uvm_analysis_port #(monitor_sequence_item) ap;

    // set driver-DUT interface
    virtual top_interface.driver_slave top_vinterface;
    monitor_sequence_item monitor_item;
    wb_master_test_config config_obj;
    function void build_phase (uvm_phase phase);
        if (!uvm_config_db #(wb_master_test_config)::get(this, "", "wb_master_config", config_obj)) begin
            `uvm_error("", "uvm_config_db::driver.svh get failed on BUILD_PHASE")
        end
        top_vinterface = config_obj.top_vinterface;
        ap = new("ap", this);
    endfunction

    /*************************
    * Internal Properties
    **************************/
    // State Enumeration
    typedef enum {  RESP_IDLE, 
                    RESP_REGADDR_WAIT, 
                    RESP_RW_WAIT, 
                    RESP_READ, 
                    RESP_WRITE
                    } resp_state_type;  // Slave Driver FSM
    typedef enum {  PACKET_ACK,
                    PACKET_NACK
                    } packet_type;      // Received Packet ACK type
    typedef enum {  CMD_NONE,
                    CMD_START,
                    CMD_STOP
                    } command_type;     // Start/Stop Bit type

    // Variables
    resp_state_type resp_state = RESP_IDLE;
    command_type command;
    packet_type packet;
    bit start, stop, ack;
    bit [7:0] data;
    bit flip;
    integer i;

    // TLM packet
    sequence_item_slave req;
    sequence_item_slave rsp;
    bit [6:0] reg_addr;
    bit [7:0] reg_data;
    bit       reg_rw;

    // Methods
    task communicate_to_sequencer;
        seq_item_port.get_next_item(req);
        req.addr = reg_addr;
        req.data = reg_data;
        req.rw = reg_rw;
        seq_item_port.item_done();

        // if read, then sequencer needs to return a value
        if (req.rw == 0) begin 
            seq_item_port.get_next_item(rsp);
            reg_data = rsp.data;
            seq_item_port.item_done();
        end

        // also send data to the scoreboard when the transaction completes
        monitor_item = monitor_sequence_item::type_id::create("i2c_observer");
        monitor_item.data = reg_data;
        monitor_item.addr = reg_addr;
        monitor_item.rw = reg_rw;
        ap.write(monitor_item);

    endtask

    task get_next_state;
        // A function to decode the next responder (slave) state based on the current state and the input
        if ((command == CMD_STOP)) begin
            resp_state = RESP_IDLE;
        end

        else begin // packet acknowledged
            // idle state
            if (resp_state == RESP_IDLE) begin
                if (command == CMD_START) begin
                    if (data == (8'h6<<1)) begin
                        resp_state = RESP_REGADDR_WAIT;
                         `uvm_info("DRIVER_SLAVE::STATE_FSM", "Device is being accessed: dev_addr 0x6", UVM_MEDIUM)
                    end
                end
            end

            // state after device address input, waiting for register address
            else if (resp_state == RESP_REGADDR_WAIT) begin
                if (command == CMD_NONE) begin
                    resp_state = RESP_RW_WAIT;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Internal address is being accessed: reg_addr 0x%2h", data), UVM_MEDIUM)
                    reg_addr = data;
                end
            end

            // state after register address input, waiting for next cmd (R/W)
            else if (resp_state == RESP_RW_WAIT) begin
                // if we get a start command, then the operation is READ
                if (command == CMD_START) begin
                    resp_state = RESP_READ;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", "Device is being read: dev_addr 0x6", UVM_MEDIUM)
                    reg_rw = 0;
                    // fetch data from the sequencer for the next read i2c pin wiggles
                    communicate_to_sequencer;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Reading: data 0x%2h", reg_data), UVM_MEDIUM)
                end
                else if (command == CMD_NONE) begin
                    // if we get a packet without a specific command (CMD_NONE), then the operation is WRITE
                    resp_state = RESP_WRITE;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Writing: data 0x%2h", data), UVM_MEDIUM)
                    reg_rw = 1;
                    reg_data = data;
                    // write data to the sequencer
                    communicate_to_sequencer;
                end
            end

            // read state latch
            else if (resp_state == RESP_READ) begin
                reg_data = data;
                reg_rw = 0;

                if (packet == PACKET_ACK) begin
                    // if packet is still acknowledged, then the data is still being read in an incremental address
                    reg_addr = reg_addr + 1;
                    communicate_to_sequencer;
                    `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Reading: data 0x%2h", reg_data), UVM_MEDIUM)
                end
                else begin
                    // if the packet is NACK, then the read operation is done
                    resp_state = RESP_IDLE;
                end

            end

            // write state latch
            else if (resp_state == RESP_WRITE) begin
                `uvm_info("DRIVER_SLAVE::STATE_FSM", $sformatf("Writing: data 0x%2h", data), UVM_MEDIUM)
                reg_addr = reg_addr + 1;
                reg_rw = 1;
                reg_data = data;
                // write data to the sequencer
                communicate_to_sequencer;
            end
        end
    endtask

    // pin-level processing tasks
    task read_packet;
        begin
            start = 0;                             // start bit variable
            stop = 0;                              // stop bit variable
            ack = 0;                               // ack/nack variable
            data = 0;                              // data packet (8 bits)
            packet = 0;                            // ack/nack variable (redundant, remove later)
            flip = (resp_state == RESP_READ);      // master/slave operation based on the state
            top_vinterface.resp_sda_o = 1 ^ flip;

            fork
                // THREAD 1 :: check for start bit
                begin
                    forever begin
                        @(negedge top_vinterface.i2c_sda_i);
                        if (top_vinterface.i2c_scl_i == 1'b1) begin
                            start = 1;
                        end
                    end
                end

                begin
                    // THREAD 2 :: check for stop bit
                    forever begin
                        @(posedge top_vinterface.i2c_sda_i);
                        if (top_vinterface.i2c_scl_i == 1'b1) begin
                            stop = 1;
                            top_vinterface.resp_sda_o = 1;
                            break;
                        end
                    end
                end

                // THREAD 3 :: retrieve data
                begin
                    if (resp_state != RESP_READ) begin
                        for(i=0; i<8+(start && resp_state!=RESP_IDLE); i=i+1) begin
                            @(posedge top_vinterface.i2c_scl_i);
                            data = (data << 1) | top_vinterface.i2c_sda_i;
                        end
                        // set ack bit
                        @(negedge top_vinterface.i2c_scl_i);
                        #5;
                        top_vinterface.resp_sda_o = 0 ^ flip;
                        // read ack bit
                        @(posedge top_vinterface.i2c_scl_i);
                        #5;
                        ack = ~top_vinterface.i2c_sda_i;
                        // wait until transfer finish
                        @(negedge top_vinterface.i2c_scl_i);
                        // making sure no race condition is happening
                        #5;
                    end

                    else begin
                        for(i=0; i<8+(start && resp_state!=RESP_IDLE); i=i+1) begin
                            #5;
                            top_vinterface.resp_sda_o = reg_data[7-i];
                            @(negedge top_vinterface.i2c_scl_i);
                        end
                        #5;
                        top_vinterface.resp_sda_o = 0 ^ flip;
                        // read ack bit
                        @(posedge top_vinterface.i2c_scl_i);
                        #5;
                        ack = ~top_vinterface.i2c_sda_i;
                        // wait until transfer finish
                        @(negedge top_vinterface.i2c_scl_i);
                        // making sure no race condition is happening
                        #5;
                    end
                end
            join_any
            disable fork;

            top_vinterface.resp_sda_o = 1;
        end
    endtask


    // define driver behavior
    task run_phase (uvm_phase phase);

        // do reset
        top_vinterface.rst = 1;
        @top_vinterface.clk;
        top_vinterface.rst = 0; 
        @top_vinterface.clk;

        forever begin
            // read packet
            read_packet;

            // encode command
            if (stop) command = CMD_STOP;
            else if (start) command = CMD_START;
            else command = CMD_NONE;
            // encode packet
            if (ack) packet = PACKET_ACK;
            else packet = PACKET_NACK;

            // compute next state
            get_next_state;
            `uvm_info("DRIVER_SLAVE", $sformatf("Input have been processed: state:0x%1h, cmd:0x%2h, data:0x%1h, ack:0x%1h", resp_state, command, data, packet), UVM_MEDIUM)

        end

    endtask

endclass

`endif