# SIPO
### Serial to Parallel data core

![image](docs/manual/img/AFRL.png)

---

   author: Jay Convertino   
   
   date: 2025.04.16
   
   details: Convert Serial to Parallel data at some baud.
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [SIPO.pdf](docs/manual/SIPO.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/sipo/)

### DEPENDENCIES
#### Build

  - AFRL:utility:helper:1.0.0
  
#### Simulation

  - cocotb

### PARAMETERS

* BUS_WIDTH     : Bus width in number of bytes.

### COMPONENTS
#### SRC

* up_sipo.v

#### TB

* tb_sipo.v
* tb_cocotb.py
* tb_cocotb.v
  
### FUSESOC

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
  - sim_cocotb
