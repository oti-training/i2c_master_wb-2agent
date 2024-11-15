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
xvlog -sv -L uvm ../sim/sim_wb16/wb16_pkg.sv

# Compile interface and DUT files
xvlog -sv -L uvm ../sim/sim_wb16/wb16_top_interface.sv
xvlog -sv -L uvm ../rtl/i2c_master_wbs_16.v

xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_wbs_16.v ../rtl/axis_fifo.v
# Compile testbench top
xvlog -sv -L uvm ../sim/sim_wb16/wb16_tb_top.sv

# Elaborate
xelab -L uvm -timescale 1ns/1ps -debug typical wb16_tb_top -s wb16_tb_top

# Run simulation
xsim -R wb16_tb_top -testplusarg "UVM_VERBOSITY=UVM_HIGH"

cd ..
