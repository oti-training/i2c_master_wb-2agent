/*
* File: axil_interface.sv
*
* This file defines the AXI-Lite interface used in the testbench.
*
* TODO:
* - Add assertions to check AXI-Lite protocol compliance
* - Consider adding more helper tasks for common operations
*
* NOTE: The current implementation is basic. It could be enhanced with
* additional features like built-in protocol checking.
*/
`ifndef AXIL_INTERFACE
`define AXIL_INTERFACE

interface axil_if(input logic clk, rst);
    logic [3:0]  awaddr;
    logic [2:0]  awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    logic [3:0]  araddr;
    logic [2:0]  arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        output awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
        output araddr, arprot, arvalid, rready;
        input  awready, wready, bresp, bvalid;
        input  arready, rdata, rresp, rvalid;
    endclocking

    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        input awaddr, awprot, awvalid, wdata, wstrb, wvalid, bready;
        input araddr, arprot, arvalid, rready;
        input awready, wready, bresp, bvalid;
        input arready, rdata, rresp, rvalid;
    endclocking


    modport driver(clocking driver_cb);
    modport monitor(clocking monitor_cb);
endinterface

`endif
