###################################################################
# 
# Xilinx Vivado FPGA Makefile
# 
# Copyright (c) 2016 Alex Forencich
# 
###################################################################
# 
# Parameters:
# FPGA_TOP - Top module name
# FPGA_FAMILY - FPGA family (e.g. VirtexUltrascale)
# FPGA_DEVICE - FPGA device (e.g. xcvu095-ffva2104-2-e)
# SYN_FILES - space-separated list of source files
# INC_FILES - space-separated list of include files
# XDC_FILES - space-separated list of timing constraint files
# XCI_FILES - space-separated list of IP XCI files
# 
# Example:
# 
# FPGA_TOP = fpga
# FPGA_FAMILY = VirtexUltrascale
# FPGA_DEVICE = xcvu095-ffva2104-2-e
# SYN_FILES = rtl/fpga.v
# XDC_FILES = fpga.xdc
# XCI_FILES = ip/pcspma.xci
# include ../common/vivado.mk
# 
###################################################################

# phony targets
.PHONY: clean fpga

# prevent make from deleting intermediate files and reports
.PRECIOUS: %.xpr %.bit
.SECONDARY:

CONFIG ?= config.mk
-include ../$(CONFIG)

SYN_FILES_REL = $(patsubst %, ../%, $(SYN_FILES))
INC_FILES_REL = $(patsubst %, ../%, $(INC_FILES))
XCI_FILES_REL = $(patsubst %, ../%, $(XCI_FILES))
CREATE_SCRIPTS_REL = $(patsubst %, ../%, $(CREATE_SCRIPTS))

INCLUDE_DIRS_REL = $(patsubst %, ../%, $(INCLUDE_DIRS))
FPGA_TOPFILE_REL = $(patsubst %, ../%, $(FPGA_TOPFILE))

ifdef XDC_FILES
  XDC_FILES_REL = $(patsubst %, ../%, $(XDC_FILES))
else
  XDC_FILES_REL = $(FPGA_TOP).xdc
endif

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and project files
###################################################################

all: fpga

fpga: $(FPGA_TOP).bit

tmpclean:
	-rm -rf *.log *.jou *.cache *.hw *.ip_user_files *.runs *.xpr *.html *.xml *.sim *.srcs *.str .Xil defines.v
	-rm -rf create_project.tcl run_synth.tcl run_impl.tcl generate_bit.tcl

clean: tmpclean
	-rm -rf *.bit program.tcl

distclean: clean
	-rm -rf rev

###################################################################
# Target implementations
###################################################################

# Vivado project file
%.xpr: Makefile $(XCI_FILES_REL) $(CREATE_SCRIPTS_REL)
	rm -rf defines.v
	touch defines.v
	for x in $(DEFS); do echo '`define' $$x >> defines.v; done
	echo "create_project -force -part $(FPGA_PART) $*" > create_project.tcl
	echo "set_property include_dirs [list $(INCLUDE_DIRS_REL)] [current_fileset]" >> create_project.tcl
	echo "add_files -fileset sources_1 defines.v" >> create_project.tcl
	for x in $(SYN_FILES_REL); do echo "add_files -fileset sources_1 $$x" >> create_project.tcl; done
	for x in $(XDC_FILES_REL); do echo "add_files -fileset constrs_1 $$x" >> create_project.tcl; done
	for x in $(XCI_FILES_REL); do echo "import_ip $$x" >> create_project.tcl; done
	for x in $(CREATE_SCRIPTS_REL); do cat $$x >> create_project.tcl; done
	echo "set_property top $(FPGA_TOP) [current_fileset]" >> create_project.tcl
	echo "set_property top_file {$(FPGA_TOPFILE_REL)} [current_fileset]" >> create_project.tcl
	echo "exit" >> create_project.tcl
	vivado -mode batch -source create_project.tcl

