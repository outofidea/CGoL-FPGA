# Conway's game of life implementation on FPGA

- This implementation is currently based on the sipeed tang primer 20k board, which uses the GW2A-18C FPGA from Gowin. 
- RTL code was made to be as portable as possible, with the only vendor-dependant module is the rPLL
- A yosys and nextpnr-himbaechel based build flow is provided, as GowinSynthesis fails to infer the bram correctly (outputs invalid bram read mode, cant continue with pnr)
- Requires 
  - [Yosys](https://github.com/yosyshq/yosys) v0.68 or higher
  - [nextpnr-himbaechel](https://github.com/YosysHQ/nextpnr) v0.11.1 or higher built with apicula 

- nextpnr-himbaechel installation instruction could be found [here](https://github.com/YosysHQ/nextpnr#nextpnr-himbaechel)

- The initial seed is currently "hard-coded", an uart-based seed config module is to be added later