// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594) (win64) Build 0 Tue May 19
//               17:22:27 MDT 2015
// Date        : Fri Jul 17 15:42:14 2026
// Host        : running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/LabVIEW_to_VHDL_projects/UART_LV_to_VHDL/UART_LV_to_VHDL.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_in1_p, clk_in1_n, clk_50M, clk_32M, reset, locked)
/* synthesis syn_black_box black_box_pad_pin="clk_in1_p,clk_in1_n,clk_50M,clk_32M,reset,locked" */;
  input clk_in1_p;
  input clk_in1_n;
  output clk_50M;
  output clk_32M;
  input reset;
  output locked;
endmodule
