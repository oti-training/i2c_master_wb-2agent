package packages;
    import uvm_pkg::*;

    
    // compile order
    `include "config.svh"
    `include "sequence.svh"
    `include "sequence_slave.svh"
    `include "monitor.svh"
    `include "driver.svh"
    `include "driver_slave.svh"
    `include "agent.svh"
    `include "agent_slave.svh"
    `include "scoreboard.svh"
    `include "environment.svh"
    `include "test.svh"
endpackage