

function void wb8_i2c_scoreboard::wb_i2c_decode(bit [2:0] wb_addr, bit [7:0] wb_data, bit wb_rw);
// TO BE DONE!!!
// 1. Be aware that WB finishes first, way before I2C due to FIFO implementation, so don't take read data from WB (check)
// 2. WB read needs to be delayed until read data is set from I2C, same reason as (1) (check)
// 3. Don't forget to implement address increment (check, needs to be reviewed)
    // input bit [2:0] wb_addr;
    // input bit [7:0] wb_data;
    // input bit       wb_rw;
    begin
        // `uvm_info("MONITOR TASK LOG", $sformatf("data:0x%2h, addr:0x%2h, wb_rw:0x%1h", wb_data, wb_addr, wb_rw), UVM_MEDIUM);
        

        // only wishbone write operation will affect I2C ports
        wb_packet_ready = 0;
        if (wb_rw) begin
            i2c_prev_increment = i2c_increment;
            case (state) 
                IDLE: begin
                    i2c_increment = 0;
                    case (wb_addr)
                        // 0: 
                        // 1: 
                        // device address reg
                        2: begin
                            temp_devaddr = wb_data[6:0];
                        end
                        // command reg
                        3: begin
                            if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                if (wb_data[2]) begin // write
                                    i2c_devaddr = temp_devaddr;
                                    i2c_regaddr = temp_data;

                                    if (i2c_devaddr == 7'h6) begin
                                        if (wb_data[4]) begin// stop
                                            state = IDLE;
                                        end
                                        else begin
                                            state = RW_WAIT;
                                            i2c_stop = 0;
                                        end
                                    end
                                end
                                else if (wb_data[1]) begin // read
                                    i2c_devaddr = temp_devaddr;
                                    i2c_regaddr = temp_data;

                                    if (i2c_devaddr == 7'h6) begin
                                        if (wb_data[4]) begin
                                            i2c_stop = 1;
                                            state = READ;
                                        end
                                        else begin
                                            i2c_stop = 0;
                                            state = READ;
                                        end
                                    end
                                end
                            end
                        end
                        // data reg
                        4: begin
                            temp_data = wb_data;
                        end
                    endcase
                end
                RW_WAIT: begin
                    i2c_increment = 0;
                    i2c_rw = 0; 
                    case (wb_addr)
                        // 0:
                        // 1:
                        // device address reg
                        2: begin
                            temp_devaddr = wb_data[6:0];
                        end
                        // command reg
                        3: begin
                            if (wb_data[2] ^ wb_data[1]) begin // only either read or write command
                                if (wb_data[0] && wb_data[1]) begin
                                    // next is read
                                    if (temp_devaddr!=i2c_devaddr) begin
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;
                                        state = IDLE;
                                    end
                                    else begin
                                        i2c_data = temp_data;
                                        i2c_rw = 0;

                                        i2c_increment = 1;

                                        if (wb_data[4]) state = IDLE;
                                        else begin
                                            state = READ;
                                        end
                                    end
                                end
                                else if (wb_data[2]) begin
                                    // next is write
                                    if (temp_devaddr!=i2c_devaddr) begin
                                        i2c_devaddr = temp_devaddr;
                                        i2c_regaddr = temp_data;
                                        state = IDLE;
                                    end
                                    else begin
                                        i2c_data = temp_data;
                                        i2c_rw = 1;

                                        // log read
                                        i2c_increment = 1;
                                        // by this time, the i2c packet is ready
                                        wb_packet_ready = 1;

                                        if (wb_data[4]) state = IDLE;
                                        else begin
                                            state = WRITE;
                                        end
                                    end
                                end
                                else begin
                                    // invalid command
                                    state = IDLE;
                                end
                            end
                        end
                        // data reg
                        4: begin
                            temp_data = wb_data;
                        end
                    endcase
                    if (i2c_stop) begin
                        state = IDLE;
                    end
                end
                READ: begin
                    i2c_rw = 0; 
                    case (wb_addr)
                        // 0:
                        // 1:
                        // device address reg
                        2: begin
                            temp_devaddr = wb_data[6:0];
                        end
                        // command reg
                        3: begin
                            if (wb_data[4]) i2c_stop = 1;
                            if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                if (temp_devaddr!=i2c_devaddr) begin
                                    i2c_devaddr = temp_devaddr;
                                    i2c_regaddr = temp_data;
                                    state = IDLE;
                                end
                                else if (wb_data[0]) begin // start
                                    if (wb_data[1]) begin // read
                                        i2c_data = temp_data;

                                        i2c_increment = 1;
                                    end
                                    else if (wb_data[2]) begin //write
                                        i2c_regaddr = temp_data;
                                        state = RW_WAIT;
                                        i2c_increment = 0;
                                    end
                                end
                                else begin // no start
                                    if (wb_data[1]) begin // read
                                        i2c_data = temp_data;

                                        // the address should be incrementing
                                        i2c_increment = 1;
                                    end
                                    else if (wb_data[2]) begin //write
                                        i2c_regaddr = temp_data;
                                        state = RW_WAIT;
                                        i2c_increment = 0;
                                    end
                                end
                            end
                        end
                        // data reg
                        4: begin
                            temp_data = wb_data;
                        end
                    endcase
                    if (i2c_stop) begin
                        state = IDLE;
                    end
                end
                WRITE: begin
                    i2c_rw = 1; 
                    case (wb_addr)
                        // 0:
                        // 1:
                        // device address reg
                        2: begin
                            temp_devaddr = wb_data[6:0];
                        end
                        // command reg
                        3: begin
                            if (wb_data[4]) i2c_stop = 1;
                            if (wb_data[2] ^ wb_data[1]) begin // write ^ read
                                if (temp_devaddr!=i2c_devaddr) begin
                                    i2c_devaddr = temp_devaddr;
                                    i2c_regaddr = temp_data;
                                    state = IDLE;
                                end
                                else if (wb_data[0]) begin // start
                                    if (wb_data[2]) begin // write
                                        i2c_devaddr = temp_devaddr;
                                        i2c_data = temp_data;
                                        i2c_increment = 0;

                                        state = RW_WAIT;
                                    end
                                    else if (wb_data[1]) begin // read
                                        i2c_regaddr = temp_data;
                                        state = READ;
                                        i2c_increment = 0;
                                    end
                                end
                                else begin // no start
                                    if (wb_data[2]) begin // write
                                        i2c_data = temp_data;

                                        // the address should be incrementing
                                        i2c_increment = 1;

                                        // by this time, the i2c packet is ready
                                        wb_packet_ready = 1;
                                    end
                                    else if (wb_data[1]) begin // read
                                        i2c_regaddr = temp_data;
                                        state = READ;
                                        i2c_increment = 0;
                                    end
                                end
                            end
                        end
                        // data reg
                        4: begin
                            temp_data = wb_data;
                        end
                    endcase
                    if (i2c_stop) begin
                        state = IDLE;
                    end
                end
            endcase
        end
        else if (wb_rw == 0) begin
            if (wb_addr == 4) begin
                i2c_data = wb_data;
                i2c_increment = 1;
                // by this time, the i2c packet is ready
                wb_packet_ready = 1;
            end
        end
    end
endfunction