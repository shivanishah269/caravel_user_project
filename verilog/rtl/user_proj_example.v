// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif	
    
    input clk,reset,trace_ready;
    input [31:0] mem_addr; 
    output [19:0] L1_hit_count,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16;
    
    	main cache (
	    .clk(clk), 
	    .reset(reset),
	    .trace_ready(trace_ready),
	    .mem_addr(mem_addr),
	    .L1_hit_count(L1_hit_count),
	    .L2_hit_count4(L2_hit_count4),
	    .L2_hit_count8(L2_hit_count8),
	    .L2_hit_count16(L2_hit_count16),
	    .L2_ss1_count4(L2_ss1_count4),
	    .L2_ss1_count8(L2_ss1_count8),
	    .L2_ss1_count16(L2_ss1_count16),
	    .L2_ss2_count4(L2_ss2_count4),
	    .L2_ss2_count8(L2_ss2_count8),
	    .L2_ss2_count16(L2_ss2_count16)
    	);

endmodule
