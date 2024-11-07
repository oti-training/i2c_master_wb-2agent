`ifndef SEQUENCER
`define SEQUENCER

/******************************
 * UVM SEQUENCE API
 ******************************/
class read_sequence_api extends uvm_sequence #(sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(read_sequence_api);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // internal properties
    logic   [2:0]   raddr;
    logic   [7:0]   rdata;
    function set_property(logic [2:0] raddr);
        this.raddr = raddr;
    endfunction

    // create sequence using the sequence_item
    task body;
        // start transfer
        req = sequence_item::type_id::create("req");
        start_item(req);
        req.addr = this.raddr;
        req.data = 0;
        req.rw = 0;
        finish_item(req);

        // fetch output
        rdata = req.data;
    endtask

    // encapsulate set_property and start task
    // not directly implemented in the body task due to input arguments
    task read (logic [2:0] raddr, uvm_sequencer_base seqr, uvm_sequence_base parent = null);
        this.set_property(raddr);
        this.start(seqr, parent);

    endtask

endclass

class write_sequence_api extends uvm_sequence #(sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(write_sequence_api);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // internal properties
    logic   [2:0]   waddr;
    logic   [7:0]   wdata;
    function set_property(logic [2:0] waddr, logic [7:0] wdata);
        this.waddr = waddr;
        this.wdata = wdata;
    endfunction

    // create sequence using the sequence_item
    task body;
        req = sequence_item::type_id::create("req");
        start_item(req);
        req.addr = this.waddr;
        req.data = this.wdata;
        req.rw = 1;
        finish_item(req);
    endtask

    // encapsulate set_property and start task
    // not directly implemented in the body task due to input arguments
    task write (logic [2:0] waddr, logic [7:0] wdata, uvm_sequencer_base seqr, uvm_sequence_base parent = null);
        this.set_property(waddr, wdata);
        this.start(seqr, parent);
    endtask

endclass

/******************************
 * UVM SEQUENCE WORKER
 ******************************/

 class random_sequence_worker extends uvm_sequence #(sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(random_sequence_worker);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // create sequence using the sequence_item
    write_sequence_api write_sequence_api_inst;
    read_sequence_api read_sequence_api_inst;
    sequence_item seq;
    bit rd_ready = 0;
    task body;
        // write device address
        write_sequence_api_inst = write_sequence_api::type_id::create("init_seq");
        write_sequence_api_inst.write(3'h2, 8'h6, m_sequencer, this);

        // write routine
        repeat(10) begin
            seq = sequence_item::type_id::create("seq");

            // write random register address
            start_item(seq);
            if (!seq.randomize()) `uvm_error("RANDOM_SEQUENCE", "Failed to randomize sequence")
            finish_item(seq);
            // write command
            start_item(seq);
            seq.addr = 3'h3;
            seq.data = 8'h04;
            seq.rw = 1;
            finish_item(seq);

            // write random value
            start_item(seq);
            if (!seq.randomize()) `uvm_error("RANDOM_SEQUENCE", "Failed to randomize sequence")
            finish_item(seq);
            // write and finish command
            start_item(seq);
            seq.addr = 3'h3;
            seq.data = 8'h14;
            seq.rw = 1;
            finish_item(seq);
        end

        // read routine
        repeat(10) begin

            seq = sequence_item::type_id::create("seq");
            // write random register address
            start_item(seq);
            if (!seq.randomize()) `uvm_error("RANDOM_SEQUENCE", "Failed to randomize sequence")
            finish_item(seq);
            // write command
            start_item(seq);
            seq.addr = 3'h3;
            seq.data = 8'h04;
            seq.rw = 1;
            finish_item(seq);
            // start, read, and finish command
            start_item(seq);
            seq.addr = 3'h3;
            seq.data = 8'h13;
            seq.rw = 1;
            finish_item(seq);

            read_sequence_api_inst = read_sequence_api::type_id::create("wait_rd_fifo");
            // wait until read FIFO is not empty
            rd_ready = 0;
            while (~rd_ready) begin
                read_sequence_api_inst.read(3'h1, m_sequencer, this);
                if (read_sequence_api_inst.rdata[6] == 0) rd_ready = 1;
            end

            // read fifo
            read_sequence_api_inst.read(3'h4, m_sequencer, this);
            
            // wait until read FIFO is empty
            rd_ready = 1;
            while (rd_ready) begin
                read_sequence_api_inst.read(3'h1, m_sequencer, this);
                if (read_sequence_api_inst.rdata[6] == 1) rd_ready = 0;
            end
        end

        // wait until finish
        #100000;
        // `uvm_info("RANDOM_WRITE_SEQUENCER", $sformatf("Randomized WB input complete (addr:0x%1h, data:0x%2h)", req.addr, req.data), UVM_MEDIUM)
    endtask

