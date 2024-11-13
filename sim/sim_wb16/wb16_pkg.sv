package wb16_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"

    // compile order
    `include "wb16_sequence_item.sv"
    `include "wb16_config.sv"
    `include "wb16_sequence.sv"
    `include "wb16_sequence_slave.sv"
    `include "wb16_monitor.sv"
    `include "wb16_driver.sv"
    `include "wb16_driver_slave.sv"
    `include "wb16_agent.sv"
    `include "wb16_agent_slave.sv"
    `include "wb16_scoreboard.sv"
    `include "wb16_coverage.sv"
    `include "wb16_environment.sv"
    `include "wb16_test.sv"
endpackage