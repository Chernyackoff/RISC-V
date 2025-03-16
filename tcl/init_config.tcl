set PROJECT_NAME SoC_RISC_V
set PROJECT_DIR SoC_RISC_V
set INCREMENTAL_BUILD false
set FPGA_PART xc7v585tffg1157-2
set TARGET_LANG VHDL
set SIM_LANG VHDL
set SRC_DIR src
set TCL_DIR tcl
set SIM_DIR tb
set CNSTR_DIR cnstr
set SIM_TOP_FILE_NAME SoC_RISC_V_TB
set TOP_FILE_NAME SoC_RISC_V_TOP
start_gui
source   -notrace  tcl/make_prj.tcl
