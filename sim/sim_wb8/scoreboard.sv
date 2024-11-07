`ifndef SCOREBOARD
`define SCOREBOARD

class wb8_i2c_scoreboard extends uvm_scoreboard;
  
  // register scoreboard to UVM factory
  `uvm_component_utils(wb8_i2c_scoreboard)
  
  // create analysis port FIFOs
  uvm_tlm_analysis_fifo #(monitor_sequence_item) wb_to_i2c;
  uvm_tlm_analysis_fifo #(sequence_item_base) i2c_observer;

  // monitoring objects
  monitor_sequence_item wb_to_i2c_trans;
  sequence_item_base i2c_observer_trans_primal;
  sequence_item_base_derived i2c_observer_trans;

  // default constructor
  function new (string name = "wb8_i2c_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    wb_to_i2c = new("wb_to_i2c", this);
    i2c_observer = new("i2c_observer", this);
  endfunction
  
  // function void write(monitor_sequence_item monitor_item);
  //   if (monitor_item.rw == 0) // read
  //     `uvm_info("SCOREBOARD", $sformatf("Request READ:to address 0x%2h", monitor_item.addr), UVM_MEDIUM)
  //   else // write
  //     `uvm_info("SCOREBOARD", $sformatf("Request WRITE:0x%2h to address 0x%2h", monitor_item.data, monitor_item.addr), UVM_MEDIUM)
  // endfunction

  task run_phase (uvm_phase phase);
      forever begin
          fork
              // wait for wb_to_i2c object
              begin
                  wb_to_i2c.get(wb_to_i2c_trans);
              end
              // wait for i2c_observer object
              begin
                  i2c_observer.get(i2c_observer_trans_primal);
                  $cast(i2c_observer_trans, i2c_observer_trans_primal);
              end
          join

          // check monitoring objects
          if ((wb_to_i2c_trans.addr == i2c_observer_trans.addr) && (wb_to_i2c_trans.rw == i2c_observer_trans.rw) && (wb_to_i2c_trans.data == i2c_observer_trans.data))
              `uvm_info("SCOREBOARD", $sformatf("Monitoring objects comply. addr:0x%2h, cmd:0x%1h, data:0x%2h", wb_to_i2c_trans.addr, wb_to_i2c_trans.rw, wb_to_i2c_trans.data), UVM_MEDIUM)
          else 
              `uvm_warning("SCOREBOARD", $sformatf("Monitoring objects don't comply. wb[addr:0x%2h, cmd:0x%1h, data:0x%2h]; i2c[addr:0x%2h, cmd:0x%1h, data:0x%2h]", wb_to_i2c_trans.addr, wb_to_i2c_trans.rw, wb_to_i2c_trans.data, i2c_observer_trans.addr, i2c_observer_trans.rw, i2c_observer_trans.data))
      end   
  endtask
  
endclass

`endif