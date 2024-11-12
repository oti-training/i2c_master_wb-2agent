/*
* File: i2c_responder.sv
*
* This file implements an I2C slave responder for the testbench environment.
* It simulates the behavior of an I2C slave device, responding to I2C transactions
* initiated by the Device Under Test (DUT) acting as an I2C master.
*
* Key Features:
* - Implements a simple memory model to store and retrieve data.
* - Responds to I2C read and write operations.
* - Configurable slave address (default: 0x50).
* - Monitors I2C bus for start conditions and handles subsequent communication.
*
* Operation:
* 1. Waits for I2C start condition.
* 2. Receives address byte and checks if it matches its own address.
* 3. Responds to read/write commands by either sending or receiving data.
* 4. Handles stop conditions to end transactions.
*
* TODO:
* - Implement multi-byte read/write operations more robustly.
* - Add support for clock stretching to simulate slow slave devices.
* - Enhance error handling and reporting for invalid I2C sequences.
*
* NOTE: This implementation, while functional, has some areas that could be improved:
* - The use of fixed delays (e.g., @(vif.clk)) may not accurately represent real I2C timing.
*   Consider implementing a more precise timing model.
* - Error injection capabilities are limited. Adding controlled error injection would enhance test coverage.
* - The memory model is simplistic. For more complex scenarios, consider implementing a more sophisticated memory model with different regions and access patterns.
* - Compliance with UVM methodology could be improved by using analysis ports to report 
*   observed transactions, enhancing overall testbench observability.
*/

`ifndef I2C_RESPONDER
`define I2C_RESPONDER

class i2c_responder extends uvm_component;
    virtual i2c_interface vif;
    bit [7:0] memory[bit [7:0]]; // Simple memory model
    bit [6:0] my_address;
    
    `uvm_component_utils(i2c_responder)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        my_address = 7'h50; // Default address
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", vif))
            `uvm_fatal("NO_VIF", "Failed to get I2C virtual interface")
    endfunction
    
    // Detect I2C start condition
    task monitor_start_condition();
        @(negedge vif.sda_i iff vif.scl_i === 1);  
        `uvm_info("I2C_RESP", "START condition detected", UVM_MEDIUM)
    endtask
    
    // Receive a byte from I2C bus
    task receive_byte(output bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_i);  
            data[i] = vif.sda_i;
            `uvm_info("I2C_RESP", $sformatf("[%t] received bit %d = %d", $time, i, data[i]), UVM_HIGH)
			wait (!vif.scl_i);
        end
    endtask
    
    // Receive a byte with potential stop condition detection
    task receive_byte_with_stop(output bit [7:0] data, output bit is_stop);
		is_stop = 0;
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_i);  
            data[i] = vif.sda_i;

			// detect stop condition
			if ((i == 7) & !vif.sda_i) begin
				wait (!vif.scl_i | vif.sda_i);
				if (vif.sda_i) begin
					is_stop = 1;
            		`uvm_info(get_type_name(), "stop bit detected", UVM_MEDIUM)
            		`uvm_info(get_type_name(), "stop bit detected", UVM_MEDIUM)
					break;
				end
			end

            `uvm_info(get_type_name(), $sformatf("[%t] bit %d = %d", $time, i, data[i]), UVM_HIGH)
			wait (!vif.scl_i);
        end
    endtask
    
    // Send ACK
    task send_ack();
        repeat (6) @(vif.clk);     // Wait for a short time
        vif.sda_o <= 0;            // Pull SDA low for ACK
        wait (vif.scl_i);          // Wait for SCL rising edge
        wait (!vif.scl_i);         // Wait for SCL falling edge
        repeat (3) @(vif.clk);     // Wait for a short time
        vif.sda_o <= 1;            // Release SDA
    endtask

    task send_byte(bit [7:0] data);
        `uvm_info("I2C_RESP", "send byte start", UVM_HIGH)
        `uvm_info("I2C_RESP", "send byte start", UVM_HIGH)
        for(int i = 7; i >= 0; i--) begin
            vif.sda_o <= data[i]; // Set SDA to bit value
            `uvm_info("I2C_RESP", $sformatf("[%t] sent bit %d = %d", $time, i, data[i]), UVM_HIGH)
            wait (vif.scl_i);      // Wait for SCL rising edge
            wait (!vif.scl_i);     // Wait for SCL falling edge
        end
        vif.sda_o <= 1;            // Release SDA
    endtask

    // Main run task
    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] reg_byte;
        bit [7:0] data_byte;
		bit is_write;
		bit is_stop;
        
        vif.sda_o <= 1;  // Initialize SDA to idle state
        vif.scl_o <= 1;  // Initialize SCL to idle state
        
        forever begin
            monitor_start_condition();
            
            receive_byte(addr_byte);
            
            if((addr_byte[7:1] == my_address)) begin
                send_ack();
				is_write = !addr_byte[0];

				if (is_write) begin
          // Write operation
					receive_byte(reg_byte);
					send_ack();
					
					receive_byte_with_stop(data_byte, is_stop);

					while (!is_stop) begin
						memory[reg_byte] = data_byte;
						send_ack();
						`uvm_info("I2C_RESP", $sformatf("Received data: %h", data_byte), UVM_LOW)
						reg_byte++;
						receive_byte_with_stop(data_byte, is_stop);
					end
				end
				else begin
          // Read operation
					send_byte(memory[reg_byte]);
					`uvm_info("I2C_RESP", $sformatf("Send data: %h", memory[reg_byte]), UVM_LOW)
				end
            end
        end
    endtask

    // Utility function to set memory values
    function void set_memory(bit [6:0] addr, bit [7:0] data);
        memory[addr] = data;
    endfunction
    
    // Utility function to get memory values
    function bit [7:0] get_memory(bit [6:0] addr);
        return memory[addr];
    endfunction
endclass

`endif
