//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.12.03 
//Created Time: 2026-09-01 06:14:19
create_clock -name crystal_osc -period 37.037 -waveform {0 18} [get_ports {ext_27M_osc}]
create_generated_clock -name calc_clk -source [get_ports {ext_27M_osc}] -master_clock crystal_osc -multiply_by 3 [get_nets {calc_clk}]
create_generated_clock -name disp_clk -source [get_nets {calc_clk}] -master_clock calc_clk -divide_by 8 [get_nets {disp_clk}]
