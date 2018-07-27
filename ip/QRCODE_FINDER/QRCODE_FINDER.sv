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

module QRCODE_FINDER (
input             iCLK,
input             iRESET,

input             iVID_CLK,
input             iVID_RESET,
input [23:0]      iVID_DATA,
input             iVID_START,
input             iVID_DATA_VALID,

input [10:0]      iADDRESS,
input [31:0]      iWRITE_DATA,
input             iWRITE,
input             iREAD,
output  [31:0]    oREAD_DATA,

output reg [23:0] oVID_DATA,
output            oVID_START,
output            oVID_DATA_VALID
);

parameter pHRES=640;
parameter pVRES=480;
parameter pTHRESH_MIN=4;
parameter pFIXED=5;
parameter pTHRESHOLD=60;
localparam cPIPE_DEPTH=4;

reg [9:0] rHCNT;
reg [9:0] rVCNT ;
reg [cPIPE_DEPTH-1:0] rVALID_PIPE;
reg [cPIPE_DEPTH-1:0] rSTART_PIPE;
reg [cPIPE_DEPTH-1:0] rDSTART_PIPE;
reg [cPIPE_DEPTH-1:0][23:0] rDATA_PIPE;
reg [cPIPE_DEPTH-1:0][9:0] rHCNT_PIPE;
reg rDSTART;
reg [9:0] rLUM;
wire [9:0] wLUM;
wire [9:0] wLUM_NORM;
reg [cPIPE_DEPTH-1:0][9:0] rLUM_HIST;
reg [1:0] rSTATE;
reg [9:0] rPREV_CHANGE;
reg [1:0] rPREV_STATE;
reg [9:0] rPREV_HSTART;
reg [9:0] rPREV_CENT_HSTART;
reg [9:0] rPREV_CENT_HEND;
reg [9:0] rPREV_DUR;
reg [3:0] rDECODE_STATE;
reg [9:0] rREFBIT_DUR_MAX;
reg [9:0] rREFBIT_DUR_MIN;
reg [9:0] rREFBIT_3DUR_MAX;
reg [9:0] rREFBIT_3DUR_MIN;
reg [9:0] rREFBIT_HSTART;
reg rFOUND;
reg rHF1, rHF2;
reg rCHANGE;
reg [9:0] rHSTART;
reg [9:0] rHST1 , rHED1, rHST2, rHED2, rHST3, rHED3;
reg [9:0] rVST1 , rVED1, rVST2, rVED2, rVST3, rVED3;
reg       rFND1,rFND2,rFND3;
reg       rOPN1,rOPN2,rOPN3;

reg [9:0] rREG_HST1 , rREG_HED1, rREG_HST2, rREG_HED2, rREG_HST3, rREG_HED3;
reg [9:0] rREG_VST1 , rREG_VED1, rREG_VST2, rREG_VED2, rREG_VST3, rREG_VED3;
reg       rREG_FND1,rREG_FND2,rREG_FND3;
reg rUPDATE, rREFRESH;
wire signed [11:0] wLUM_DIFF;
reg signed [10:0] rLUM_DIFF;
reg signed [12:0] rTHRESHOLD;
wire [19:0] wLB_RAM_DATA;
reg [10:0] rAVL_ADDRESS;
reg [31:0] rREADDATA;

typedef enum {
  stNONE,
  stWHITE,
  stBLACK} eSTATES;

typedef enum {
  dsIDLE,
  dsFIRST,
  dsSECOND,
  dsCENTER,
  dsTHIRD,
  dsFOURTH} eDECODE_STATES;
  
