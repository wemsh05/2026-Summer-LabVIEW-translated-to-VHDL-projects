// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594) (win64) Build 0 Tue May 19
//               17:22:27 MDT 2015
// Date        : Fri Jul 17 16:45:08 2026
// Host        : running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/LabVIEW_to_VHDL_projects/UART_LV_to_VHDL/UART_LV_to_VHDL.srcs/sources_1/ip/vio_0/vio_0_stub.v
// Design      : vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594)" *)
module vio_0(clk, probe_in0, probe_in1, probe_out0, probe_out1, probe_out2)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[7:0],probe_in1[0:0],probe_out0[0:0],probe_out1[0:0],probe_out2[7:0]" */;
  input clk;
  input [7:0]probe_in0;
  input [0:0]probe_in1;
  output [0:0]probe_out0;
  output [0:0]probe_out1;
  output [7:0]probe_out2;
endmodule
