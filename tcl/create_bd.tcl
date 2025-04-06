create_bd_design "Processor_Design"

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
startgroup
create_bd_cell -type ip -vlnv SUAI:user:AXI4_Master:1.0 AXI4_Master_0
endgroup
startgroup
create_bd_cell -type ip -vlnv SUAI:user:instruction_cache:1.0 instruction_cache_0
endgroup
startgroup
create_bd_cell -type ip -vlnv SUAI:user:riscv_core:1.0 riscv_core_0
endgroup
create_bd_port -dir I -type clk -freq_hz 250000000 clk
startgroup
create_bd_port -dir I -type rst rst_n
endgroup
connect_bd_net [get_bd_ports clk] [get_bd_pins riscv_core_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins instruction_cache_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins AXI4_Master_0/refclk]
connect_bd_net [get_bd_ports clk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins riscv_core_0/rst]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins instruction_cache_0/reset_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins AXI4_Master_0/arst_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_pins instruction_cache_0/proc_data] [get_bd_pins riscv_core_0/icache_proc_data]
connect_bd_net [get_bd_pins instruction_cache_0/proc_ready] [get_bd_pins riscv_core_0/icache_proc_ready]
connect_bd_net [get_bd_pins riscv_core_0/icache_proc_addr] [get_bd_pins instruction_cache_0/proc_addr]
connect_bd_net [get_bd_pins riscv_core_0/icache_proc_req] [get_bd_pins instruction_cache_0/proc_req]
connect_bd_net [get_bd_pins AXI4_Master_0/o_data] [get_bd_pins instruction_cache_0/axi_data]
connect_bd_net [get_bd_pins AXI4_Master_0/o_valid] [get_bd_pins instruction_cache_0/axi_valid]
connect_bd_net [get_bd_pins instruction_cache_0/axi_addr] [get_bd_pins AXI4_Master_0/i_addr]
connect_bd_net [get_bd_pins instruction_cache_0/axi_req] [get_bd_pins AXI4_Master_0/i_read_req]

connect_bd_net [get_bd_pins instruction_cache_0/axi_ready] [get_bd_pins AXI4_Master_0/i_ready]
connect_bd_intf_net [get_bd_intf_pins AXI4_Master_0/M_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Enable_32bit_Address {false} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {9} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTA_Pin {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.use_bram_block {Stand_Alone} CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells blk_mem_gen_0]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]
set_property -dict [list CONFIG.FREQ_HZ {250000000}] [get_bd_intf_pins AXI4_Master_0/M_AXI]
validate_bd_design
save_bd_design
close_bd_design [get_bd_designs Processor_Design]

make_wrapper -files [get_files $CURRENT_DIR/SoC_RISC_V/SoC_RISC_V.srcs/sources_1/bd/Processor_Design/Processor_Design.bd] -top
add_files -norecurse $CURRENT_DIR/SoC_RISC_V/SoC_RISC_V.gen/sources_1/bd/Processor_Design/hdl/Processor_Design_wrapper.vhd

