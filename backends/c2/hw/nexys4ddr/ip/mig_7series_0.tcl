create_ip -name mig_7series -vendor xilinx.com -library ip -module_name mig_7series_0
set_property CONFIG.XML_INPUT_FILE [file normalize ../ip/mig_7series_0.prj] [get_ips mig_7series_0]
generate_target {instantiation_template} \
    [get_files sources_1/ip/mig_7series_0/mig_7series_0.xci]

