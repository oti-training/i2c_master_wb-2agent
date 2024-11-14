// Coverage types:
// Multiple bytes, single bytes,
// Permutative operations example bins twoops[] = ([add_op:mul_op] [* 2]);
// Later: reset to operation & operation to reset
`ifndef I2C_COVERAGE
`define I2C_COVERAGE
class i2c_coverage extends uvm_subscriber #(i2c_transaction);
  `uvm_component_utils(i2c_coverage)

  i2c_transaction trans;
  covergroup slave_address_cg;
    slave_addr_cp: coverpoint trans.slave_addr {
      bins low = {[0:31]};
      bins mid = {[32:95]};
      bins high = {[96:127]};
      option.auto_bin_max = 128;  // Ensure all 7-bit addresses are covered
    }
  endgroup

  covergroup payload_data_cg;
    payload_size_cp: coverpoint trans.payload_data.size() {
      // bins empty = {0};
      bins low = {[1:5]};
      bins mid = {[6:20]};
      bins high = {[21:50]};
      bins extra_high = {[51:$]};
    }

    payload_value_cp: coverpoint trans.payload_data[0] {
      bins zeros = {8'h00};
      bins ones = {8'hFF};
      bins low = {[8'h01:8'h7F]};
      bins high = {[8'h80:8'hFE]};
    }

    payload_pattern_cp: coverpoint trans.payload_data[0] {
      bins alternating = {8'b10101010, 8'b01010101};
      bins all_ones = {8'b11111111};
      bins all_zeros = {8'b00000000};
      bins random = default;
    }
  endgroup

  covergroup transaction_direction_cg;
    direction_cp: coverpoint trans.is_write {
      bins write = {1};
      bins read = {0};
    }
  endgroup

  covergroup combined_cg;
    slave_addr_cp: coverpoint trans.slave_addr {
      bins low = {[0:31]};
      bins mid = {[32:95]};
      bins high = {[96:127]};
    }

    payload_size_cp: coverpoint trans.payload_data.size() {
      bins empty = {0};
      bins low = {[1:5]};
      bins mid = {[6:20]};
      bins high = {[21:$]};
    }

    direction_cp: coverpoint trans.is_write;

    addr_dir_cross: cross slave_addr_cp, direction_cp;
    size_dir_cross: cross payload_size_cp, direction_cp;
    addr_size_cross: cross slave_addr_cp, payload_size_cp;

    addr_size_dir_cross: cross slave_addr_cp, payload_size_cp, direction_cp {
      ignore_bins ignore_empty_writes = binsof(payload_size_cp) intersect {0} && 
                                        binsof(direction_cp) intersect {1};
    }
  endgroup

  // slave_address_cg sa_cg;
  // payload_data_cg pd_cg;
  // transaction_direction_cg td_cg;
  // combined_cg c_cg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    slave_address_cg = new();
    payload_data_cg = new();
    transaction_direction_cg = new();
    combined_cg = new();
  endfunction

  function void write(i2c_transaction t);
    trans = t;
    slave_address_cg.sample();
    payload_data_cg.sample();
    transaction_direction_cg.sample();
    combined_cg.sample();
  endfunction
endclass
`endif
