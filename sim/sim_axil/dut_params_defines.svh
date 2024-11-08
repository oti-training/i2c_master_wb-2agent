/*
* File: dut_params_defines.svh
*
* This file defines the parameters used to configure the Device Under Test (DUT),
* which is an AXI-Lite to I2C Master Bridge.
*
* Key Features:
* - Defines default values for various DUT parameters.
* - Allows easy modification of DUT configuration for different test scenarios.
* - Includes parameters for prescaler settings, FIFO configurations, and depths.
*
* These parameters control aspects such as:
* - I2C clock generation (via prescaler settings)
* - Command, write, and read FIFO implementations and their depths
*
* By adjusting these parameters, testers can verify the DUT's behavior under
* different configurations without modifying the core RTL code.
*/

`ifndef DUT_PARAMS_DEFINES
`define DUT_PARAMS_DEFINES

// Default prescale value for I2C clock generation
parameter DEFAULT_PRESCALE = 1;

// Flag to indicate if prescale value is fixed (1) or configurable (0)
parameter FIXED_PRESCALE = 0;

// Enable (1) or disable (0) command FIFO 
parameter CMD_FIFO = 1;

// Depth of the command FIFO (when enabled)
parameter CMD_FIFO_DEPTH = 32;

// Enable (1) or disable (0) write data FIFO
parameter WRITE_FIFO = 1;

// Detph of the write data FIFO (when enabled)
parameter WRITE_FIFO_DEPTH = 32;

// Enable (1) or disable (0) read data FIFO
parameter READ_FIFO = 1;

// Depth of the read data FIFO (when enabled)
parameter READ_FIFO_DEPTH = 32;

`endif
