//******************************************************************************
// file:    tb_cocotb.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/16
//
// about:   Brief
// Test bench wrapper for cocotb
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.BUS_WIDTH
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: tb_cocotb
 *
 * SIPO interface DUT
 *
 * Parameters:
 *
 *   BUS_WIDTH       - Width of the data port in bytes.
 *
 * Ports:
 *
 *   clk     - Clock
 *   rstn    - negative reset
 *   ena     - enable for core, use to change input rate. Enable serial shift input.
 *   rev     - reverse, 0 is MSb first out, 1 is LSb first out.
 *   load    - load parallel data from core, and reset counters for next incoming serial data.
 *   pdata   - parallel data output, valid when dcount is BUS_WIDTH*8.
 *   sdata   - serialized data input.
 *   dcount  - Number of bits to shift out. BUS_WIDTH*8 means all bits have been sampled and put into the register.
 */
module tb_cocotb #(
    parameter BUS_WIDTH     = 4
  )
  (
      input                     clk,
      input                     rstn,
      input                     ena,
      input                     rev,
      input                     load,
      output  [BUS_WIDTH*8-1:0] pdata,
      input                     sdata,
      output  [BUS_WIDTH*8-1:0] dcount
  );
  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end
  
  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, sipo
   */
  sipo #(
    .BUS_WIDTH(BUS_WIDTH)
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .ena(ena),
    .rev(rev),
    .load(load),
    .pdata(pdata),
    .sdata(sdata),
    .dcount(dcount)
  );
  
endmodule

