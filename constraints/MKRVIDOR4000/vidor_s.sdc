## Generated SDC file "arduino_c10.sdc"

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.1.1 Internal Build 593 12/11/2017 SJ Standard Edition"

## DATE    "Sun Feb 18 22:17:54 2018"

##
## DEVICE  "10CL010YU256C8G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name mipi_clk -period 15.38 [get_ports {iMIPI_CLK}]
create_clock -name iCLK -period 20.833 [get_ports {iCLK}]

derive_pll_clocks

#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name oSDRAM_CLK -source [get_pins PLL_inst|altpll_component|auto_generated|pll1|clk[3]] [get_ports {oSDRAM_CLK}]


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_A*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_D*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_R*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CA*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CK*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CS*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_W*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_BA*]
set_output_delay -max 1.5 -clock [get_clocks oSDRAM_CLK]  [get_ports bSDRAM_D*]

set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_A*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_D*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_R*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CA*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CK*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_CS*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_W*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports oSDRAM_BA*]
set_output_delay -min -0.8 -clock [get_clocks oSDRAM_CLK]  [get_ports bSDRAM_D*]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -to [get_keepers {*altera_std_synchronizer:*|din_s1}]
set_false_path -from [get_keepers {sld_hub:*|irf_reg*}] -to [get_keepers {*system_nios2_gen2_0_cpu:*|system_nios2_gen2_0_cpu_nios2_oci:the_system_nios2_gen2_0_cpu_nios2_oci|system_nios2_gen2_0_cpu_debug_slave_wrapper:the_system_nios2_gen2_0_cpu_debug_slave_wrapper|system_nios2_gen2_0_cpu_debug_slave_sysclk:the_system_nios2_gen2_0_cpu_debug_slave_sysclk|ir*}]
set_false_path -from [get_keepers {sld_hub:*|sld_shadow_jsm:shadow_jsm|state[1]}] -to [get_keepers {*system_nios2_gen2_0_cpu:*|system_nios2_gen2_0_cpu_nios2_oci:the_system_nios2_gen2_0_cpu_nios2_oci|system_nios2_gen2_0_cpu_nios2_oci_debug:the_system_nios2_gen2_0_cpu_nios2_oci_debug|monitor_go}]
set_false_path -from [get_clocks {mipi_clk}] -to [get_clocks {PLL_inst|altpll_component|auto_generated|pll1|clk[2]}]
set_false_path -from [get_clocks {PLL_inst|altpll_component|auto_generated|pll1|clk[2]}] -to [get_clocks {mipi_clk}]

#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -from {memory:u0|AES_AVL:aes_0|*} -to {memory:u0|AES_AVL:aes_0|*} -setup -end 2

#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

