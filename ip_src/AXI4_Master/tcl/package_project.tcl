update_compile_order -fileset sources_1
ipx::package_project -root_dir $IP_PATH/AXI_Master -vendor SUAI -library user -taxonomy /UserIP -import_files -set_current false

ipx::unload_core $IP_PATH/AXI_Master/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $IP_PATH/AXI_Master $IP_PATH/AXI_Master/component.xml

update_compile_order -fileset sources_1
set_property display_name AXI4_Master [ipx::current_core]
set_property description {AXI4_Master is master for AXI MM} [ipx::current_core]
set_property vendor_display_name SUAI [ipx::current_core]
set_property vendor SUAI [ipx::current_core]
set_property name AXI4_Master [ipx::current_core]
set_property version 0.2 [ipx::current_core]
set_property supported_families {qvirtex7 Production versal Production kintex7 Production kintex7l Production qkintex7 Production qkintex7l Production akintex7 Production artix7 Production artix7l Production aartix7 Production qartix7 Production zynq Production qzynq Production azynq Production spartan7 Production aspartan7 Production virtexu Production zynquplus Production virtexuplus Production virtexuplusHBM Production virtexuplus58g Production kintexuplus Production artixuplus Production kintexu Production} [ipx::current_core]
set_property supported_families {qvirtex7 Production versal Production artix7 Production artix7l Production aartix7 Production qartix7 Production zynq Production qzynq Production azynq Production spartan7 Production aspartan7 Production virtexu Production zynquplus Production virtexuplus Production virtexuplusHBM Production virtexuplus58g Production kintexuplus Production artixuplus Production kintexu Production} [ipx::current_core]
set_property supported_families {qvirtex7 Production versal Production virtexu Production zynquplus Production virtexuplus Production virtexuplusHBM Production virtexuplus58g Production kintexuplus Production artixuplus Production kintexu Production} [ipx::current_core]
set_property supported_families {qvirtex7 Production versal Production virtexu Production zynquplus Production kintexuplus Production artixuplus Production kintexu Production} [ipx::current_core]
set_property supported_families {qvirtex7 Production virtexu Production zynquplus Production kintexuplus Production artixuplus Production kintexu Production} [ipx::current_core]
set_property supported_families {qvirtex7 Production virtexu Production zynquplus Production kintexuplus Production artixuplus Production kintexu Production kintex7 Beta kintex7l Beta kintexuplus Beta kintexu Beta} [ipx::current_core]
set_property previous_version_for_upgrade xilinx.com:user:AXI4_Master_TOP:1.0 [ipx::current_core]
set_property core_revision 1 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]

ipx::save_core [ipx::current_core]
close_project