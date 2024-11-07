`ifndef SEQUENCER_SLAVE
`define SEQUENCER_SLAVE

class i2c_slave_sequence extends uvm_sequence #(sequence_item_slave);

    // register object to UVM Factory
    `uvm_object_utils(i2c_slave_sequence);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // memory
    int mem[int];

    task body;
        forever begin
            req = sequence_item_slave::type_id::create("req");
            rsp = sequence_item_slave::type_id::create("rsp");

            // start a request
            start_item(req);
            finish_item(req);           // by this time, a response has been sent from driver_slave

            // look at the response and decide read/write
            if (req.rw == 1) begin
                mem[req.addr] = req.data;
                `uvm_info("SEQUENCE_SLAVE", $sformatf("Writing data: 0x%2h to addr: 0x%2h", req.data, req.addr), UVM_MEDIUM)
            end
            else begin
                `uvm_info("SEQUENCE_SLAVE", $sformatf("Reading data: 0x%2h from addr: 0x%2h", mem[req.addr], req.addr), UVM_MEDIUM)
            end

            // give back response to the driver_slave ONLY IF the operation is READ
            if (req.rw == 0) begin      // read flag
                start_item(rsp);
                rsp.copy(req);
                rsp.data = mem[req.addr];
                finish_item(rsp);
            end
        end
    endtask


endclass

class i2c_slave_sequencer extends uvm_sequencer #(sequence_item_slave);

    // register sequence to UVM factory
    `uvm_component_utils(i2c_slave_sequencer)

    // create the sequence constructor default
    function new (string name, uvm_component parent);
        // call the base class virtual function
        super.new(name, parent);
    endfunction

endclass

`endif