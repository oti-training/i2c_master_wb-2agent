`ifndef AXIL_I2C_REF_MODEL_SV
`define AXIL_I2C_REF_MODEL_SV

class axil_i2c_ref_model extends uvm_component;
    `uvm_component_utils(axil_i2c_ref_model)

    uvm_analysis_imp #(axil_seq_item, axil_i2c_ref_model) axil_in;
    uvm_analysis_port #(i2c_trans) i2c_out;

    // Internal registers
    bit [31:0] status_reg;
    bit [31:0] cmd_reg;
    bit [31:0] data_reg;
    bit [31:0] prescale_reg;

    // I2C transaction in progress
    i2c_trans current_i2c_trans;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axil_in = new("axil_in", this);
        i2c_out = new("i2c_out", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void write(axil_seq_item item);
        process_axil_transaction(item);
    endfunction

    function void process_axil_transaction(axil_seq_item item);
        if (item.read) begin
            case (item.addr)
                STATUS_REG:   item.data = status_reg;
                CMD_REG:      item.data = cmd_reg;
                DATA_REG:     item.data = data_reg;
                PRESCALE_REG: item.data = prescale_reg;
            endcase
        end else begin
            case (item.addr)
                STATUS_REG:   status_reg = item.data;
                CMD_REG:      begin
                    cmd_reg = item.data;
                    process_command_register();
                end
                DATA_REG:     begin
                    data_reg = item.data;
                    process_data_register();
                end
                PRESCALE_REG: prescale_reg = item.data;
            endcase
        end
    endfunction

    function void process_command_register();
      if (cmd_reg[CMD_START]) begin
          current_i2c_trans = i2c_trans::type_id::create("current_i2c_trans");
          current_i2c_trans.addr = cmd_reg[6:0];
          current_i2c_trans.read = cmd_reg[CMD_READ];
          `uvm_info("REF_MODEL", $sformatf("Generated I2C transaction: %s", current_i2c_trans.convert2string()), UVM_LOW)
      end

        if (cmd_reg[CMD_STOP] && current_i2c_trans != null) begin
            i2c_out.write(current_i2c_trans);
            current_i2c_trans = null;
        end
    endfunction

    function void process_data_register();
        if (current_i2c_trans != null) begin
            if (!current_i2c_trans.read) begin
                current_i2c_trans.data = data_reg[7:0];
            end
            
            if (data_reg[DATA_LAST]) begin
                i2c_out.write(current_i2c_trans);
                current_i2c_trans = null;
            end
        end
    endfunction

endclass

`endif
