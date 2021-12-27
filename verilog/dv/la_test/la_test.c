/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include "verilog/dv/caravel/defs.h"
#include "verilog/dv/caravel/stub.c"

/*
	MPRJ LA Test:
                - Sets MPRJ initial data through LA[31:0]
		- Sets MPRJ rst through LA[32]
		- Sets MPRJ wen through LA[36]
		- Sets MPRJ csb through LA[40]
                - Sets MPRJ initial address through LA[51:44]
		- Observes 10-bit result of the initial program (e.g. sum of 0 to 9) which will be written on r17 through LA[73:64]
*/

void main()
{
        /* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

	reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.


	// All GPIO pins are configured to be output
	// Used to flad the start/end of a test 

        reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

        reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

        /* Apply configuration */
        reg_mprj_xfer = 1;
        while (reg_mprj_xfer == 1);

	// Configure All LA probes 
	reg_la0_oenb = reg_la0_iena = 0x00000000;    // [31:0]   => Output from the CPU
	reg_la1_oenb = reg_la1_iena = 0x00000000;    // [63:32]  => Output from the CPU
	reg_la2_oenb = reg_la2_iena = 0xFFFFFFFF;    // [95:64]  => Input to the CPU
	reg_la3_oenb = reg_la3_iena = 0xFFFFFFFF;    // [127:96] => Input to the CPU

	// Flag start of the test
	reg_mprj_datal = 0xAB600000;

	// [31: 0] => DAT_IN 
        reg_la0_data = 0x00000000;

        // [ 3: 0] => RST // Active High
        // [ 7: 4] => WEN // Active High
        // [11: 8] => CSB // Active Low
        // [19:12] => ADR
	reg_la1_data = 0x00000000;

        // Delay
        for (int i = 0; i < 5; i++);

	// IMem initiation
	for (int i = 0; i < 13; i++) {
                reg_la1_data = 0x00000011 | i << 12;
                reg_la0_data = 
                        i == 0x0        ?       0b00000000000100000000010010010011      :
                        i == 0x1        ?       0b00000010101100000000010100010011      :
                        i == 0x2        ?       0b00000000000000000000010110010011      :
                        i == 0x3        ?       0b00000000000000000000100010010011      :
                        i == 0x4        ?       0b00000000101110001000100010110011      :
                        i == 0x5        ?       0b00000000000101011000010110010011      :
                        i == 0x6        ?       0b11111110101001011001110011100011      :
                        i == 0x7        ?       0b00000000101110001000100010110011      :
                        i == 0x8        ?       0b01000000101110001000100010110011      :
                        i == 0x9        ?       0b01000000100101011000010110110011      :
                        i == 0xA        ?       0b11111110100101011001110011100011      :
                        i == 0xB        ?       0b01000000101110001000100010110011      :
                        i == 0xC        ?       0b11111110000000000000000011100011      :
                                                0b00000000000000000000000000000000      ;
	}

        // Write enable signal de-assert and keep reset asserted
        reg_la1_data = 0x00000001;
        // Wait for a few clocks to propagate signals
        for (int i = 0; i < 2; i++);
        // Reset signal de-assert and RVMYTH starts
        reg_la1_data = 0x00000000;
        // Wait for the expected result
        while ((reg_la2_data & 0x000003FF) != 0x2D);
        // Test has been done successfully
	reg_mprj_datal = 0xAB610000;
}

