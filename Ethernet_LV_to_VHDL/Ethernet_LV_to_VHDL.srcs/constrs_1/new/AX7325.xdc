############## Boot/Flash Configuration Settings ##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

############### 200 MHz Differential System Clock ##################
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]

set_property PACKAGE_PIN G27 [get_ports sys_clk_p]
set_property PACKAGE_PIN F28 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]

# Allow clock routing to fabric logic / BUFG if needed
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]

# GMII Receive Clock from RTL8211 (125 MHz = 8.0 ns period)
create_clock -period 8.000 -name E_RXC [get_ports E_RXC]

############### System Pins ##################
set_property -dict { PACKAGE_PIN AG27 IOSTANDARD LVCMOS25 } [get_ports rst_n]

############### GMII Interface (AN8211 Module) ##################
set_property PACKAGE_PIN P23 [get_ports E_RESET]
set_property IOSTANDARD LVCMOS25 [get_ports E_RESET]

set_property PACKAGE_PIN N25 [get_ports E_GTXC]
set_property IOSTANDARD LVCMOS25 [get_ports E_GTXC]

set_property PACKAGE_PIN AB22 [get_ports E_TXEN]
set_property IOSTANDARD LVCMOS25 [get_ports E_TXEN]

set_property PACKAGE_PIN AA22 [get_ports E_RXC]
set_property IOSTANDARD LVCMOS25 [get_ports E_RXC]

set_property PACKAGE_PIN Y20 [get_ports E_RXDV]
set_property IOSTANDARD LVCMOS25 [get_ports E_RXDV]

set_property PACKAGE_PIN Y21 [get_ports E_RXER]
set_property IOSTANDARD LVCMOS25 [get_ports E_RXER]

# GMII TX Data Bus
set_property PACKAGE_PIN Y23 [get_ports {E_TXD[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[0]}]

set_property PACKAGE_PIN Y24 [get_ports {E_TXD[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[1]}]

set_property PACKAGE_PIN AA21 [get_ports {E_TXD[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[2]}]

set_property PACKAGE_PIN AB23 [get_ports {E_TXD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[3]}]

set_property PACKAGE_PIN AC23 [get_ports {E_TXD[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[4]}]

set_property PACKAGE_PIN AC24 [get_ports {E_TXD[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[5]}]

set_property PACKAGE_PIN AD23 [get_ports {E_TXD[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[6]}]

set_property PACKAGE_PIN AD24 [get_ports {E_TXD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_TXD[7]}]

# GMII RX Data Bus
set_property PACKAGE_PIN AE23 [get_ports {E_RXD[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[0]}]

set_property PACKAGE_PIN AE24 [get_ports {E_RXD[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[1]}]

set_property PACKAGE_PIN AF23 [get_ports {E_RXD[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[2]}]

set_property PACKAGE_PIN AF24 [get_ports {E_RXD[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[3]}]

set_property PACKAGE_PIN AG24 [get_ports {E_RXD[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[4]}]

set_property PACKAGE_PIN AH24 [get_ports {E_RXD[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[5]}]

set_property PACKAGE_PIN AG25 [get_ports {E_RXD[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[6]}]

set_property PACKAGE_PIN AH25 [get_ports {E_RXD[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {E_RXD[7]}]
############### Clock Groups ##################
set_clock_groups -asynchronous -group [get_clocks sys_clk_p] -group [get_clocks E_RXC]


# bitstream override property
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]