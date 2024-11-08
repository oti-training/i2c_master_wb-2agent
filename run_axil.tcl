set BUILD_DIR "build"
file mkdir $BUILD_DIR

file delete -force {*}[glob -nocomplain $BUILD_DIR/xsim.dir]
file delete -force {*}[glob -nocomplain $BUILD_DIR/*.log $BUILD_DIR/*.jou $BUILD_DIR/*.pb $BUILD_DIR/*.wdb]

set fp [open "$BUILD_DIR/uvm_precompile.sv" w]
puts $fp "`timescale 1ns/1ps"
close $fp

cd $BUILD_DIR

exec xvlog -sv -L uvm uvm_precompile.sv > xvlog_uvm_precompile.log 2>&1

exec xvlog -sv -L uvm ../sim/sim_axil/dut_params_defines.svh > xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/register_defines.svh >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/i2c_master_axil_pkg.sv >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/i2c_agent/i2c_agent_pkg.sv >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/axil_agent/axil_agent_pkg.sv >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/env/bridge_env_pkg.sv >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/sequences/axil_seq_list.sv >> xvlog_dut_params.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/tests/axil_test_pkg.sv >> xvlog_dut_params.log 2>&1

exec xvlog -sv -L uvm ../sim/common/i2c_interface.sv > xvlog_interfaces.log 2>&1
exec xvlog -sv -L uvm ../sim/sim_axil/axil_interface.sv >> xvlog_interfaces.log 2>&1
exec xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_axil.v ../rtl/axis_fifo.v >> xvlog_interfaces.log 2>&1

exec xvlog -sv -L uvm ../sim/sim_axil/axil_tb_top.sv > xvlog_tb_top.log 2>&1

exec xelab -L uvm -timescale 1ns/1ps -debug typical axil_tb_top -s axil_tb_top > xelab.log 2>&1

exec xsim -R axil_tb_top -testplusarg "UVM_VERBOSITY=UVM_LOW" > xsim.log 2>&1

cd ..

puts "Simulation completed. Check the log files in the build directory for details."

# Display contents of xsim.log
puts "Contents of xsim.log:"
set fp [open "$BUILD_DIR/xsim.log" r]
set file_data [read $fp]
close $fp
puts $file_data

# Delete Vivado generated files
file delete -force {*}[glob -nocomplain vivado*.jou]
file delete -force {*}[glob -nocomplain vivado*.log]
file delete -force {*}[glob -nocomplain vivado*.str]

puts "Vivado generated .jou, .log, and .str files have been deleted."
