//******************************************************************************
// file:    sipo.v
//
// author:  JAY CONVERTINO
//
// date:    2025/04/15
//
// about:   Brief
// SIPO (serial in parallel out) The idea is to keep this core simple,
// and let the control logic be handled outside of this core.
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
// IN THE SOFTWARE.
//
//******************************************************************************

`resetall
`timescale 1 ns/100 ps
`default_nettype none

/*
 * Module: sipo
 *
 * Serial to Parallel out
 *
 * Parametes:
 *  BUS_WIDTH    - width of the parallel data input in bytes.
 *
 * Ports:
 *  clk               - global clock for the core.
 *  rstn              - negative syncronus reset to clk.
 *  ena               - enable for core, use to change input rate. Enable serial shift input.
 *  rev               - reverse, 0 is MSb first out, 1 is LSb first out.
 *  load              - load parallel data from core, and reset counters for next incoming serial data.
 *  pdata             - parallel data output, valid when dcount is BUS_WIDTH*8 or reg_count_amount
 *  reg_count_amount  - If anything other than zero, the dcount and data output will use this value instead of the BUS_WIDTH size.
 *  sdata             - serialized data input.
 *  dcount            - Number of bits to shift out. BUS_WIDTH*8 or COUNT_AMOUNT means all bits have been sampled and put into the register.
 *
 */
module sipo #(
      parameter BUS_WIDTH = 1,
      parameter COUNT_AMOUNT = 0
    ) (
      input   wire                    clk,
      input   wire                    rstn,
      input   wire                    ena,
      input   wire                    rev,
      input   wire                    load,
      output  wire  [BUS_WIDTH*8-1:0] pdata,
      input   wire  [ 7:0]            reg_count_amount,
      input   wire                    sdata,
      output  wire  [ 7:0]            dcount
    );

    wire [ 7:0] s_count_amount;

    // data count register
    reg [ 7:0] r_dcount;

    // amount to count register
    reg [ 7:0] r_count_amount;

    // register to contain input parallel data that is positive edge shifted.
    reg [BUS_WIDTH*8-1:0] r_pdata;

    // assign counter to output data count so cores can track output status.
    assign dcount = r_dcount;

    // assign parallel data register to output.
    assign pdata = r_pdata;

    assign s_count_amount = (reg_count_amount > BUS_WIDTH*8 : BUS_WIDTH*8 : (reg_count_amount == 0 ? BUS_WIDTH*8 : reg_count_amount));

    // Positive edge data count that is incremented on enable pulse.
    always @(posedge clk)
    begin
      if(rstn == 1'b0)
      begin
        r_dcount        <= 0;
        r_count_amount  <= s_count_amount;
      end else begin
        r_dcount <= r_dcount;

        if(r_dcount == 0)
        begin
          r_count_amount <= s_count_amount;
        end

        if(ena == 1'b1)
        begin
          r_dcount <= r_dcount + 1;
        end

        if(load == 1'b1)
        begin
          r_dcount <= 0;
        end

        if(r_dcount == r_count_amount && load != 1'b1)
        begin
          r_dcount <= r_dcount;
        end
      end
    end

    // Positive edge shift register, serial data is shifted (C) in on clk+ena.
    always @(posedge clk)
    begin
      if(rstn == 1'b0)
      begin
        r_pdata <= 0;
      end else begin
        r_pdata <= r_pdata;

        // shift in data till we hit are count.
        if(ena == 1'b1 && r_dcount != r_count_amount)
        begin
          if(rev == 1'b0)
          begin
            r_pdata <= {r_pdata[BUS_WIDTH*8-2:0], sdata};
          end else begin
            r_pdata[r_dcount] <= sdata;
          end
        end

        if(load == 1'b1)
        begin
          r_pdata <= 0;
        end
      end
    end

endmodule

`resetall
