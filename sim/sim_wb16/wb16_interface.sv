/**
 * Top Level DUT's Interface
 */
interface wb16_if(input logic clk, input logic rst);

// Generic signals
// logic        rst;

// Host interface
logic  [2:0] wbs_adr_i;   // ADR_I() address
logic  [15:0] wbs_dat_i;   // DAT_I() data in
logic  [15:0] wbs_dat_o;   // DAT_O() data out
logic        wbs_we_i;    // WE_I write enable input
logic  [1:0] wbs_sel_i;   
logic        wbs_stb_i;   // STB_I strobe input
logic        wbs_ack_o;   // ACK_O acknowledge output
logic        wbs_cyc_i;   // CYC_I cycle input

// I2C interface
// logic        i2c_scl_i;
// logic        i2c_scl_o;
// logic        i2c_scl_t;
// logic        i2c_sda_i;
// logic        i2c_sda_o;
// logic        i2c_sda_t;

// Responder interface
// logic        resp_sda_o;


/**
 * Modports
 */
// master agent driver
modport driver(
    // Generic signals
    input           clk,
    output          rst,

    // Host interface
    output          wbs_adr_i,
    output          wbs_dat_i,
    input           wbs_dat_o,
    output          wbs_we_i,
    output          wbs_sel_i,
    output          wbs_stb_i,
    input           wbs_ack_o,
    output          wbs_cyc_i

    // I2C interface
    // input           i2c_scl_i,
    // input           i2c_scl_o,
    // input           i2c_scl_t,
    // input           i2c_sda_i,
    // input           i2c_sda_o,
    // input           i2c_sda_t
);
// slave agent driver
modport driver_slave(
    // Generic signals
    input           clk,
    input          rst,

    // Host interface
    input          wbs_adr_i,
    input          wbs_dat_i,
    input           wbs_dat_o,
    input          wbs_we_i, 
    input          wbs_stb_i,
    input           wbs_ack_o,
    input          wbs_cyc_i

    // I2C interface
    // output          i2c_scl_i,
    // input           i2c_scl_o,
    // input           i2c_scl_t,
    // output          i2c_sda_i,
    // input           i2c_sda_o,
    // input           i2c_sda_t,

    // output          resp_sda_o
);
// monitor
modport monitor(
    // Generic signals
    input           clk,
    input           rst,

    // Host interface
    input           wbs_adr_i,
    input           wbs_dat_i,
    input           wbs_dat_o,
    input           wbs_we_i, 
    input           wbs_stb_i,
    input           wbs_ack_o,
    input           wbs_cyc_i

    // I2C interface
    // input           i2c_scl_i,
    // input           i2c_scl_o,
    // input           i2c_scl_t,
    // input           i2c_sda_i,
    // input           i2c_sda_o,
    // input           i2c_sda_t
);
endinterface

/**
 * Interfaced Top Level DUT
 */
module i2c_master_wbs_16_interfaced (wb16_interface top_if, i2c_interface i2c_if);

// copied this from the documentation
assign scl_dut_i = scl_dut_o & scl_tb_o;
assign scl_tb_i = scl_dut_o & scl_tb_o;
assign sda_dut_i = sda_dut_o & sda_tb_o;
assign sda_tb_i = sda_dut_o & sda_tb_o;

// connect the above logic to the interface
assign scl_tb_o = 1'b1; 
assign sda_tb_o = i2c_if.sda_o;
assign i2c_if.scl_i = scl_tb_i;
assign i2c_if.sda_i = sda_tb_i;

// DUT
i2c_master_wbs_16 DUT(
    // Generic signals
    .clk(top_if.clk),
    .rst(top_if.rst),

    // Host interface
    .wbs_adr_i(top_if.wbs_adr_i),
    .wbs_dat_i(top_if.wbs_dat_i),
    .wbs_dat_o(top_if.wbs_dat_o),
    .wbs_we_i(top_if.wbs_we_i),
    .wbs_sel_i(top_if.wbs_sel_i), 
    .wbs_stb_i(top_if.wbs_stb_i),
    .wbs_ack_o(top_if.wbs_ack_o),
    .wbs_cyc_i(top_if.wbs_cyc_i),

    // I2C interface
    .i2c_scl_i(scl_dut_i),
    .i2c_scl_o(scl_dut_o),
    .i2c_scl_t(top_if.i2c_scl_t),
    .i2c_sda_i(sda_dut_i),
    .i2c_sda_o(sda_dut_o),
    .i2c_sda_t(top_if.i2c_sda_t)
);
endmodule