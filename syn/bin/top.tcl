set TOPLEVEL "minimips"
set simType ""
#set TECH "LIB065"
set TECH "nangate45"
# set TECH "nangate15"
# set_host_options -max_cores 8
set CLK "clock"
set CLK2 "clock2"
set RST "reset"
# 200 MHz
set CLK_PERIOD 5
# Push hard
set MAX_AREA 0
# yes, no
set DO_UNGROUP "no"
set DO_VERIFY "no"
# 100 ps
set CLK_UNCERTAINTY 0.1
# Clk to Q in technology time units
set DFF_CKQ 0.2
# Setup time in technology time units
set DFF_SETUP 0.1

# Starting timestamp
sh date

###################################################
#  Set some basic variables related to environment
###################################################

# Enable Verilog HDL preprocessor */
set hdlin_enable_vpp true

# Set log path
set LOG_PATH "../log/"

# Set gate-level netlist path
set GATE_PATH "../out/"

# Set RAMS_PATH
set RAMS_PATH "../lib/"

# Set RTL source path
set RTL_PATH "../src/"

set CLS_RTL_PATH "../../../ ../../../rtl/verilog/cls_config/"



# Optimize adders
set synlib_model_map_effort high
set hlo_share_effort low

set STAGE final

###################################################
# Load libraries
###################################################

# /* Search paths */
set search_path [list . ../lib/ [getenv "SYNOPSYS"]]

# /* Synthetic libraries */
set synthetic_library dw_foundation.sldb

#comment out if SYNOPSYS_UNCONNECTED_ not removed
set verilogout_show_unconnected_pins   "FALSE"

if { $TECH == "nangate45" } {
	set target_library NangateOpenCellLibrary.db
	set_dont_use "NangateOpenCellLibrary/SDFFRS_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFRS_X2"
	set_dont_use "NangateOpenCellLibrary/SDFFR_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFR_X2"
	set_dont_use "NangateOpenCellLibrary/SDFFS_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFS_X2"
	set_dont_use "NangateOpenCellLibrary/SDFF_X1"
	set_dont_use "NangateOpenCellLibrary/SDFF_X2"
# 	set_dont_use "NangateOpenCellLibrary/MUX2_X1"
# 	set_dont_use "NangateOpenCellLibrary/MUX2_X2"

} elseif { $TECH == "nangate45Old" } {
	set target_library NangateOpenCellLibrary.db
	set_dont_use "NangateOpenCellLibrary/SDFFRS_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFRS_X2"
	set_dont_use "NangateOpenCellLibrary/SDFFR_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFR_X2"
	set_dont_use "NangateOpenCellLibrary/SDFFS_X1"
	set_dont_use "NangateOpenCellLibrary/SDFFS_X2"
	set_dont_use "NangateOpenCellLibrary/SDFF_X1"
	set_dont_use "NangateOpenCellLibrary/SDFF_X2"
# 	set_dont_use "NangateOpenCellLibrary/MUX2_X1"
# 	set_dont_use "NangateOpenCellLibrary/MUX2_X2"

} elseif { $TECH == "LIB065" } {
	set target_library CORE65GPSVT_nom_1.10V_25C.db
} elseif { $TECH == "nangate15" } {
	set target_library NanGate_15nm_OCL.db
	set_dont_use "NanGate_15nm_OCL/SDFFRNQ_X1"
	set_dont_use "NanGate_15nm_OCL/SDFFSNQ_X1"
# 	set_dont_use "NanGate_15nm_OCL/MUX2_X1"
# 	set_dont_use "NanGate_15nm_OCL/MUX2_X2"

}

set link_library [list $target_library $synthetic_library]


###################################################
#  * Load HDL source files
###################################################

source ../bin/read_design.inc > "${LOG_PATH}read_design_${TOPLEVEL}_${simType}${TECH}.log"
elaborate $TOPLEVEL > "${LOG_PATH}elaborate_${TOPLEVEL}_${simType}${TECH}.log"

# /* Set design top */
current_design $TOPLEVEL

set power_reserve_rtl_hier_names true

# /* Link all blocks and uniquify them */
link
uniquify
check_design > "${LOG_PATH}check_design_${TOPLEVEL}_${simType}${TECH}.log"

# /*
#  * Apply constraints
#  *
#  */

