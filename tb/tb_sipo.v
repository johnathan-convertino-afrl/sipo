//******************************************************************************
// file:    tb_sipo.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/16
//
// about:   Brief
// Test bench for Serial in Parallel out core.
//
// license: License MIT
// Copyright 2025 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A [width=0.3\textwidth]PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1 ns/10 ps

/*
 * Module: tb_sipo
 *
 * Test bench for serial in parallel out
 *
 */
module tb_sipo ();
  
  reg tb_clk = 0;
  reg tb_rstn = 0;
  reg tb_ena = 0;
  reg tb_load = 0;
  reg [7:0] tb_sdata = 0;

  reg [7:0] r_pdata = 0;

  wire [7:0] tb_pdata;
  wire [7:0] tb_dcount;

  integer counter = 0;
  
  //1ns
  localparam CLK_PERIOD = 20;

  localparam RST_PERIOD = 500;

  //Group: Instantiated Modules

  /*
   * Module: sipo
   *
   * Device under test, serial to parallel data conversion.
   */
  sipo #(
    .BUS_WIDTH(1)
  ) dut (
    .clk(tb_clk),
    .rstn(tb_rstn),
    .ena(tb_ena),
    .rev(1'b0),
    .load(tb_load),
    .pdata(tb_pdata),
    .sdata(tb_sdata[7]),
    .dcount(tb_dcount)
  );

  always @(posedge tb_clk)
  begin
    if(tb_rstn == 1'b0)
    begin
      tb_ena <= 1'b0;
      tb_load <= 1'b0;
      tb_sdata <= counter;
    end else begin
      tb_ena <= 1'b0;

      if(tb_dcount != 8)
      begin
        tb_ena <= ~tb_ena;
        if(tb_ena == 1'b1)
        begin
          tb_sdata <= {tb_sdata[6:0], 1'b0};
        end
      end else begin
        tb_sdata <= counter;
      end
    end
  end

  always @(posedge tb_clk)
  begin
    if(tb_rstn == 1'b0)
    begin
      counter <= 255;
      r_pdata <= 0;
    end else begin
      tb_load <= 1'b0;

      if(tb_dcount == 8 && tb_load != 1'b1)
      begin
        tb_load <= 1'b1;
        r_pdata <= tb_pdata;
        counter <= counter - 1;
      end

      if(counter < 0)
      begin
        $finish();
      end
    end
  end
  
  //clock
  always
  begin
    tb_clk <= ~tb_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //reset
  initial
  begin
    tb_rstn <= 1'b0;
    
    #RST_PERIOD;
    
    tb_rstn <= 1'b1;
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_sipo.fst");
    $dumpvars(0,tb_sipo);
  end

endmodule
