# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CACHE_LINE_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CACHE_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "INDEX_BITS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LINE_OFFSET_BITS" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.CACHE_LINE_SIZE { PARAM_VALUE.CACHE_LINE_SIZE } {
	# Procedure called to update CACHE_LINE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CACHE_LINE_SIZE { PARAM_VALUE.CACHE_LINE_SIZE } {
	# Procedure called to validate CACHE_LINE_SIZE
	return true
}

proc update_PARAM_VALUE.CACHE_SIZE { PARAM_VALUE.CACHE_SIZE } {
	# Procedure called to update CACHE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CACHE_SIZE { PARAM_VALUE.CACHE_SIZE } {
	# Procedure called to validate CACHE_SIZE
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.INDEX_BITS { PARAM_VALUE.INDEX_BITS } {
	# Procedure called to update INDEX_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INDEX_BITS { PARAM_VALUE.INDEX_BITS } {
	# Procedure called to validate INDEX_BITS
	return true
}

proc update_PARAM_VALUE.LINE_OFFSET_BITS { PARAM_VALUE.LINE_OFFSET_BITS } {
	# Procedure called to update LINE_OFFSET_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LINE_OFFSET_BITS { PARAM_VALUE.LINE_OFFSET_BITS } {
	# Procedure called to validate LINE_OFFSET_BITS
	return true
}


proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CACHE_SIZE { MODELPARAM_VALUE.CACHE_SIZE PARAM_VALUE.CACHE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CACHE_SIZE}] ${MODELPARAM_VALUE.CACHE_SIZE}
}

proc update_MODELPARAM_VALUE.CACHE_LINE_SIZE { MODELPARAM_VALUE.CACHE_LINE_SIZE PARAM_VALUE.CACHE_LINE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CACHE_LINE_SIZE}] ${MODELPARAM_VALUE.CACHE_LINE_SIZE}
}

proc update_MODELPARAM_VALUE.LINE_OFFSET_BITS { MODELPARAM_VALUE.LINE_OFFSET_BITS PARAM_VALUE.LINE_OFFSET_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LINE_OFFSET_BITS}] ${MODELPARAM_VALUE.LINE_OFFSET_BITS}
}

proc update_MODELPARAM_VALUE.INDEX_BITS { MODELPARAM_VALUE.INDEX_BITS PARAM_VALUE.INDEX_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INDEX_BITS}] ${MODELPARAM_VALUE.INDEX_BITS}
}

