/*
 * Copyright (C) 2015 Harmon Instruments, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/
 *
 */

`timescale 1ns / 1ps

module oversample_4x (input c, c90, r, i, output [3:0] o);

   ISERDESE2 #(
	       .DATA_RATE("DDR"),
	       .DATA_WIDTH(4),
	       .INTERFACE_TYPE("OVERSAMPLE"),
	       .IOBDELAY("IFD"),
	       .NUM_CE(2),
	       .OFB_USED("FALSE"),
	       .SERDES_MODE("MASTER")
	       )
   deser (
		.O(),
		.Q1(o[3]), // 0 degree
		.Q2(o[1]), // 180 degree
		.Q3(o[2]), // 90 degree
		.Q4(o[0]), // 270 degree
		.Q5(), .Q6(), .Q7(), .Q8(),
		.SHIFTOUT1(),.SHIFTOUT2(),
		.BITSLIP(1'b0),
		.CE1(1'b1),
		.CE2(1'b1),
		.CLKDIVP(1'b0),
		.CLK(c), .CLKB(~c),
		.CLKDIV(1'b0),
		.OCLK(c90), .OCLKB(~c90),
		.DYNCLKDIVSEL(1'b0),
		.DYNCLKSEL(1'b0),
		.D(1'b0),
		.DDLY(i),
		.OFB(1'b0),
		.RST(r),
		.SHIFTIN1(1'b0),
		.SHIFTIN2(1'b0)
		);
endmodule

module idelay_fixed(input i, output o);
   parameter DVAL = 0; // 0 to 31, 78.125 ps steps
   IDELAYE2 #(
	      .DELAY_SRC("IDATAIN"),
	      .HIGH_PERFORMANCE_MODE("FALSE"),
	      .IDELAY_TYPE("FIXED"),
	      .IDELAY_VALUE(DVAL),
	      .REFCLK_FREQUENCY(200.0),
	      .SIGNAL_PATTERN("DATA")
	      )
   del (
	     .CNTVALUEOUT(),
	     .DATAOUT(o),
	     .C(1'b0),
	     .CE(1'b0),
	     .CINVCTRL(1'b0),
	     .CNTVALUEIN(5'b0),
	     .DATAIN(1'b0),
	     .IDATAIN(i),
	     .INC(1'b0),
	     .LD(1'b0),
	     .LDPIPEEN(1'b0),
	     .REGRST(1'b0));
endmodule

// sample data every 312.5 ps using a 400 MHz clock
// c90 is 90 degrees phase shifted from
// odd output bits are inverted
// output is MSB first bit, 7 is the earliest sample taken
module oversample_8x (input c, c90, r, ip, in, output [7:0] o);
   wire [1:0] d0; // buffered
   IBUFDS_DIFF_OUT #(.DIFF_TERM("TRUE")) IB(.O(d0[0]), .OB(d0[1]), .I(ip), .IB(in));
   wire [1:0] d1; // delayed
   idelay_fixed #(.DVAL(0)) id0(.i(d0[0]), .o(d1[0]));
   idelay_fixed #(.DVAL(4)) id1(.i(d0[1]), .o(d1[1]));
   oversample_4x os0 (.c(c), .c90(c90), .r(r), .i(d1[0]), .o({o[6], o[4], o[2], o[0]}));
   oversample_4x os1 (.c(c), .c90(c90), .r(r), .i(d1[1]), .o({o[7], o[5], o[3], o[1]}));
endmodule