/* 
* File: wb16_tb_top.sv
* 
* This is the top-level testbench module for the WB16 to I2C Master Bridge verification environment.
* 
* Key Features:
* - Sets up the main simulation environment, including clock generation and reset logic.
* - Instantiates and connects the Device Under Test (DUT) - an I2C master with WB16 interface.
* - Creates and connects virtual interfaces for both WB16 and I2C protocols.
* - Manages the UVM test execution flow.
* 
* The testbench performs the following main tasks:
* 1. Generates clock and reset signals for the DUT and interfaces.
* 2. Sets up virtual interfaces for WB16 and I2C communications.
* 3. Instantiates the DUT (i2c_master_wb16) with appropriate parameters.
* 4. Connects the DUT to the virtual interfaces.
* 5. Configures the UVM environment by setting interface handles in the config_db.
* 6. Initiates the UVM test execution.
* 7. Sets up waveform dumping for debug purposes.
*
* This testbench serves as the entry point for all verification scenarios targeting
* the WB16 to I2C Master bridge functionality.
 * TODO: 
 * 1. Consider parameterizing the clock period for easier configuration.
 * 2. Add assertions to verify correct reset behavior.
 * 3. Implement a more robust timeout mechanism for test completion.
 *
 * BEST PRACTICE:
 * - Use SystemVerilog interfaces consistently for all DUT connections.
 * - Consider using a package for all parameter definitions instead of `include.
 *
 * IMPLEMENTATION NOTE:
 * The open-drain emulation for I2C lines is a good practice for accurate simulation.
 */
`ifndef WB16_TB_TOP
`define WB16_TB_TOP

`include "../common/i2c_interface.sv"
`include "wb16_interface.sv"
`include "wb16_dut_params_defines.svh"

module wb16_tb_top;
	import uvm_pkg::*;
	import wb16_test_pkg::*;
    
    // Clock and Reset
    reg clk; // Toggles every 5 time units
    reg rst; // Reset signal
    
    // Clock generation: 100MHz clock (5ns high, 5ns low)
    initial begin
        clk =  0; 
        forever #5 clk = ~clk; 
    end
    // TODO: Add assertion for reset
    // assert property (@(posedge clk) $rose(rst) |-> ##[1:10] !rst);

    // Reset generation: Active high reset for 100ns
    initial begin
        rst = 1;     
        #10;        
        rst = 0;     
    end
    
    // Interfaces instantiated and connected
    i2c_interface  i2c_if(clk);
    wb16_if wb16_vif(clk, rst);

    // copied this from the documentation
    assign scl_dut_i = scl_dut_o & scl_tb_o;
    assign scl_tb_i = scl_dut_o & scl_tb_o;
    assign sda_dut_i = sda_dut_o & sda_tb_o;
    assign sda_tb_i = sda_dut_o & sda_tb_o;
    
    // connect the above logic to the interface

    // Connect testbench signals to I2C interface
    assign scl_tb_o = i2c_if.scl_o; 
    assign sda_tb_o = i2c_if.sda_o;
    assign i2c_if.scl_i = scl_tb_i;
    assign i2c_if.sda_i = sda_tb_i;

    // Instantiate the DUT (I2C master with WB16 interface)
    i2c_master_wbs_16 DUT(
        // Generic signals
        .clk(clk),
        .rst(rst),

        // Host interface
        .wbs_adr_i(wb16_vif.wbs_adr_i),
        .wbs_dat_i(wb16_vif.wbs_dat_i),
        .wbs_dat_o(wb16_vif.wbs_dat_o),
        .wbs_sel_i(wb16_vif.wbs_sel_i),
        .wbs_we_i(wb16_vif.wbs_we_i), 
        .wbs_stb_i(wb16_vif.wbs_stb_i),
        .wbs_ack_o(wb16_vif.wbs_ack_o),
        .wbs_cyc_i(wb16_vif.wbs_cyc_i),

        // I2C interface
        .i2c_scl_i(scl_dut_i),
        .i2c_scl_o(scl_dut_o),
        .i2c_scl_t(i2c_if.scl_t),
        .i2c_sda_i(sda_dut_i),
        .i2c_sda_o(sda_dut_o),
        .i2c_sda_t(i2c_if.sda_t)
    );

  // UVM configuration and test execution
	initial begin
		uvm_top.set_report_verbosity_level_hier(UVM_LOW);

    // Set virtual interfaces in the UVM configuration database
		uvm_config_db#(virtual i2c_interface)::set(null, "*", "i2c_vif", i2c_if);
		uvm_config_db#(virtual wb16_if)::set(null, "*", "wb16_vif", wb16_vif);

    // Start UVM phases and run the test
		run_test("wb16_basic_test");
	end


    // Waveform dumping for debug
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, wb16_tb_top);
    end

endmodule

`endif