endclass

class read_i2c_worker extends uvm_sequence #(sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(read_i2c_worker);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // sequence API instantiation
    read_sequence_api read_sequence_api_inst;
    write_sequence_api write_sequence_api_inst;

    // internal properties
    logic   [6:0]   device_addr;
    logic   [7:0]   reg_addr;
    int             len;
    function set_property (logic [6:0] device_addr, logic [7:0] reg_addr, int len);
        this.device_addr = device_addr;
        this.reg_addr = reg_addr;
        this.len = len;
    endfunction
    
    bit [7:0] WB_DEVICE_ADDR = 3'h2;
    bit [7:0] WB_REG_ADDR = 3'h3;
    bit [7:0] WB_DATA_ADDR = 3'h4;

    task body;
        int i;
        logic [7:0] cmd;

        // check whether the length is valid
        if (this.len <= 0) `uvm_error("READ_I2C_WORKER", $sformatf("Read length is smaller than 1: given 0x%d", this.len))

        read_sequence_api_inst = read_sequence_api::type_id::create("read");
        write_sequence_api_inst = write_sequence_api::type_id::create("write");

        // read routine consists of:
        // 1. targeting a specific register inside a device
        //     -> write i2c device_address register in wishbone bridge
        //     -> write i2c register address in wishbone bridge
        //     -> write i2c command (cmd_write) in wishbone bridge
        // 2. continuously read the register using increment
        //     -> write i2c command (cmd_start, cmd_read) in wishbone bridge
        //     -> read i2c data output register from wishbone bridge
        //     -> loop to write command (cmd_read) until reaching desired length
        //     -> read i2c data output register from wishbone bridge
        //     -> write command (cmd_stop)
        //     -> read i2c data output register from wishbone bridge

        // targeting a specific register inside a device
        write_sequence_api_inst.write(WB_DEVICE_ADDR, this.device_addr, m_sequencer, this);
        write_sequence_api_inst.write(WB_DATA_ADDR, this.reg_addr, m_sequencer, this);
        write_sequence_api_inst.write(WB_REG_ADDR, 8'h4, m_sequencer, this);   // write command

        // continuously read the register using increment
        for (i = 0; i<this.len; i=i+1) begin
            // setup command
            cmd = 8'h02;                            // default read command
            if (i == 0) cmd = cmd | 8'h01;          // start command
            if (i == this.len-1) cmd = cmd | 8'h10; // stop command

            // transfer read i2c command
            write_sequence_api_inst.write(WB_REG_ADDR, cmd, m_sequencer, this);

            // read i2c data from wishbone reg
            read_sequence_api_inst.read(WB_DATA_ADDR, m_sequencer, this);

            // process i2c read data (if needed) below
            // ...
        end

        // wait for the communication to complete
        #10000;

    endtask

    // encapsulate set_property and start task
    // not directly implemented in the body task due to input arguments
    task read_i2c (input bit [6:0] device_addr, input bit [7:0] reg_addr, int len=1, uvm_sequencer_base seqr);
        this.set_property(device_addr, reg_addr, len);
        this.start(seqr);
    endtask

endclass

class write_i2c_worker extends uvm_sequence #(sequence_item);

    // register object to UVM Factory
    `uvm_object_utils(write_i2c_worker);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // sequence API instantiation
    read_sequence_api read_sequence_api_inst;
    write_sequence_api write_sequence_api_inst;

    // internal properties

    bit     [6:0]   device_addr;
    bit     [7:0]   reg_addr;
    logic   [7:0]   data [$];  
    int             len;
    
    function void set_property (logic [6:0] device_addr, logic [7:0] reg_addr, logic [7:0] data [$], int len);
        this.device_addr = device_addr;
        this.reg_addr = reg_addr;
        this.data = data;
        this.len = len;
    endfunction
    
    bit [7:0] WB_DEVICE_ADDR = 3'h2;
    bit [7:0] WB_REG_ADDR = 3'h3;
    bit [7:0] WB_DATA_ADDR = 3'h4;

    task body;
        int i;
        logic [7:0] cmd;

        // check whether the length is valid
        if (this.len <= 0) `uvm_error("WRITE_I2C_WORKER", $sformatf("Write length is smaller than 1: given 0x%d", this.len))

        read_sequence_api_inst = read_sequence_api::type_id::create("read");
        write_sequence_api_inst = write_sequence_api::type_id::create("write");

        // read routine consists of:
        // 1. targeting a specific register inside a device
        //     -> write i2c device_address register in wishbone bridge
        //     -> write i2c register address in wishbone bridge
        //     -> write i2c command (cmd_write) in wishbone bridge
        // 2. continuously write the register using increment
        //     -> write reg data in wishbone bridge
        //     -> write i2c command (cmd_write) from wishbone bridge
        //     -> repeat until cmd_stop

        // targeting a specific register inside a device
        write_sequence_api_inst.write(WB_DEVICE_ADDR, this.device_addr, m_sequencer, this);
        write_sequence_api_inst.write(WB_DATA_ADDR, this.reg_addr, m_sequencer, this);
        write_sequence_api_inst.write(WB_REG_ADDR, 8'h4, m_sequencer, this);   // write command

        // continuously read the register using increment
        for (i = 0; i<this.len; i=i+1) begin
            // setup command
            cmd = 8'h04;                            // default write command
            if (i == this.len-1) cmd = cmd | 8'h10; // stop command

            // write i2c data to wishbone reg
            write_sequence_api_inst.write(WB_DATA_ADDR, this.data.pop_front(), m_sequencer, this);

            // transfer read i2c command
            write_sequence_api_inst.write(WB_REG_ADDR, cmd, m_sequencer, this);
        end

        // wait for the communication to complete
        #10000;

    endtask

    // encapsulate set_property and start task
    // not directly implemented in the body task due to input arguments
    task write_i2c (logic [6:0] device_addr, logic [7:0] reg_addr, logic [7:0] data [$], int len=1, uvm_sequencer_base seqr);
        this.set_property(device_addr, reg_addr, data, len);
        this.start(seqr);
    endtask
endclass

class wb_master_sequencer extends uvm_sequencer #(sequence_item);

    // register sequence to UVM factory
    `uvm_component_utils(wb_master_sequencer)

    // create the sequence constructor default
    function new (string name, uvm_component parent); // default name my_seq
        // call the base class virtual function
        super.new(name, parent);
    endfunction

