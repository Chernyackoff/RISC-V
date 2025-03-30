ipx::package_project -root_dir $IP_PATH/Processor \
                     -vendor SUAI \
                     -library user \
                     -taxonomy /UserIP \
                     -import_files \
                     -force \
                     -set_current true  

if {[ipx::current_core] == ""} {
  error "ERROR: Failed to load core after packaging."
  return -code error
}

set_property display_name Processor [ipx::current_core]
set_property vendor_display_name SUAI [ipx::current_core]

set_property supported_families { \
    artix7 Production artix7l Production aartix7 Production qartix7 Production \
    kintex7 Production kintex7l Production qkintex7 Production qkintex7l Production akintex7 Production \
    spartan7 Production aspartan7 Production \
    virtex7 Production qvirtex7 Production \
    zynq Production qzynq Production azynq Production \
    kintexu Production \
    virtexu Production \
    kintexuplus Production \
    virtexuplus Production virtexuplusHBM Production virtexuplus58g Production \
    zynquplus Production \
    artixuplus Production \
    versal Production \
} [ipx::current_core]

set_property core_revision 1 [ipx::current_core]

ipx::create_xgui_files [ipx::current_core]

ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

ipx::unload_core [ipx::current_core]

puts "INFO: IP packaging complete for Processor."