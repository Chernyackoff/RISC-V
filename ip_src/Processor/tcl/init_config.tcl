set PROJECT_NAME Processor
set PROJECT_DIR Processor
set INCREMENTAL_BUILD false
set FPGA_PART xc7v585tffg1157-2
set TARGET_LANG VHDL
set SIM_LANG VHDL
set SRC_DIR src
set TCL_DIR tcl
set SIM_DIR tb
set CNSTR_DIR cnstr
set SIM_TOP_FILE_NAME RISCV_Core_TB
set TOP_FILE_NAME RISCV_Core_TOP
start_gui
source   -notrace  tcl/make_prj.tcl
