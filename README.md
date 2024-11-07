# To automate project creation in Vivado GUI
1. Make sure no project in Vivado is open.
2. Go to the Vivado top bar, select Tools ->  Run Tcl Script...
3. Select init_project.tcl from the file directory inside this repository.
4. Wait for magic (1-2 minutes).

# To run simulation using vivado tcl script
```
vivado -mode tcl -source run_axil.tcl
```
```
vivado -mode tcl -source run_wb_8.tcl
```

# To run simulation using bash script
## First time initialization
```
chmod +x run_axil.sh
```
```
chmod +x run_wb_8.sh
```

## Using The script
```
./run_axil.sh
```
```
./run_wb_8.sh
```
