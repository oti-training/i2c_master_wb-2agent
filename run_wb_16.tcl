set BUILD_DIR "build"
file mkdir $BUILD_DIR

file delete -force {*}[glob -nocomplain $BUILD_DIR/xsim.dir]
file delete -force {*}[glob -nocomplain $BUILD_DIR/*.log $BUILD_DIR/*.jou $BUILD_DIR/*.pb $BUILD_DIR/*.wdb]

set fp [open "$BUILD_DIR/uvm_precompile.sv" w]
puts $fp "`timescale 1ns/1ps"
close $fp

cd $BUILD_DIR

# Compile UVM precompile file
exec xvlog -sv -L uvm uvm_precompile.sv > xvlog_uvm_precompile.log 2>&1

# Compile package files
exec xvlog -sv -L uvm ../sim/sim_wb16/wb16_pkg.sv > xvlog_wb16_pkg.log 2>&1

# Compile interface and DUT files
exec xvlog -sv -L uvm ../sim/sim_wb16/wb16_top_interface.sv > xvlog_interfaces.log 2>&1
exec xvlog -sv -L uvm ../rtl/i2c_master_wbs_16.v >> xvlog_interfaces.log 2>&1

exec xvlog -sv -L uvm ../rtl/i2c_master.v ../rtl/i2c_master_wbs_16.v ../rtl/axis_fifo.v >> xvlog_interfaces.log 2>&1

# Compile testbench top
exec xvlog -sv -L uvm ../sim/sim_wb16/wb16_tb_top.sv > xvlog_tb_top.log 2>&1

# Elaborate
exec xelab -L uvm -timescale 1ns/1ps -debug typical wb16_tb_top -s wb16_tb_top > xelab.log 2>&1

# Run simulation
exec xsim -R wb16_tb_top -testplusarg "UVM_VERBOSITY=UVM_HIGH" > xsim.log 2>&1

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
