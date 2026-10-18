DEFS = FPGA NEXYS ENABLE_EXT ENABLE_LONG_EXT DISABLE_MICROOPS RAM_REGISTERED_OUT ENABLE_SOUND DISABLE_MEMQUEUE
FPGA_TOP = c2soc
FPGA_ARCH = artix7
FPGA_PART = xc7a100tcsg324-1
SYN_FILES = ../rtl/core.v
SYN_FILES += ../rtl/soctop.v
SYN_FILES += ../rtl/regfile.v
SYN_FILES += nexys4.v
SYN_FILES += ./3rdparty/uart.v
SYN_FILES += ./3rdparty/uart_tx.v
SYN_FILES += ./3rdparty/uart_rx.v
SYN_FILES += ./3rdparty/vgafifo.v
SYN_FILES += vga640x480grey.v
SYN_FILES += vgatop640x480grey.v

CREATE_SCRIPTS = ip/clk_wiz_0.tcl

FPGA_TOPFILE = ../../rtl/soctop.v
XDC_FILES = fpga.xdc
INCLUDE_DIRS = ./
INCLUDE_DIRS += ../../custom_out/
INCLUDE_DIRS += ../rtl/
include ../common/vivado.mk

