# Ajoute le FIR passe-bande (mêmes réglages que la question 3) et sa
# constante tvalid = 1 dans le block design ouvert.
# Dans la Tcl Console de Vivado :  source <chemin>/add_fir_bandpass.tcl

create_bd_cell -type ip -vlnv xilinx.com:ip:fir_compiler:7.2 fir_bandpass
set_property -dict [list \
  CONFIG.CoefficientVector {0.003967, 0.008226, 0.007672, -0.002955, -0.021568, -0.031200, -0.011666, 0.034355, 0.070552, 0.053812, -0.019497, -0.096256, -0.106275, -0.028702, 0.080015, 0.130532, 0.080015, -0.028702, -0.106275, -0.096256, -0.019497, 0.053812, 0.070552, 0.034355, -0.011666, -0.031200, -0.021568, -0.002955, 0.007672, 0.008226, 0.003967} \
  CONFIG.Coefficient_Sets {1} \
  CONFIG.Sample_Frequency {15.625} \
  CONFIG.Clock_Frequency {15.625} \
  CONFIG.Coefficient_Sign {Signed} \
  CONFIG.Quantization {Quantize_Only} \
  CONFIG.Coefficient_Width {8} \
  CONFIG.Coefficient_Fractional_Bits {9} \
  CONFIG.Coefficient_Structure {Inferred} \
  CONFIG.Data_Sign {Signed} \
  CONFIG.Data_Width {14} \
  CONFIG.Output_Rounding_Mode {Full_Precision} \
  CONFIG.Output_Width {24} \
] [get_bd_cells fir_bandpass]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 fir_tvalid
set_property CONFIG.CONST_VAL {1} [get_bd_cells fir_tvalid]
connect_bd_net [get_bd_pins fir_tvalid/dout] [get_bd_pins fir_bandpass/s_axis_data_tvalid]
