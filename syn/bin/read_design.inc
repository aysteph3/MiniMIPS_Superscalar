# /* Set search path for verilog include files */
set search_path "${search_path} ${RTL_PATH} ${GATE_PATH} ${CLS_RTL_PATH}"

# /* Read vhdl files of the minimips processor core */
if { $TOPLEVEL == "minimips" } {


  analyze -f vhdl pack_mips.vhd
  analyze -f vhdl alu.vhd
  analyze -f vhdl alu2.vhd
  analyze -f vhdl pps_pf.vhd
  analyze -f vhdl delay_gate.vhd
  analyze -f vhdl pps_di.vhd
  analyze -f vhdl pps_di_2.vhd
  analyze -f vhdl pps_ei.vhd
  analyze -f vhdl pps_ei_2.vhd
  analyze -f vhdl ram.vhd
  analyze -f vhdl rom.vhd
  analyze -f vhdl renvoi.vhd
  analyze -f vhdl syscop.vhd
  analyze -f vhdl pps_mem.vhd
  analyze -f vhdl pps_ex.vhd
  analyze -f vhdl pps_ex_2.vhd
  analyze -f vhdl bus_ctrl01.vhd
  analyze -f vhdl bus_ctrl02.vhd
  analyze -f vhdl banc.vhd
  analyze -f vhdl minimips.vhd

} else {
	echo "Non-existing top level."
	exit
}
