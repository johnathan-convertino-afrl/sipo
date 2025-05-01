#******************************************************************************
# file:    tb_cocotb.py
#
# author:  JAY CONVERTINO
#
# date:    2025/04/16
#
# about:   Brief
# Cocotb test bench
#
# license: License MIT
# Copyright 2025 Jay Convertino
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#******************************************************************************

import random
import itertools

import cocotb
from cocotb.queue import Queue
from cocotb.clock import Clock
from cocotb.utils import get_sim_time
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event
from cocotb.binary import BinaryValue

# Class: piso
# Convert parallel data to serial
class piso:
  def __init__(self, dut):
    self._dut = dut
    self._active = False
    # Variable: wqueue
    # Queue to store write requests
    self.wqueue = Queue()
    # Variable: _idle_write
    # Event trigger for cocotb read
    self._idle_write = Event()
    self._idle_write.clear()
    self._run_cr = None
    self._restart()

  # Function: _restart
  # kill and restart _run thread.
  def _restart(self):
      if self._run_cr is not None:
          self._run_cr.kill()
      self._run_cr = cocotb.start_soon(self._run())

  async def set_data(self, data):
    self._idle_write.clear()
    await self.wqueue.put(data)
    await self._idle_write.wait()

  async def _run(self):
    self._active = False

    counter = 0

    while True:
      await RisingEdge(self._dut.clk)

      if not self.wqueue.empty():
        self._idle_write.clear()
        self._active = True
        data = await self.wqueue.get()
        if(self._dut.rev.value):
          counter = 0
        else:
          counter = self._dut.BUS_WIDTH.value*8-1


        while self._active:
          await RisingEdge(self._dut.clk)
          self._dut.sdata.value = (data >> counter) & 1
          self._dut.ena.value = 1
          await RisingEdge(self._dut.clk)
          self._dut.ena.value = 0
          await Timer(20, units="ns")
          if(self._dut.rev.value):
            counter += 1
          else:
            counter -= 1

          if((counter < 0 and not self._dut.rev.value) or (counter == self._dut.BUS_WIDTH.value*8 and self._dut.rev.value)):
            self._dut.ena.value = 0
            self._active = False
            self._idle_write.set()



# Function: random_bool
# Return a infinte cycle of random bools
#
# Returns: List
def random_bool():
  temp = []

  for x in range(0, 256):
    temp.append(bool(random.getrandbits(1)))

  return itertools.cycle(temp)

# Function: start_clock
# Start the simulation clock generator.
#
# Parameters:
#   dut - Device under test passed from cocotb test function
def start_clock(dut):
  temp = Clock(dut.clk, 1, units="ns")
  cocotb.start_soon(temp.start())
  return temp

# Function: reset_dut
# Cocotb coroutine for resets, used with await to make sure system is reset.
async def reset_dut(dut):
  dut.rstn.value = 0
  await Timer(5, units="ns")
  dut.rstn.value = 1

# Function: increment test MSb
# Coroutine that is identified as a test routine. Write data, on one clock edge, read
# on the next.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_MSb(dut):

    mclock = start_clock(dut)

    converter = piso(dut)

    dut.load.value = 0

    dut.ena.value = 0

    dut.rev.value = 0

    ena_pulse = Timer(mclock.period)

    await reset_dut(dut)

    for x in range(1, 2**8):

        await converter.set_data(x)

        await RisingEdge(dut.clk)

        dut.load.value = 1

        rx_data = dut.pdata.value.integer

        await RisingEdge(dut.clk)

        dut.load.value = 0

        assert rx_data == x, "SENT DATA DOES NOT MATCH RECEIVED"

        await Timer(20, units="ns")

    await RisingEdge(dut.clk)

# Function: increment test LSb
# Coroutine that is identified as a test routine. Write data, on one clock edge, read
# on the next.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def increment_test_LSb(dut):

    mclock = start_clock(dut)

    converter = piso(dut)

    dut.load.value = 0

    dut.ena.value = 0

    dut.rev.value = 1

    ena_pulse = Timer(mclock.period)

    await reset_dut(dut)

    for x in range(1, 2**8):

        await converter.set_data(x)

        await RisingEdge(dut.clk)

        dut.load.value = 1

        rx_data = dut.pdata.value.integer

        await RisingEdge(dut.clk)

        dut.load.value = 0

        assert rx_data == x, "SENT DATA DOES NOT MATCH RECEIVED"

        await Timer(20, units="ns")

    await RisingEdge(dut.clk)

# Function: in_reset
# Coroutine that is identified as a test routine. This routine tests if device stays
# in unready state when in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def in_reset(dut):

    start_clock(dut)

    dut.rstn.value = 0

    await Timer(50, units="ns")

    assert dut.pdata.value.integer == 0, "PDATA is not 0!"
    assert dut.dcount.value.integer == 0, f"DCOUNT is not 0"

# Function: no_clock
# Coroutine that is identified as a test routine. This routine tests if no ready when clock is lost
# and device is left in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def no_clock(dut):

    dut.rstn.value = 0

    await Timer(50, units="ns")

    assert dut.pdata.value.integer == 0, "PDATA is not 0!"
    assert dut.dcount.value.integer == 0, f"DCOUNT is not 0"
