`include "uvm_macros.svh"
`include "../common/i2c_interface.sv"
`include "top_interface.sv"

module wb8_tb_top;
  import uvm_pkg::*;
  import wb8_pkg::*;
  
  logic clk;

  // Instantiate the interface
  top_interface top_interface_inst(clk);
  i2c_interface i2c_if(clk);
  
  // Instantiate the DUT and connect it to the interface
  i2c_master_wbs_8_interfaced dut(top_interface_inst, i2c_if);

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
    uvm_config_db#(virtual top_interface)::set(null, "*", "top_vinterface", top_interface_inst);
    uvm_config_db#(virtual i2c_interface)::set(null, "*", "i2c_vif", i2c_if);
    // Start the test
    run_test("wb_master_test");
  end
  
  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, wb8_tb_top);
  end
  
endmodule