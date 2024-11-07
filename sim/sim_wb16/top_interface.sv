/**
 * Top Level DUT's Interface
 */
interface top_interface #(int size = 16);

// Generic signals
logic        clk;
logic        rst;

// Host interface
logic  [2:0] wbs_adr_i;   // ADR_I() address
logic  [size-1:0] wbs_dat_i;   // DAT_I() data in
logic  [size-1:0] wbs_dat_o;   // DAT_O() data out

logic [1:0] wbs_sel_i; // Only for Size == 16

logic        wbs_we_i;    // WE_I write enable input
logic        wbs_stb_i;   // STB_I strobe input
logic        wbs_ack_o;   // ACK_O acknowledge output
logic        wbs_cyc_i;   // CYC_I cycle input

// I2C interface
logic        i2c_scl_i;
logic        i2c_scl_o;
logic        i2c_scl_t;
logic        i2c_sda_i;
logic        i2c_sda_o;
logic        i2c_sda_t;

// Responder interface
logic        resp_sda_o;


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

    output wbs_sel_i,  // Only connected if WBS_16 is defined
    
    output          wbs_stb_i,
    input           wbs_ack_o,
    output          wbs_cyc_i,

    // I2C interface
    input           i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    input           i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t
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
    input          wbs_cyc_i,

    // I2C interface
    output          i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    output          i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t,

    output          resp_sda_o
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
    input           wbs_cyc_i,

    // I2C interface
    input           i2c_scl_i,
    input           i2c_scl_o,
    input           i2c_scl_t,
    input           i2c_sda_i,
    input           i2c_sda_o,
    input           i2c_sda_t
);
endinterface

/**
 * Interfaced Top Level DUT
 */
module i2c_master_wbs_interfaced #(int size = 16) (top_interface top_if);

wire sda_i;
wire dut_sda_o;
wire scl_i;
wire dut_scl_o;

// connect scl and sda for inout operation
assign sda_i = dut_sda_o & top_if.resp_sda_o;
assign scl_i = dut_scl_o;

assign top_if.i2c_scl_i = scl_i;
assign top_if.i2c_sda_i = sda_i;
assign top_if.i2c_scl_o = dut_scl_o;
assign top_if.i2c_sda_o = dut_sda_o;

// DUT
if (size == 16) begin
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
        .i2c_scl_i(scl_i),
        .i2c_scl_o(dut_scl_o),
        .i2c_scl_t(top_if.i2c_scl_t),
        .i2c_sda_i(sda_i),
        .i2c_sda_o(dut_sda_o),
        .i2c_sda_t(top_if.i2c_sda_t)
    );
end

else if (size == 8) begin
    i2c_master_wbs_8 DUT(
    // Generic signals
    .clk(top_if.clk),
    .rst(top_if.rst),

    // Host interface
    .wbs_adr_i(top_if.wbs_adr_i),
    .wbs_dat_i(top_if.wbs_dat_i),
    .wbs_dat_o(top_if.wbs_dat_o),
    .wbs_we_i(top_if.wbs_we_i), 
    .wbs_stb_i(top_if.wbs_stb_i),
    .wbs_ack_o(top_if.wbs_ack_o),
    .wbs_cyc_i(top_if.wbs_cyc_i),

    // I2C interface
    .i2c_scl_i(scl_i),
    .i2c_scl_o(dut_scl_o),
    .i2c_scl_t(top_if.i2c_scl_t),
    .i2c_sda_i(sda_i),
    .i2c_sda_o(dut_sda_o),
    .i2c_sda_t(top_if.i2c_sda_t)
);
end

endmodule