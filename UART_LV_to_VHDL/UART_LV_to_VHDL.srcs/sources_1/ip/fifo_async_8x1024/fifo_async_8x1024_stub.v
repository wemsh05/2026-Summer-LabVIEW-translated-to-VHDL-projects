// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594) (win64) Build 0 Tue May 19
//               17:22:27 MDT 2015
// Date        : Fri Jul 17 15:06:49 2026
// Host        : running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/LabVIEW_to_VHDL_projects/UART_LV_to_VHDL/UART_LV_to_VHDL.srcs/sources_1/ip/fifo_async_8x1024/fifo_async_8x1024_stub.v
// Design      : fifo_async_8x1024
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v12_0,Vivado 2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594)" *)
module fifo_async_8x1024(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [7:0]din;
  input wr_en;
  input rd_en;
  output [7:0]dout;
  output full;
  output empty;
endmodule
