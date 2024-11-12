`include "uvm_macros.svh"
`include "../common/i2c_interface.sv"
`include "wb16_top_interface.sv"

module wb16_tb_top;
  import uvm_pkg::*;
  import wb16_pkg::*;
  
  logic clk;

  // Instantiate the interface
  wb16_interface wb16_interface_inst(clk);
  i2c_interface i2c_if(clk);
  
  // Instantiate the DUT and connect it to the interface
  i2c_master_wbs_16_interfaced dut(wb16_interface_inst, i2c_if);

  // Clock and reset control
  initial begin
    clk = 0;
    forever begin
      #5;
      clk = ~clk;
    end
  end
  
  initial begin
    // Place the interface into the UVM configuration database
    uvm_config_db#(virtual wb16_interface)::set(null, "*", "wb16_vif", wb16_interface_inst);
    uvm_config_db#(virtual i2c_interface)::set(null, "*", "i2c_vif", i2c_if);
    // Start the test
    run_test("wb16_i2c_test");
  end
  
  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, wb16_tb_top);
  end
  
endmodule
