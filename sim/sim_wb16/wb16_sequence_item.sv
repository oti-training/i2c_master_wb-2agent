`ifndef SEQ_ITEM
`define SEQ_ITEM

/******************************
 * UVM SEQUENCE ITEM BASE CLASS
 ******************************/
class sequence_item_base extends uvm_sequence_item;

    // register object to UVM Factory
    `uvm_object_utils(sequence_item_base);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // item member
    rand logic   [15:0]              data;
    rand logic                      rw; // r:0, w:1

endclass
class sequence_item_base_derived #(int ADDR_WIDTH = 8) extends sequence_item_base;

    // register object to UVM Factory
    `uvm_object_utils(sequence_item_base_derived);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    // item member
    rand logic   [ADDR_WIDTH-1:0]   addr;

endclass

/******************************
 * UVM SEQUENCE ITEM
 ******************************/
class sequence_item extends sequence_item_base_derived#(.ADDR_WIDTH(3));

    // register object to UVM Factory
    `uvm_object_utils(sequence_item);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

    constraint address_range {
        addr == 4;
    }

    constraint command_range {
        rw == 1;
    }

    constraint data_range {
        data < 8'h10;
    }

endclass

class sequence_item_slave extends sequence_item_base_derived#(.ADDR_WIDTH(8));

    // register object to UVM Factory
    `uvm_object_utils(sequence_item_slave);

    // constructor
    function new (string name="");
        super.new(name);
    endfunction

endclass


typedef sequence_item_slave monitor_sequence_item;

`endif