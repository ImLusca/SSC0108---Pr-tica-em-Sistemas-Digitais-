//lpm_decode CBX_SINGLE_OUTPUT_FILE="ON" LPM_DECODES=16 LPM_TYPE="LPM_DECODE" LPM_WIDTH=4 data
//VERSION_BEGIN 24.1 cbx_mgl 2025:03:05:20:07:01:SC cbx_stratixii 2025:03:05:20:06:36:SC cbx_util_mgl 2025:03:05:20:06:36:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2025  Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus Prime License Agreement,
//  the Altera IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Altera and sold by Altera or its authorized distributors.  Please
//  refer to the Altera Software License Subscription Agreements 
//  on the Quartus Prime software download page.



//synthesis_resources = lpm_decode 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mg4h8
	( 
	data) /* synthesis synthesis_clearbox=1 */;
	input   [3:0]  data;


	lpm_decode   mgl_prim1
	( 
	.data(data));
	defparam
		mgl_prim1.lpm_decodes = 16,
		mgl_prim1.lpm_type = "LPM_DECODE",
		mgl_prim1.lpm_width = 4;
endmodule //mg4h8
//VALID FILE
