package wb8_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"

    // compile order
    `include "sequence_item.sv"
    `include "config.sv"
    `include "sequence.sv"
    `include "sequence_slave.sv"
    `include "monitor.sv"
    `include "driver.sv"
    `include "driver_slave.sv"
    `include "agent.sv"
    `include "agent_slave.sv"
    `include "scoreboard.sv"
    `include "coverage.sv"
    `include "environment.sv"
    `include "test.sv"
endpackage