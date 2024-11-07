# Get the directory where the script is located
set script_path [file normalize [info script]]
set repo_path [file dirname $script_path]
set project_dir "${repo_path}/project"

# Check if project directory exists and remove it if it does
if {[file exists $project_dir]} {
    puts "Found existing project directory: $project_dir"
    puts "Removing old project directory..."
    file delete -force $project_dir
    puts "Old project directory removed."
}

# Create project
set project_name "oti-i2c-bridge-project"
create_project ${project_name} "${repo_path}/project" -part xc7vx485tffg1157-1

# Add RTL files
set rtl_files [list \
    "[file normalize "${repo_path}/rtl/i2c_master_axil.v"]" \
    "[file normalize "${repo_path}/rtl/i2c_master.v"]" \
    "[file normalize "${repo_path}/rtl/axis_fifo.v"]" \
    "[file normalize "${repo_path}/rtl/i2c_master_wbs_8.v"]" \
    "[file normalize "${repo_path}/rtl/i2c_master_wbs_16.v"]" \
]
add_files -norecurse $rtl_files
update_compile_order -fileset sources_1

# Create and setup AXIL simulation fileset
create_fileset -simset sim_axil
set_property SOURCE_SET sources_1 [get_filesets sim_axil]

# Add AXIL simulation files
set sim_axil_files [list \
    "[file normalize "${repo_path}/sim/sim_axil/"]" \
]
add_files -fileset sim_axil -scan_for_includes $sim_axil_files

# Configure AXIL simulation settings
set_property top axil_tb_top [get_filesets sim_axil]
set_property top_lib xil_defaultlib [get_filesets sim_axil]
update_compile_order -fileset sim_axil
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_axil]

# Create and setup WB8 simulation fileset
create_fileset -simset sim_wb8
set_property SOURCE_SET sources_1 [get_filesets sim_wb8]

# Add WB8 simulation files
set sim_wb8_files [list \
    "[file normalize "${repo_path}/sim/sim_wb8/"]" \
]
add_files -fileset sim_wb8 -scan_for_includes $sim_wb8_files

# Configure WB8 simulation settings
set_property top wb8_tb_top [get_filesets sim_wb8]
set_property top_lib xil_defaultlib [get_filesets sim_wb8]
update_compile_order -fileset sim_wb8
current_fileset -simset [ get_filesets sim_wb8 ]
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_wb8]

# Set dataflow viewer settings
set_property dataflow_viewer_settings "min_width=16" [current_fileset]