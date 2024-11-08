`ifndef SCOREBOARD
`define SCOREBOARD

class wb8_i2c_scoreboard extends uvm_scoreboard;
  
  // register scoreboard to UVM factory
  `uvm_component_utils(wb8_i2c_scoreboard)
  
  // create analysis port FIFOs
  uvm_tlm_analysis_fifo #(sequence_item_base) wb_observer;
  uvm_tlm_analysis_fifo #(sequence_item_base) i2c_observer;

  // monitoring objects
  sequence_item_base wb_observer_trans_primal;
  sequence_item wb_observer_trans;
  sequence_item_base i2c_observer_trans_primal;
  sequence_item_base_derived i2c_observer_trans;

  // default constructor
  function new (string name = "wb8_i2c_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  /******* internal use variables ********/    
  // wishbone command decoder
  bit       wb_packet_ready;
  bit [6:0] i2c_devaddr;
  bit [7:0] i2c_regaddr;
  bit [7:0] i2c_data;
  bit       i2c_rw;
  bit       i2c_stop = 0;
  bit       i2c_increment = 0, i2c_prev_increment = 0;
  int       increment_val = 0;
  bit [6:0] temp_devaddr;
  bit [7:0] temp_data;
  // wishbone to i2c state
  typedef enum {IDLE, RW_WAIT, READ, WRITE} state_t;
  state_t state = IDLE;
  // wishbone to i2c decoder function
  extern function void wb_i2c_decode(bit [2:0] wb_addr, bit [7:0] wb_data, bit wb_rw);

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    wb_observer = new("wb_observer", this);
    i2c_observer = new("i2c_observer", this);
  endfunction

  task run_phase (uvm_phase phase);
      forever begin
          fork
              // wait for wb_observer object
              begin
                while(!wb_packet_ready) begin
                  // get primal data (carrier)
                  wb_observer.get(wb_observer_trans_primal);
                  // recast carrier data to child
                  $cast(wb_observer_trans, wb_observer_trans_primal);
                  // decode i2c signals based on wb input
                  wb_i2c_decode(wb_observer_trans.addr, wb_observer_trans.data, wb_observer_trans.rw);
                end
                wb_packet_ready = 0;
              end
              // wait for i2c_observer object
              begin
                  // get primal data (carrier)
                  i2c_observer.get(i2c_observer_trans_primal);
                  // recast carrier data to child
                  $cast(i2c_observer_trans, i2c_observer_trans_primal);
              end
          join

          // check monitoring objects
          if ((i2c_regaddr + increment_val == i2c_observer_trans.addr) && (i2c_rw == i2c_observer_trans.rw) && (i2c_data == i2c_observer_trans.data))
              `uvm_info("SCOREBOARD", $sformatf("Monitoring objects comply. addr:0x%2h, cmd:0x%1h, data:0x%2h", i2c_regaddr + increment_val, i2c_rw, i2c_data), UVM_MEDIUM)
          else 
              `uvm_warning("SCOREBOARD", $sformatf("Monitoring objects don't comply. wb[addr:0x%2h, cmd:0x%1h, data:0x%2h]; i2c[addr:0x%2h, cmd:0x%1h, data:0x%2h]", i2c_regaddr + increment_val, i2c_rw, i2c_data, i2c_observer_trans.addr, i2c_observer_trans.rw, i2c_observer_trans.data))
      end   
  endtask
  
endclass

`endif