endclass

class wb_master_vsequence extends uvm_sequence #(sequence_item);

    // register sequence to UVM factory
    `uvm_object_utils(wb_master_vsequence)

    // create the sequence constructor default
    function new (string name=""); // default name my_seq
        // call the base class virtual function
        super.new(name);
    endfunction

    // create sequencer handler
    uvm_sequencer_base sequencer_1;
    // uvm_sequencer_base sequencer_2;

    // create sequence
    write_i2c_worker write_sequence;    
    read_i2c_worker read_sequence;   

    // write_random_sequence_api write_random_sequence;
    random_sequence_worker random_sequence;

    // config object
    wb8_i2c_test_config config_obj;

    // run the sequence
    task body;
        integer i;
        string scope_name;
        // not randomized objects
        write_sequence = write_i2c_worker::type_id::create("write_sequence");
        read_sequence = read_i2c_worker::type_id::create("read_sequence");
        // test objects
        random_sequence = random_sequence_worker::type_id::create("random_sequence");


        begin
            scope_name = get_full_name();
            if (!uvm_config_db#(wb8_i2c_test_config)::get(null, "", "wb8_i2c_test_config", config_obj))
                `uvm_error("VIRTUAL_SEQUENCE", "Config Object cannot be loaded")
            
            if (config_obj.test_type == 0) begin
            // not randomized operaiton
                write_sequence.write_i2c(7'h6, 8'ha, {8'h33, 8'h44}, 2, sequencer_1);
                read_sequence.read_i2c(7'h6, 8'ha, 2, sequencer_1);
                write_sequence.write_i2c(7'h6, 8'ha, {8'h11}, 1, sequencer_1);
                read_sequence.read_i2c(7'h6, 8'ha, 2, sequencer_1);
            end

            // test operation
            else if (config_obj.test_type == 1) begin
                random_sequence.start(sequencer_1);
            end
        end
    endtask

endclass


`endif