if { $TECH == "nangate45" } {
 	set DFF_CELL DFF_X2
 	set LIB_DFF_D NangateOpenCellLibrary/DFF_X2/D
	set OPER_COND typical
} elseif { $TECH == "nangate45Old" } {
 	set DFF_CELL DFF_X2
 	set LIB_DFF_D NangateOpenCellLibrary/DFF_X2/D
	set OPER_COND typical
} elseif { $TECH == "LIB065" } {
	set OPER_COND nom_1.10V_25C
	set LIB_DFF_D CORE65GPSVT/HS65_GS_DFPHQNX4/D
	set DFF_CELL HS65_GS_DFPHQNX4
} elseif { $TECH == "nangate15" } {
 	set DFF_CELL DFFRNQ_X1
 	set LIB_DFF_D NanGate_15nm_OCL/DFFRNQ_X1/D
	set OPER_COND typical
} else {
	echo "Error: Unsupported technology"
}


# /* Clocks constraints */
#create_clock clock -period $CLK_PERIOD
#create_clock clock2 -period $CLK_PERIOD
create_clock $CLK -period $CLK_PERIOD
create_clock $CLK2 -period $CLK_PERIOD
set_clock_uncertainty $CLK_UNCERTAINTY [all_clocks]
set_dont_touch_network [all_clocks]
#remove_unconnected_ports -blast_buses [get_cells -hier *]
#remove_unconnected_ports
set_false_path -from clock1 -to clock2
report_clocks

# /* Reset constraints */
set_driving_cell -none $RST
set_drive 0 $RST
set_dont_touch_network $RST

# /* All inputs except reset and clock */
set all_inputs_wo_rst_clk [remove_from_collection [all_inputs] [list $CLK $RST]]

# /* Set output delays and load for output signals
#  *
#  * All outputs are assumed to go directly into
#  * external flip-flops for the purpose of this
#  * synthesis
#  */
set_output_delay $DFF_SETUP -clock $CLK [all_outputs]
set_load [expr [load_of $LIB_DFF_D] * 4] [all_outputs]

# /* Input delay and driving cell of all inputs
#  *
#  * All these signals are assumed to come directly from
#  * flip-flops for the purpose of this synthesis
#  *
#  */
set_input_delay $DFF_CKQ -clock $CLK $all_inputs_wo_rst_clk
set_driving_cell -lib_cell $DFF_CELL -pin QN $all_inputs_wo_rst_clk

# /* Set design fanout */
# /*
# set_max_fanout 10 $TOPLEVEL
# */

# /* Optimize all near-critical paths to give extra slack for layout */
set c_range [expr $CLK_PERIOD * 0.10]
group_path -critical_range $c_range -name $CLK -to $CLK

# /* Operating conditions */
set_operating_conditions $OPER_COND

# /* Lets do basic synthesis */
if { $DO_UNGROUP == "yes" } {
	ungroup -all -unflatten
}

# /*
# set_structure -boolean false -timing true
# set_flatten -effort medium -minimize single_output
# */

# /*
# set_flatten false
# */

# /*
#  compile -boundary_optimization -map_effort medium -ungroup_all
# */
#  compile -boundary_optimization -map_effort high -auto_ungroup
# compile -area_effort none -map_effort high
# /*
# compile -map_effort low
# */

# New PART START
# set automatic removal of constants flip-flop
# set compile_seqmap_propagate_constants true

# set automatic removal of unloaded flip-flop
# set compile_delete_unloaded_sequential_cells false
# set hdlin_ff_always_sync_set_reset "true"
# compile_ultra -no_autoungroup -no_seq_output_inversion
# compile -area_effort none -exact_map -power_effort none
# New PART END
#compile_ultra -no_autoungroup
compile

# /* Save current design using synopsys format */
write -hierarchy -format ddc -output "${GATE_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}.ddc"

# /* Save current design using verilog format */
change_names -hierarchy -rules verilog
write -hierarchy -format verilog -output "${GATE_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}.v"
write_sdf -version 3.0 "${GATE_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}.sdf"
write_sdc "${GATE_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}.sdc"
# write_test_protocol -output "${GATE_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}.spf"
write_tmax_library -path "${GATE_PATH}"

# /* Basic reports */
report_area                     > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_area.log"
report_timing -nworst 10        > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_timing.log"
report_hierarchy                > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_hierarchy.log"
report_resources                > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_resources.log"
report_reference                > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_reference.log"
report_constraint               > "${LOG_PATH}${STAGE}_${TOPLEVEL}_${simType}_${TECH}_constraint.log"
# report_ultra_optimizations      > "${LOG_PATH}${STAGE}_${TOPLEVEL}_ultra_optimizations_${simType}_${TECH}.log"
# report_power                    > "${LOG_PATH}${STAGE}_${TOPLEVEL}_power_${simType}_${TECH}.log"


# /* Verify design */
if { $DO_VERIFY == "yes" } {
	compile -no_map -verify		> "${LOG_PATH}verify_${TOPLEVEL}_${simType}_${TECH}.log"
}

# /* Finish */
sh date
exit
