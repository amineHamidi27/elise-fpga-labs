----------------------------------------------------------------------------------
-- Company: 
-- Engineer: SE
-- 
-- Create Date: 17.01.2018 11:05:21
-- Design Name: 
-- Module Name: axis_red_pitaya_adc - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:d'après A.Potocnik / Pavel Demin
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity axis_red_pitaya_adc is
GENERIC(
    ADC_DATA_WIDTH : integer := 14;
    AXIS_TDATA_WIDTH : integer :=32
    );
Port ( 
-- System signals
    adc_clk : out std_logic;

-- ADC signals
    adc_csn : out std_logic;
    adc_clk_p : in std_logic;
    adc_clk_n : in std_logic;
    adc_dat_a : in std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
    adc_dat_b : in std_logic_vector(ADC_DATA_WIDTH-1 downto 0); 

--Master side
    m_axis_tvalid : out std_logic;
    m_axis_tdata : out std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0)
  -- 
  );
end axis_red_pitaya_adc;

architecture Behavioral of axis_red_pitaya_adc is
    constant PADDING_WIDTH : integer := AXIS_TDATA_WIDTH/2 - ADC_DATA_WIDTH;
    signal int_dat_a_reg : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) ;
    signal int_dat_b_reg : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) ;
    signal int_clk0 : std_logic;
    signal int_clk : std_logic;    
    signal pad_a : std_logic_vector(PADDING_WIDTH downto 0);
    signal pad_b : std_logic_vector(PADDING_WIDTH downto 0);  
begin
    adc_clk_inst0 : IBUFGDS PORT MAP(I=>adc_clk_p,IB =>adc_clk_n,O =>int_clk0);
    adc_clk_inst : BUFG  PORT MAP(I=>int_clk0, O=>int_clk);

  process
  begin
    wait until rising_edge(int_clk);
    int_dat_a_reg <= adc_dat_a;
    int_dat_b_reg <= adc_dat_b;
  end process;
  
  adc_clk <= int_clk;
  adc_csn <= '1';
  m_axis_tvalid <= '1';
  
  pad_b <= (others => int_dat_b_reg(ADC_DATA_WIDTH-1));
  pad_a <= (others => int_dat_a_reg(ADC_DATA_WIDTH-1));
  m_axis_tdata <= pad_b & (not int_dat_b_reg(ADC_DATA_WIDTH-2 downto 0)) & pad_a & (not int_dat_a_reg(ADC_DATA_WIDTH-2 downto 0));

end Behavioral;