// convert from RGB 8 bit to luminance 10 bit
assign wLUM = {2'b0,iVID_DATA[7:0]}+
              {2'b0,iVID_DATA[15:8]}+
              {2'b0,iVID_DATA[23:16]};

// normalize so that we have full scale on 10 bit
assign wLUM_NORM = rLUM+rLUM[9:2]+rLUM[9:4]+rLUM[9:6]+rLUM[9:8];
assign oVID_START=rSTART_PIPE[2];
assign oVID_DATA_VALID=rVALID_PIPE[2];

initial rTHRESHOLD<=pTHRESHOLD;

altsyncram #(
  .address_aclr_b                     ( "NONE" ),
  .address_reg_b                      ( "CLOCK0" ),
  .clock_enable_input_a               ( "BYPASS" ),
  .clock_enable_input_b               ( "BYPASS" ),
  .clock_enable_output_b              ( "BYPASS" ),
  .intended_device_family             ( "Cyclone 10 LP" ),
  .lpm_type                           ( "altsyncram" ),
  .numwords_a                         ( 1024 ),
  .numwords_b                         ( 1024 ),
  .operation_mode                     ( "DUAL_PORT" ),
  .outdata_aclr_b                     ( "NONE" ),
  .outdata_reg_b                      ( "UNREGISTERED" ),
  .power_up_uninitialized             ( "FALSE" ),
  .read_during_write_mode_mixed_ports ( "DONT_CARE" ),
  .widthad_a                          ( 10 ),
  .widthad_b                          ( 10 ),
  .width_a                            ( 20 ),
  .width_b                            ( 20 ),
  .width_byteena_a                    ( 1 )
) line_buffer (
  .address_a                          ( rHCNT ), //write
  .address_b                          ( rHCNT ), //read
  .clock0                             ( iVID_CLK ),
  .data_a                             ( {wLB_RAM_DATA,rLUM_DIFF[10:1]} ),
  .wren_a                             ( rVALID_PIPE[1] ),
  .q_b                                ( wLB_RAM_DATA ),
  .aclr0                              ( 1'b0 ),
  .aclr1                              ( 1'b0 ),
  .addressstall_a                     ( 1'b0 ),
  .addressstall_b                     ( 1'b0 ),
  .byteena_a                          ( 1'b1 ),
  .byteena_b                          ( 1'b1 ),
  .clock1                             ( 1'b1 ),
  .clocken0                           ( 1'b1 ),
  .clocken1                           ( 1'b1 ),
  .clocken2                           ( 1'b1 ),
  .clocken3                           ( 1'b1 ),
  .data_b                             ( {32{1'b1}} ),
  .eccstatus                          ( ),
  .q_a                                ( ),
  .rden_a                             ( 1'b1 ),
  .rden_b                             ( 1'b1 ),
  .wren_b                             ( 1'b0 )
);

reg [1:0] rOUTMODE;
reg [9:0] rDETECT_ADDR;
wire [31:0] wDETECT_DATA;
reg         rDETECT_WRITE;

altsyncram #(
  .address_reg_b                      ( "CLOCK1" ),
  .byte_size                          ( 8 ),
  .byteena_reg_b                      ( "CLOCK1" ),
  .indata_reg_b                       ( "CLOCK1" ),
  .lpm_type                           ( "altsyncram" ),
  .maximum_depth                      ( 1024 ),
  .numwords_a                         ( 1024 ),
  .numwords_b                         ( 1024 ),
  .operation_mode                     ( "BIDIR_DUAL_PORT" ),
  .outdata_reg_a                      ( "UNREGISTERED" ),
  .outdata_reg_b                      ( "UNREGISTERED" ),
  .ram_block_type                     ( "AUTO" ),
  .read_during_write_mode_mixed_ports ( "DONT_CARE" ),
  .width_a                            ( 32 ),
  .width_b                            ( 32 ),
  .width_byteena_a                    ( 4 ),
  .width_byteena_b                    ( 4 ),
  .widthad_a                          ( 10 ),
  .widthad_b                          ( 10 ),
  .wrcontrol_wraddress_reg_b          ( "CLOCK1" )
) results ( .address_a                          ( rDETECT_ADDR ), //write
  .address_b                          ( iADDRESS ), //read
  .clock0                             ( iVID_CLK ),
  .clock1                             ( iCLK ),
  .data_a                             ( rUPDATE? {32{1'b1}} : {rVCNT,rPREV_CENT_HSTART,rPREV_CENT_HEND} ),
  .wren_a                             ( rDETECT_WRITE ),
  .q_b                                ( wDETECT_DATA ),
  .data_b                             ( {32{1'b1}} ),
  .byteena_a                          ( 4'b1111 ),
  .byteena_b                          ( 4'b1111 ),
  .rden_a                             ( 1'b1 ),
  .rden_b                             ( 1'b1 ),
  .wren_b                             ( 1'b0 )
);

always @(posedge iCLK)
begin
  if (iWRITE) begin
    case (iADDRESS)
      0: {rOUTMODE,rREFRESH}<= iWRITE_DATA;
      1: rTHRESHOLD <= iWRITE_DATA;
    endcase
  end
  rAVL_ADDRESS <= iADDRESS;
  if (iREAD) begin
    case (iADDRESS)
      0 : rREADDATA<= {rOUTMODE,rUPDATE}; //control
      default: rREADDATA<=0;
    endcase
  end
  if (rREFRESH&!rUPDATE)
    rREFRESH<=0;
end

assign oREADDATA = rAVL_ADDRESS[10] ? wDETECT_DATA : rREADDATA;
assign wLUM_DIFF = { {2{rLUM_DIFF[10]}},rLUM_DIFF[10:1]} + { {1{wLB_RAM_DATA[9]}},wLB_RAM_DATA[9:0],1'b0} + {{2{wLB_RAM_DATA[19]}},wLB_RAM_DATA[19:10]};
always @(posedge iVID_CLK)
begin
  rDETECT_WRITE<=0;
  if (rDETECT_WRITE)
    rDETECT_ADDR<=rDETECT_ADDR+1;
    
  rDATA_PIPE  <= {rDATA_PIPE,iVID_DATA};
  rVALID_PIPE <= {rVALID_PIPE,iVID_DATA_VALID};
  rSTART_PIPE <= {rSTART_PIPE,iVID_START};
  rDSTART_PIPE <= {rDSTART_PIPE,rDSTART};
  rHCNT_PIPE <= {rHCNT_PIPE,rHCNT};
  //first pipeline stage
  if (iVID_DATA_VALID) begin
    rDSTART <= iVID_START;
    rLUM    <= wLUM;
    rHCNT   <= rHCNT+1;
    if (rHCNT==pHRES-1) begin
      rHCNT<=0;
      rSTATE<=stNONE;
      rVCNT<=rVCNT+1;
      rDSTART_PIPE[0]<=1;
    end
    if (rDSTART) begin
      rHCNT<=0;
      rVCNT<=0;
      if (rUPDATE&&rREFRESH) begin
        rUPDATE<=0;
        rDETECT_ADDR<=0;
      end
      if (!rUPDATE) begin
        rUPDATE <=1;
        rDETECT_WRITE<=1;
        
      end
      rSTATE<=stNONE;
    end
  end
  //second pipeline stage
  if (rVALID_PIPE[0]) begin
    rLUM_DIFF <= {1'b0,rLUM_HIST[0]}-{1'b0,rLUM_HIST[2]};
    rLUM_HIST <= {rLUM_HIST,wLUM_NORM};
    if (rDSTART_PIPE[0]) begin
      rLUM_HIST<={cPIPE_DEPTH-1{wLUM_NORM}};
      rLUM_DIFF<=0;
    end
  end
  //third pipeline stage
  if (rVALID_PIPE[1]) begin
    rCHANGE<=0;
    oVID_DATA<= rOUTMODE==0 ? rDATA_PIPE[1] :
                rOUTMODE==1 ? {3{rLUM_HIST[0][9:2]}} :
                rOUTMODE==2 ? (rSTATE==stNONE) ? {3{8'h80}} : 
                              (rSTATE==stBLACK) ? {3{8'h0}} : {3{8'hFF}}  :
                              0;

    //  check for rising edge
    if ((wLUM_DIFF>0) && (wLUM_DIFF > rTHRESHOLD ) ) begin
      if ((rSTATE==stWHITE && rPREV_CHANGE<wLUM_DIFF) || 
          (rSTATE!=stWHITE) ) begin
        rHSTART<= rHCNT_PIPE[1];
        rPREV_CHANGE<= wLUM_DIFF;
        if (rSTATE!=stWHITE) begin
          rSTATE <= stWHITE;
          rPREV_STATE <= rSTATE;
          rPREV_HSTART <= rHSTART;
          rCHANGE<=1;
          if (rOUTMODE!=0) oVID_DATA<= 24'hff0000;
          rPREV_DUR<=rHCNT_PIPE[0]-rHSTART;
        end
      end
    end

    //  check for falling edge
    if ((wLUM_DIFF<0) && ((-wLUM_DIFF) > rTHRESHOLD ) ) begin
      if ((rSTATE==stBLACK && rPREV_CHANGE<(-wLUM_DIFF)) || 
          (rSTATE!=stBLACK) ) begin
        rHSTART<= rHCNT_PIPE[1];
        rPREV_CHANGE<= -wLUM_DIFF;
        if (rSTATE!=stBLACK) begin
          rSTATE <= stBLACK;
          rPREV_STATE <= rSTATE;
          rPREV_HSTART <= rHSTART;
          rCHANGE<=1;
          if (rOUTMODE!=0) oVID_DATA<= 24'h0000ff;
          rPREV_DUR<=rHCNT_PIPE[0]-rHSTART;
        end
      end
    end
    if (rDSTART_PIPE[1]) begin
      rPREV_STATE<={2{stNONE}};
      rHSTART <=0;
      rCHANGE<=0;
    end
    rFOUND<=0;
    if (rFOUND && rOUTMODE!=0)
      oVID_DATA<= 24'h00FF00;
  end
  //fourth pipeline stage
  if (rVALID_PIPE[2]) begin
    if (rDSTART_PIPE[2])
      rDECODE_STATE<=dsIDLE;
    else if (rCHANGE) begin
      case (rDECODE_STATE)
        dsIDLE: begin
          if (rPREV_STATE==stBLACK) begin
            rREFBIT_DUR_MAX <=rPREV_DUR+(rPREV_DUR>>3)+1;
            rREFBIT_DUR_MIN <=rPREV_DUR-(rPREV_DUR>>3)-1;
            rREFBIT_3DUR_MAX <=(rPREV_DUR<<1)+rPREV_DUR+(rPREV_DUR>>2)+(rPREV_DUR>>3)+3;
            rREFBIT_3DUR_MIN <=(rPREV_DUR<<1)+rPREV_DUR-(rPREV_DUR>>2)-(rPREV_DUR>>3)-3;
            rDECODE_STATE<=dsFIRST;
            rREFBIT_HSTART<= rPREV_HSTART;
          end
        end
        dsFIRST: begin
          if ((rREFBIT_DUR_MAX>=rPREV_DUR) && 
              (rREFBIT_DUR_MIN<=rPREV_DUR)  ) begin
            rDECODE_STATE<= dsCENTER;
          end
          else 
            rDECODE_STATE<= dsIDLE;
        end
        dsCENTER: begin
          if ((rREFBIT_3DUR_MAX>=rPREV_DUR) && 
              (rREFBIT_3DUR_MIN<=rPREV_DUR)  ) begin
            rDECODE_STATE<= dsTHIRD;
            rPREV_CENT_HSTART<= rPREV_HSTART;
          end
          else begin
            rREFBIT_DUR_MAX <=rPREV_DUR+(rPREV_DUR>>3)+1;
            rREFBIT_DUR_MIN <=rPREV_DUR-(rPREV_DUR>>3)-1;
            rREFBIT_3DUR_MAX <=(rPREV_DUR<<1)+rPREV_DUR+(rPREV_DUR>>2)+(rPREV_DUR>>3)+3;
            rREFBIT_3DUR_MIN <=(rPREV_DUR<<1)+rPREV_DUR-(rPREV_DUR>>2)-(rPREV_DUR>>3)-3;
            rDECODE_STATE<=dsFIRST;
            rREFBIT_HSTART<= rPREV_HSTART;
          end
        end
        dsTHIRD: begin
          if ((rREFBIT_DUR_MAX>=rPREV_DUR) && 
              (rREFBIT_DUR_MIN<=rPREV_DUR)  ) begin
            rDECODE_STATE<= dsFOURTH;
            rPREV_CENT_HEND<= rPREV_HSTART;
          end
          else 
            rDECODE_STATE<= dsIDLE;
        end
        dsFOURTH: begin
          if ((rREFBIT_DUR_MAX>=rPREV_DUR) && 
              (rREFBIT_DUR_MIN<=rPREV_DUR)  ) begin
            rDECODE_STATE<= dsIDLE;
            // pattern found!!!
            rFOUND<=1;
            rDETECT_WRITE<=!rUPDATE;
          end
          else begin
            rREFBIT_DUR_MAX <=rPREV_DUR+(rPREV_DUR>>3)+1;
            rREFBIT_DUR_MIN <=rPREV_DUR-(rPREV_DUR>>3)-1;
            rREFBIT_3DUR_MAX <=(rPREV_DUR<<1)+rPREV_DUR+(rPREV_DUR>>2)+(rPREV_DUR>>3)+3;
            rREFBIT_3DUR_MIN <=(rPREV_DUR<<1)+rPREV_DUR-(rPREV_DUR>>2)-(rPREV_DUR>>3)-3;
            rDECODE_STATE<=dsFIRST;
            rREFBIT_HSTART<= rPREV_HSTART;
          end
        end
      endcase
    end
  end
end
endmodule