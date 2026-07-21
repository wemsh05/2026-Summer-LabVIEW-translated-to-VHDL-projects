-- Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594) (win64) Build 0 Tue May 19
--               17:22:27 MDT 2015
-- Date        : Fri Jul 17 15:06:49 2026
-- Host        : running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               e:/LabVIEW_to_VHDL_projects/UART_LV_to_VHDL/UART_LV_to_VHDL.srcs/sources_1/ip/fifo_async_8x1024/fifo_async_8x1024_stub.vhdl
-- Design      : fifo_async_8x1024
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_async_8x1024 is
  Port ( 
    rst : in STD_LOGIC;
    wr_clk : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 7 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 7 downto 0 );
    full : out STD_LOGIC;
    empty : out STD_LOGIC
  );

end fifo_async_8x1024;

architecture stub of fifo_async_8x1024 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "rst,wr_clk,rd_clk,din[7:0],wr_en,rd_en,dout[7:0],full,empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v12_0,Vivado 2014.4_AR65813_AR64601_AR63880_AR63479_AR62969_(AR63524_AR64594)";
begin
end;
