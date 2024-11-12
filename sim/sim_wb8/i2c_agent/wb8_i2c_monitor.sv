/*  
* File: wb8_i2c_monitor.sv
*
* This file implements the I2C monitor component for the verification
* environment.
* The I2C monitor observes the I2C bus transactions and converts them into
* transaction objects for analysis by other components of the testbench
*
* Key Features:
* - Monitors both SCL and SDA lines of the I2C interface
* - Detects START and STOP conditions
* - Captures address, read/write bit, and data bytes 
* - Packages observed transactions into i2c_trans objects
* - Broadcasts captured transactions via analysis port
*
* TODO:
* - Implement clock stretching detection and handling
* - Add support for 10-bit addressing mode
* - Implement multi-master arbitration monitoring
* - Add bus busy/idle state tracking
*
* 
* Notes on current implementation:
* - The monitor assumes a standard 7-bit addressing mode
* - It doesn't currently handle repeated START conditions
* - There's no explicit error checking for protocol violations
* - The monitor might miss transactions if sampling rate is not sufficient
*  
* Potential improvements:
* - Use a configurable sampling rate for better accuracy
* - Implement a state machine for more robust transaction tracking
* - Add configuration options for different I2C modes (standard, fast, high-speed)
* - Include more detailed reporting and error logging
*
* Best practice considerations:
* - Consider breaking down long tasks into smaller, more manageable sub-tasks
* - Add more inline comments explaining the logic of complex operations
* - Implement proper error handling and recovery mechanisms
* - Use `uvm_info` with different verbosity levels for debug information
* - Consider adding coverage collection directly in the monitor
*
*/
`ifndef WB8_I2C_MONITOR_SV
`define WB8_I2C_MONITOR_SV

class wb8_i2c_monitor extends uvm_monitor;
    virtual i2c_interface vif;
    uvm_analysis_port #(i2c_trans) ap;
    
    `uvm_component_utils(wb8_i2c_monitor)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Retrieve the virtual interface from the UVM configuration database
        if(!uvm_config_db#(virtual i2c_interface)::get(this, "", "i2c_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction

    // Wait for a START condition on the I2C bus
    task wait_for_start();
        @(negedge vif.sda_i iff vif.scl_i === 1);  
        `uvm_info("I2C_MON", "START condition detected", UVM_HIGH)
    endtask

    // Receive a byte from the I2C bus
    task receive_byte(output bit [7:0] data);
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_i);  
            // Should check both sda_i and sda_o depending on who's driving
            data[i] = vif.sda_t ? vif.sda_o : vif.sda_i;

            `uvm_info("I2C_MON", $sformatf("Bit[%0d]=%b at time %0t", i, data[i], $time), UVM_HIGH)
            wait(!vif.scl_i);
        end
    endtask

    // Receive a byte from the I2C bus and check for STOP condition
    task receive_byte_with_stop(output bit [7:0] data, output bit is_stop);
        is_stop = 0;
        for(int i = 7; i >= 0; i--) begin
            @(posedge vif.scl_i);  
            data[i] = vif.sda_i;

            // Detect stop condition
            if ((i == 7) && !vif.sda_i) begin
                wait(!vif.scl_i || vif.sda_i);
                if (vif.sda_i) begin
                    is_stop = 1;
                    `uvm_info("I2C_MON", "Stop condition detected", UVM_HIGH)
                    break;
                end
            end
            
            wait(!vif.scl_i);
        end
    endtask

    // Monitor ACK or NACK bit
    task monitor_ack();
        @(posedge vif.scl_i);
        // Check based on who's driving (master or slave)
        if (vif.sda_t ? vif.sda_o : vif.sda_i)
            `uvm_info("I2C_MON", "NACK received", UVM_HIGH)
        else
            `uvm_info("I2C_MON", "ACK received", UVM_HIGH)
        wait(!vif.scl_i);
    endtask

    // Main monitoring task
    task run_phase(uvm_phase phase);
        bit [7:0] addr_byte;
        bit [7:0] data_byte;
        bit is_stop;
        
        forever begin
            i2c_trans trans;
            
            wait_for_start();
            trans = i2c_trans::type_id::create("trans");
            
            // Address Phase
            receive_byte(addr_byte);
            `uvm_info("I2C_MON", $sformatf("Address Phase: 0x%02h [%s]", 
                addr_byte[7:1], addr_byte[0] ? "READ" : "WRITE"), UVM_HIGH)
            
            monitor_ack();
            
            trans.addr = addr_byte[7:1];
            trans.read = addr_byte[0];
            
            // Data Phase
            if (trans.read) begin
                // Read Operation
                do begin
                    receive_byte_with_stop(data_byte, is_stop);
                    if (!is_stop) begin
                        trans.data = data_byte;
                        `uvm_info("I2C_MON", 
                            $sformatf("Read Data: 0x%02h from addr 0x%02h", 
                            data_byte, trans.addr), UVM_HIGH)
                        monitor_ack();
                        ap.write(trans);
                    end
                end while (!is_stop);
            end else begin
                // Write Operation
                receive_byte_with_stop(data_byte, is_stop);
                while (!is_stop) begin
                    trans.data = data_byte;
                    `uvm_info("I2C_MON", 
                        $sformatf("Write Data: 0x%02h to addr 0x%02h", 
                        data_byte, trans.addr), UVM_HIGH)
                    monitor_ack();
                    ap.write(trans);
                    receive_byte_with_stop(data_byte, is_stop);
                end
            end
        end
    endtask
endclass

`endif