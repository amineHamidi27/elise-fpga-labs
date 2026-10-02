# ELISE FPGA labs

FPGA lab projects of the ELISE Master (2nd year), Université Marie et Louis Pasteur,
on the Red Pitaya board (Zynq-7010).
## Project 1: DDS

- `Project_1_DDS/PROJECT1_DDS/code/dds.vhd`: 10-bit DDS with a 14-bit sine ROM
- `code/dds_tb.vhd`: testbench
- `code/dds_top.vhd`: encapsulating file for the board (openXC7)
- `code/dds_top_250.vhd`: version with a PLL (250 MHz DAC clock)
- `code/sine_wave.m`, `code/spectre.m`: sine table and spectrum
- `rapport/`: LaTeX report

## Project 2: FIR

- `Projet_2/Pl/fir.vhd`: 4th-order low-pass FIR filter
- `Projet_2/Pl/tb_fir.vhd`: testbench
- `Projet_2/octave/filter.m`: coefficients with fir1
- `Projet_2/rapport/`: LaTeX report
