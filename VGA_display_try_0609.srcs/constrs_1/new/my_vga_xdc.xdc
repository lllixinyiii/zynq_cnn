#set_property PACKAGE_PIN  N15  [get_ports {rst}]
#set_property IOSTANDARD LVCMOS33 [get_ports {rst}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ov5640_pclk_IBUF]

set_property IOSTANDARD LVCMOS33 [get_ports clk_100M]

set_property IOSTANDARD LVCMOS33 [get_ports v_sync]

set_property IOSTANDARD LVCMOS33 [get_ports h_sync]

set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[11]}]

set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[7]}]


set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rgb_data[3]}]


set_property IOSTANDARD LVCMOS33 [get_ports i2c_sdat]
set_property IOSTANDARD LVCMOS33 [get_ports ov5640_xclk]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports ov5640_pwdn]
set_property IOSTANDARD LVCMOS33 [get_ports ov5640_rst_n]


set_property IOSTANDARD LVCMOS33 [get_ports ov5640_href]
set_property IOSTANDARD LVCMOS33 [get_ports ov5640_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports ov5640_vsync]


set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov5640_data[0]}]




set_property PACKAGE_PIN Y11 [get_ports i2c_sdat]
set_property PACKAGE_PIN AB9 [get_ports ov5640_href]
set_property PACKAGE_PIN AB11 [get_ports i2c_sclk]
set_property PACKAGE_PIN W11 [get_ports ov5640_pclk]


set_property PACKAGE_PIN Y10 [get_ports ov5640_pwdn]
set_property PACKAGE_PIN Y9 [get_ports clk_100M]
set_property PACKAGE_PIN AA11 [get_ports ov5640_rst_n]
set_property PACKAGE_PIN AA8 [get_ports ov5640_xclk]
set_property PACKAGE_PIN AB10 [get_ports ov5640_vsync]
set_property PACKAGE_PIN AA19 [get_ports h_sync]
set_property PACKAGE_PIN Y19 [get_ports v_sync]
set_property PACKAGE_PIN AA9 [get_ports {ov5640_data[7]}]
set_property PACKAGE_PIN W12 [get_ports {ov5640_data[6]}]
set_property PACKAGE_PIN V12 [get_ports {ov5640_data[5]}]
set_property PACKAGE_PIN W10 [get_ports {ov5640_data[4]}]
set_property PACKAGE_PIN V9 [get_ports {ov5640_data[3]}]
set_property PACKAGE_PIN V8 [get_ports {ov5640_data[2]}]
set_property PACKAGE_PIN W8 [get_ports {ov5640_data[1]}]
set_property PACKAGE_PIN V10 [get_ports {ov5640_data[0]}]
set_property PACKAGE_PIN V18 [get_ports {rgb_data[11]}]
set_property PACKAGE_PIN V19 [get_ports {rgb_data[10]}]
set_property PACKAGE_PIN U20 [get_ports {rgb_data[9]}]
set_property PACKAGE_PIN V20 [get_ports {rgb_data[8]}]
set_property PACKAGE_PIN AA21 [get_ports {rgb_data[7]}]
set_property PACKAGE_PIN AB21 [get_ports {rgb_data[6]}]
set_property PACKAGE_PIN AA22 [get_ports {rgb_data[5]}]
set_property PACKAGE_PIN AB22 [get_ports {rgb_data[4]}]
set_property PACKAGE_PIN AB19 [get_ports {rgb_data[3]}]
set_property PACKAGE_PIN AB20 [get_ports {rgb_data[2]}]
set_property PACKAGE_PIN Y20 [get_ports {rgb_data[1]}]
set_property PACKAGE_PIN Y21 [get_ports {rgb_data[0]}]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets ov5640_pclk_IBUF]
