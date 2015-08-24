/*
 * Copyright (C) 2014-2015 Harmon Instruments, LLC
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
 * LVDS remote IO
 *
 */

`timescale 1ns / 1ps

module target_tx(input c, c2x, inv, r, v, input [65:0] d, output op, on);

   reg [66:0] sr = ~67'h0;

   oserdes_4x oserdes_tx
     (.c(c2x), .cdiv(c), .t(r), .din({sr[63], sr[64], sr[65], sr[66]}), .op(op), .on(on));

   always @ (posedge c)
     sr <= v ? {1'b0, d} : {sr[64:0], 4'hF};
endmodule

module target_rx
  (
   input 	     c, // 200 MHz
   input 	     c2x, c2x_90, // 400 MHz, 400 MHz 90 deg
   input 	     ip, in, // diff pair in
   input 	     inv,
   input 	     r, // reset
   output reg [65:0] d,
   output reg 	     v = 0);

   wire [7:0] 	     d2;

   oversample_8x oversample (.c(c2x), .c90(c2x_90), .r(r), .ip(ip), .in(in), .o(d2));

   wire [3:0] 	     d3;
   wire 	     v3;

   dru dru(.c(c2x), .i(d2 ^ (inv ? 8'h55 : 8'hAA)), .d(d3), .v(v3));

   reg [3:0]   d4;
   reg 	       v4;
   reg [61:0]  d5;

   always @ (posedge c) begin
      d4 <= d3;
      v4 <= v3;
      d5 <= {d5[35:0],d4};
      if(v4)
	d <= {d5,d4};
      v <= v4;
   end
endmodule

module lvds_target
  (
   input 	 c, c2x, c2x_90,
   input 	 reset,
   input 	 sdip, sdin,
   output 	 sdop, sdon,
   output 	 wvalid,
   output [65:0] wdata,
   input 	 rvalid,
   input [65:0]  rdata
   );

   parameter TINV = 1'b0;
   parameter RINV = 1'b0;

   target_rx r(.c(c), .c2x(c2x), .c2x_90(c2x_90),
	       .r(reset),
	       .ip(sdip), .in(sdin),
	       .inv(RINV),
	       .d(wdata),
	       .v(wvalid));
   target_tx t(.c(c),
	       .c2x(c2x),
	       .inv(TINV),
	       .r(reset),
	       .d(rdata),
	       .v(rvalid),
	       .op(sdop),
	       .on(sdon));

endmodule
