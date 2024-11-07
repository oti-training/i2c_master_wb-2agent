`ifndef test
`define TEST

`include "environment.svh"

class wb_master_test extends uvm_test;

    // register agent as component to UVM Factory
    `uvm_component_utils(wb_master_test);
  
    // register agent as component to UVM Factory
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    wb_master_environment wb_master_environment_handler;

    // build phase
    function void build_phase(uvm_phase phase);
        wb_master_environment_handler = wb_master_environment::type_id::create("wb_master_environment_handler", this);
    endfunction
  
endclass

`endif