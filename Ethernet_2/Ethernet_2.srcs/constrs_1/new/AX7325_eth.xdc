############## Bitstream/Flash Configuration Settings ##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]

############### 200 MHz Differential System Clock (Bank 33) ##################
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]

set_property PACKAGE_PIN AE10 [get_ports sys_clk_p]
set_property PACKAGE_PIN AF10 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]

############### System Reset Button (KEY1) ##################
set_property PACKAGE_PIN AG27 [get_ports rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports rst_n]

############### GMII Interface (AN8211 Module - Bank 15) ##################
set_property IOSTANDARD LVCMOS33 [get_ports {E_*}]

# Ethernet Control & Clocks
set_property PACKAGE_PIN J27 [get_ports E_RESET]
set_property PACKAGE_PIN L26 [get_ports E_GTXC]
set_property PACKAGE_PIN J26 [get_ports E_RXC]

# Ethernet RX Signals
set_property PACKAGE_PIN J23 [get_ports E_RXDV]
set_property PACKAGE_PIN J24 [get_ports {E_RXD[0]}]
set_property PACKAGE_PIN J21 [get_ports {E_RXD[1]}]
set_property PACKAGE_PIN J22 [get_ports {E_RXD[2]}]
set_property PACKAGE_PIN K26 [get_ports {E_RXD[3]}]
set_property PACKAGE_PIN L30 [get_ports {E_RXD[4]}]
set_property PACKAGE_PIN K30 [get_ports {E_RXD[5]}]
set_property PACKAGE_PIN M28 [get_ports {E_RXD[6]}]
set_property PACKAGE_PIN L28 [get_ports {E_RXD[7]}]

# Ethernet TX Signals
set_property PACKAGE_PIN L27 [get_ports E_TXEN]
set_property PACKAGE_PIN J28 [get_ports {E_TXD[0]}]
set_property PACKAGE_PIN J29 [get_ports {E_TXD[1]}]
set_property PACKAGE_PIN H29 [get_ports {E_TXD[2]}]
set_property PACKAGE_PIN K28 [get_ports {E_TXD[3]}]
set_property PACKAGE_PIN K29 [get_ports {E_TXD[4]}]
set_property PACKAGE_PIN M20 [get_ports {E_TXD[5]}]
set_property PACKAGE_PIN L20 [get_ports {E_TXD[6]}]
set_property PACKAGE_PIN L21 [get_ports {E_TXD[7]}]

# RX Clock Timing Constraint (125 MHz for GMII)
create_clock -period 8.000 -name E_RXC -waveform {0.000 4.000} [get_ports E_RXC]

############### Clock Groups ##################
set_clock_groups -asynchronous -group [get_clocks sys_clk_p] -group [get_clocks E_RXC]


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets E_RXC_IBUF]