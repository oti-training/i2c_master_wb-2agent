/* 
* File: register defines.svh
* 
* This file defines the register map and associated structures for the AXI-Lite to I2C Master Bridge.
* 
* Key Features:
*   - Defines register addresses as an enumerated type for easy reference and maintainance.
*   - Defines bit-field structures for status and control registers.
*   - Provides enumeration for command flags and data flags used in register operations.
*   
* The definitions in this file are crucial for:
*   - Proper addressing of registers in the DUT.
*   - Correct interpretation of register contents.
*   - Consistent usage of command and data flags across the testbench and DUT.
* 
* These definitions serve as a single source of truth for register-related information, ensuring consistency between the RTL, verification environment, and potentially software drivers. 
*/

`ifndef REG_DEFINES
`define REG_DEFINES

// Register address map
typedef enum bit [3:0] {
	STATUS_REG   = 4'h0, // Status register address
	CMD_REG      = 4'h4, // Command register address
	DATA_REG     = 4'h8, // Data register address
	PRESCALE_REG = 4'hc  // Prescaler register address
} reg_addr_t;

// Control register structure
typedef struct packed {
	bit [31:1] reserved; // Reserved bits
	bit        enable;   // Enable bit for the I2C master
} ctrl_reg_t;

// Status register structure
typedef struct packed {
	bit [31:4] reserved;  // Reserved bits
	bit        cmd_full;  // Command FIFO full flag
	bit        cmd_empty; // Command FIFO empty flag
	bit        busy;      // I2C bus busy flag
	bit        error;     // Error flag
} status_reg_t;

// Command register flags
typedef enum bit [4:0] {
	CMD_STOP	= 5'h10,    // Stop condition
	CMD_WR_M	= 5'h8,     // Write multiple bytes
	CMD_WRITE	= 5'h4,     // Write operation
	CMD_READ	= 5'h2,     // Read operation
	CMD_START	= 5'h1      // Start condition
} reg_cmd_flag_t;

// Data register flags
typedef enum bit [1:0] {
	DATA_LAST		= 2'h2,   // Last byte flag
	DATA_VALID		= 2'h1, // Data valid flag
	DATA_DEFAULT	= 2'h0  // Default state
} reg_data_flag_t;

`endif
	
