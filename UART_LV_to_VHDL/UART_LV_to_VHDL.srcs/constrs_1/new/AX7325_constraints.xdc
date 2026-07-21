############## SPI Configuration Settings ##################
# Ensures reliable boot and bitstream configuration parameters
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

############### System Clock Definitions ##################
# 200 MHz System Differential Clock input (AX7325 Board Pins AE10/AE11)
create_clock -period 5.000 -name sys_clk_pin [get_ports sys_clk_p]

set_property -dict { PACKAGE_PIN AE10 IOSTANDARD DIFF_SSTL15 } [get_ports sys_clk_p]
set_property -dict { PACKAGE_PIN AE11 IOSTANDARD DIFF_SSTL15 } [get_ports sys_clk_n]

############### Top-Level System Port Mappings ##################

# Active-Low Reset (Mapped to Board KEY1 - AG27)
set_property -dict { PACKAGE_PIN AG27 IOSTANDARD LVCMOS25 } [get_ports rst_n]

# UART Signals (AX7325 Onboard USB-to-UART Serial Bridge)
set_property -dict { PACKAGE_PIN AJ26 IOSTANDARD LVCMOS25 } [get_ports uart_rxd]
set_property -dict { PACKAGE_PIN AK26 IOSTANDARD LVCMOS25 } [get_ports uart_txd]

# Read Status Signal (Mapped to Board LED1 - A22)
set_property -dict { PACKAGE_PIN A22 IOSTANDARD LVCMOS15 } [get_ports read_valid]

# Read Data Bus (read_d[7:0] mapped to Bank 12 Pins)
set_property -dict { PACKAGE_PIN Y20  IOSTANDARD LVCMOS25 } [get_ports {read_d[0]}]
set_property -dict { PACKAGE_PIN Y23  IOSTANDARD LVCMOS25 } [get_ports {read_d[1]}]
set_property -dict { PACKAGE_PIN Y24  IOSTANDARD LVCMOS25 } [get_ports {read_d[2]}]
set_property -dict { PACKAGE_PIN Y21  IOSTANDARD LVCMOS25 } [get_ports {read_d[3]}]
set_property -dict { PACKAGE_PIN AA21 IOSTANDARD LVCMOS25 } [get_ports {read_d[4]}]
set_property -dict { PACKAGE_PIN AB22 IOSTANDARD LVCMOS25 } [get_ports {read_d[5]}]
set_property -dict { PACKAGE_PIN AB23 IOSTANDARD LVCMOS25 } [get_ports {read_d[6]}]
set_property -dict { PACKAGE_PIN AA22 IOSTANDARD LVCMOS25 } [get_ports {read_d[7]}]

######## FPGA_IO_SI5338 Clock Generator #####################
# I2C Configuration lines for the external clock generator
set_property -dict { PACKAGE_PIN P23 IOSTANDARD LVCMOS33 } [get_ports si5338_scl]
set_property -dict { PACKAGE_PIN N25 IOSTANDARD LVCMOS33 } [get_ports si5338_sda]

######## Timing Constraints / Clock Groups #####################
# Set false path to prevent Vivado from timing paths between asynchronous domains
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin]