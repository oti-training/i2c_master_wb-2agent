#!/bin/bash

BUILD_DIR="./build"
mkdir -p $BUILD_DIR

rm -rf $BUILD_DIR/xsim.dir
rm -f $BUILD_DIR/*.log $BUILD_DIR/*.jou $BUILD_DIR/*.pb $BUILD_DIR/*.wdb

echo "\`timescale 1ns/1ps" > $BUILD_DIR/uvm_precompile.sv

cd $BUILD_DIR

# Compile UVM precompile file
xvlog -sv -L uvm uvm_precompile.sv

# Compile package files
xvlog -sv -L uvm ../sim/sim_axil/dut_params_defines.svh
xvlog -sv -L uvm ../sim/sim_axil/register_defines.svh
xvlog -sv -L uvm ../sim/sim_axil/i2c_master_axil_pkg.sv
xvlog -sv -L uvm ../sim/sim_axil/i2c_agent/axil_i2c_agent_pkg.sv
xvlog -sv -L uvm ../sim/sim_axil/axil_agent/axil_agent_pkg.sv

xvlog -sv -L uvm ../sim/common/i2c/common_i2c_pkg.sv
xvlog -sv -L uvm ../sim/common/sequences/common_seq_lib.sv
xvlog -sv -L uvm ../sim/common/utils/common_utils_pkg.sv
xvlog -sv -L uvm ../sim/sim_axil/env/axil_bridge_env_pkg.sv

xvlog -sv -L uvm ../sim/sim_axil/sequences/axil_seq_list.sv
xvlog -sv -L uvm ../sim/sim_axil/tests/axil_test_pkg.sv
# Compile interface and DUT files
xvlog -sv -L uvm ../sim/common/i2c_interface.sv
xvlog -sv -L uvm ../sim/sim_axil/axil_interface.sv
xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_axil.v ../rtl/axis_fifo.v

# Compile testbench top
xvlog -sv -L uvm ../sim/sim_axil/axil_tb_top.sv

# Elaborate
xelab -L uvm -timescale 1ns/1ps -debug typical axil_tb_top -s axil_tb_top

# Run simulation
xsim -R axil_tb_top -testplusarg "UVM_VERBOSITY=UVM_LOW" 

xcrg -dir ./xsim.covdb/ -report_format html -report_dir ./coverage_report

cd ..