# synthesis run
%.runs/synth_1/%.dcp: %.xpr $(SYN_FILES_REL) $(INC_FILES_REL) $(XDC_FILES_REL)
	echo "open_project $*.xpr" > run_synth.tcl
	echo "reset_run synth_1" >> run_synth.tcl
	echo "launch_runs synth_1" >> run_synth.tcl
	echo "wait_on_run synth_1" >> run_synth.tcl
	echo "exit" >> run_synth.tcl
	vivado -mode batch -source run_synth.tcl

# implementation run
%.runs/impl_1/%_routed.dcp: %.runs/synth_1/%.dcp
	echo "open_project $*.xpr" > run_impl.tcl
	echo "reset_run impl_1" >> run_impl.tcl
	echo "launch_runs impl_1" >> run_impl.tcl
	echo "wait_on_run impl_1" >> run_impl.tcl
	echo "set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]" >> run_impl.tcl
	echo "set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]" >> run_impl.tcl
	echo "set_property STRATEGY \"Performance_Explore\" [get_runs impl_1]" >> run_impl.tcl
	echo "set_property steps.post_route_phys_opt_design.is_enabled true [get_runs impl_1]" >> run_impl.tcl
	echo "set_property steps.post_route_phys_opt_design.args.directive Default [get_runs impl_1]" >> run_impl.tcl
	echo "launch_runs impl_1" >> run_impl.tcl
	echo "wait_on_run impl_1" >> run_impl.tcl
	echo "set WNS [get_property STATS.WNS [get_runs impl_1]]" >> run_impl.tcl
	echo "set TNS [get_property STATS.TNS [get_runs impl_1]]" >> run_impl.tcl
	echo "set WHS [get_property STATS.WHS [get_runs impl_1]]" >> run_impl.tcl
	echo "set THS [get_property STATS.THS [get_runs impl_1]]" >> run_impl.tcl
	echo "set TPWS [get_property STATS.TPWS [get_runs impl_1]]" >> run_impl.tcl
	echo "set FAILED_NETS [get_property STATS.FAILED_NETS [get_runs impl_1]]" >> run_impl.tcl

	echo "if { \$${WNS}<0.0 || \$${TNS}<0.0 || \$${WHS}<0.0 || \$${THS}<0.0 || \$${TPWS}<0.0 || \$${FAILED_NETS}>0.0 } {" >> run_impl.tcl
	echo "set chan [open timing_failed.log a]" >> run_impl.tcl
	echo "   puts $$chan \"===TIMING-FAILED-MARKER====\"" >> run_impl.tcl
	echo "   puts $$chan \"Timing fail, WNS=\$${WNS}\"" >> run_impl.tcl
	echo "   puts $$chan \"             TNS=\$${TNS}\"" >> run_impl.tcl
	echo "   puts $$chan \"             WHS=\$${WHS}\"" >> run_impl.tcl
	echo "   puts $$chan \"             THS=\$${THS}\"" >> run_impl.tcl
	echo "   puts $$chan \"  Nets: \$${FAILED_NETS}\"" >> run_impl.tcl
	echo "   puts $$chan \"===TIMING-FAILED-MARKER====\"" >> run_impl.tcl
	echo "   close $$chan" >> run_impl.tcl
	echo "}" >> run_impl.tcl
	echo "exit" >> run_impl.tcl
	vivado -mode batch -source run_impl.tcl

# bit file
%.bit: %.runs/impl_1/%_routed.dcp
	echo "open_project $*.xpr" > generate_bit.tcl
	echo "open_run impl_1" >> generate_bit.tcl
	echo "write_bitstream -force $*.bit" >> generate_bit.tcl
	echo "exit" >> generate_bit.tcl
	vivado -mode batch -source generate_bit.tcl
	mkdir -p rev
	EXT=bit; COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.$$EXT ]; \
	do let COUNT=COUNT+1; done; \
	cp $@ rev/$*_rev$$COUNT.$$EXT; \
	echo "Output: rev/$*_rev$$COUNT.$$EXT";
