//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12 
//Created Time: 2026-08-30 16:12:52
create_clock -name sys_calc_clk -period 10 -waveform {0 5} [get_ports {calc_clk}]
create_clock -name disp_clk -period 107.055 -waveform {0 53.528} [get_ports {display_clk}]
