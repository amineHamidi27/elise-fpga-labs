----------------------------------------------------------------------------------
-- Company: 
-- Engineer: SE
-- 
-- Create Date: 17.01.2018 11:41:14
-- Design Name: 
-- Module Name: axis_red_pitaya_dac - Behavioral
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

entity axis_red_pitaya_dac is
GENERIC(  
    DAC_DATA_WIDTH : integer  := 14;
    AXIS_TDATA_WIDTH : integer  := 32
);
Port ( 
--PLL signals
    aclk : in std_logic;
    ddr_clk : in std_logic;
    locked : in std_logic;
    
--DAC signals
    dac_clk : out std_logic;
    dac_rst : out std_logic;
    dac_sel : out std_logic;
    dac_wrt : out std_logic;
    dac_dat : out std_logic_vector(DAC_DATA_WIDTH-1 downto 0);

--Slave side
    s_axis_tready : out std_logic;
    s_axis_tdata : in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    s_axis_tvalid : in std_logic
);
end axis_red_pitaya_dac;

architecture Behavioral of axis_red_pitaya_dac is
    signal int_dat_a_reg : std_logic_vector(DAC_DATA_WIDTH-1 downto 0);
    signal int_dat_b_reg : std_logic_vector(DAC_DATA_WIDTH-1 downto 0);
    signal int_rst_reg : std_logic;

    alias int_dat_a_wire : std_logic_vector (DAC_DATA_WIDTH-1 downto 0) is s_axis_tdata(DAC_DATA_WIDTH-1 downto 0);
    alias int_dat_b_wire : std_logic_vector (DAC_DATA_WIDTH-1 downto 0) is s_axis_tdata(AXIS_TDATA_WIDTH/2+DAC_DATA_WIDTH-1 downto AXIS_TDATA_WIDTH/2);
begin

    process
    begin
        wait until rising_edge(aclk);
        if(((not locked) or (not s_axis_tvalid)) ='1')
        then
            int_dat_a_reg <= (others =>'0');
            int_dat_b_reg <= (others =>'0');
        else
            --int_dat_a_reg <= int_dat_a_wire(DAC_DATA_WIDTH-1) & (not int_dat_a_wire(DAC_DATA_WIDTH-2 downto 0));
            int_dat_a_reg <= int_dat_a_wire(DAC_DATA_WIDTH-1 downto 0);
            int_dat_b_reg <= int_dat_b_wire(DAC_DATA_WIDTH-1) & (not int_dat_b_wire(DAC_DATA_WIDTH-2 downto 0));
        end if;
        int_rst_reg <= (not locked) or (not s_axis_tvalid);
     end process;
     
     ODDR_rst: ODDR PORT MAP (Q=>dac_rst, D1=> int_rst_reg, D2=>int_rst_reg, C=>aclk, CE=>'1', R=>'0', S=>'0');
     ODDR_sel: ODDR PORT MAP (Q=>dac_sel, D1=>'0', D2=>'1', C=>aclk, CE=>'1', R=>'0', S=>'0');
     ODDR_wrt: ODDR PORT MAP (Q=>dac_wrt, D1=>'0', D2=>'1', C=>ddr_clk, CE=>'1', R=>'0', S=>'0');
     ODDR_clk: ODDR PORT MAP (Q=>dac_clk, D1=>'0', D2=>'1', C=>ddr_clk,CE=>'1', R=>'0', S=>'0');

    DAC_DAT_gen: for j in 0 to DAC_DATA_WIDTH-1 generate
    begin  
        ODDR_inst: ODDR PORT MAP(Q=>dac_dat(j),D1 =>int_dat_a_reg(j),D2=>int_dat_b_reg(j),
        C =>aclk,CE=>'1',R=>'0',S=>'0');
    end generate;
  
    s_axis_tready <= '1';

end Behavioral;

