/*
* Copyright 2018 ARDUINO SA (http://www.arduino.cc/)
* This file is part of Vidor IP.
* Copyright (c) 2018
* Authors: Dario Pennisi
*
* This software is released under:
* The GNU General Public License, which covers the main part of 
* Vidor IP
* The terms of this license can be found at:
* https://www.gnu.org/licenses/gpl-3.0.en.html
*
* You can be released from the requirements of the above licenses by purchasing
* a commercial license. Buying such a license is mandatory if you want to modify or
* otherwise use the software for commercial activities involving the Arduino
* software without disclosing the source code of your own applications. To purchase
* a commercial license, send an email to license@arduino.cc.
*
*/

module QUAD_ENCODER #(
    pENCODERS=2,
    pENCODER_PRECISION=32
  )(
    input                             iCLK,
    input                             iRESET,
    // AVALON SLAVE INTERFACE
    input  [$clog2(pENCODERS)-1:0]	  iAVL_ADDRESS,
    input        	                    iAVL_READ,
    output reg [31:0]                 oAVL_READ_DATA,
    // ENCODER INPUTS
    input [pENCODERS-1:0]             iENCODER_A,
    input [pENCODERS-1:0]             iENCODER_B
  );

  
// bidimensional arrays containing encoder input states at 4 different points in time
// the first two delay taps are used to synchronize inputs with the internal clocks
// while the other two are used to compare two points in time of those signals.
reg [3:0][pENCODERS-1:0] rRESYNC_ENCODER_A,rRESYNC_ENCODER_B;

// bidimensional arrays containing the counters for each channel
reg [pENCODERS-1:0][pENCODER_PRECISION-1:0] rSTEPS;

// encoder decrementing
// A       __----____----__
// B       ____----____----
// ENABLE  __-_-_-_-_-_-_-_
// DIR     __---_---_---_--
//     
// encoder incrementing
// A       ____----____----
// B       __----____----__
// ENABLE  __-_-_-_-_-_-_-_
// DIR     ___-___-___-___-

wire [pENCODERS-1:0] wENABLE =  rRESYNC_ENCODER_A[2]^rRESYNC_ENCODER_A[3]^rRESYNC_ENCODER_B[2]^rRESYNC_ENCODER_B[3];
wire [pENCODERS-1:0] wDIRECTION = rRESYNC_ENCODER_A[2]^rRESYNC_ENCODER_B[3];

integer i;

initial rSTEPS <=0;

always @(posedge iCLK)
begin
  if (iRESET) begin
    rSTEPS<=0;
    rRESYNC_ENCODER_A<=0;
    rRESYNC_ENCODER_B<=0;
  end
  else begin
    // implement shift registers for each channel. since arrays are packed we can treat that as a monodimensional array
    // and by adding inputs at the bottom we are effectively shifting data by one bit
    rRESYNC_ENCODER_A<={rRESYNC_ENCODER_A,iENCODER_A};
    rRESYNC_ENCODER_B<={rRESYNC_ENCODER_B,iENCODER_B};

    for (i=0;i<pENCODERS;i=i+1)
    begin
      // if strobe is high..
      if (wENABLE[i])
        // increment or decrement based on direction
        rSTEPS[i] <= rSTEPS[i]+ ((wDIRECTION[i]) ? 1 : -1);
    end
    // if slave interface is being read...
    if (iAVL_READ)
    begin
      // return the value of the counter indexed by the address
      oAVL_READ_DATA<= rSTEPS[iAVL_ADDRESS];
    end
  end
end

endmodule
