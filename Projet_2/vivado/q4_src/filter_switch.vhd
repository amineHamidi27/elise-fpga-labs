-- Gestion des 2 filtres pour la question 4 (PS/PL).
-- Entrée : voie A de l'ADC (16 LSB du bus AXI de axis_red_pitaya_adc).
-- Le passe-bas (fir_low) est instancié ici, le passe-bande est le FIR Compiler
-- du block design (bp_x vers s_axis_data_tdata, m_axis_data_tdata vers bp_y).
-- sel = bit 0 de l'AXI_GPIO :
--   '0' : passe-bas sur DAC A (16 LSB), passe-bande sur DAC B (16 MSB)
--   '1' : passe-bande sur DAC A, passe-bas sur DAC B

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity filter_switch is
    port (
        clk       : in  std_logic;                      -- fs = 15,625 MHz
        sel       : in  std_logic;                      -- bit 0 du GPIO
        adc_tdata : in  std_logic_vector(31 downto 0);  -- bus de l'ADC
        bp_x      : out std_logic_vector(15 downto 0);  -- vers le FIR Compiler
        bp_y      : in  std_logic_vector(23 downto 0);  -- sortie du FIR Compiler
        dac_tdata : out std_logic_vector(31 downto 0)   -- bus du DAC
    );
end filter_switch;

architecture behav of filter_switch is

    component fir_low is
        generic (
            b0 : integer := 18;
            b1 : integer := 123;
            b2 : integer := 230
        );
        port (
            clk    : in  std_logic;
            enable : in  std_logic;
            x      : in  unsigned(13 downto 0);
            y      : out unsigned(13 downto 0)
        );
    end component;

    signal x_a          : std_logic_vector(13 downto 0);  -- voie A, signée
    signal lp_x, lp_y   : unsigned(13 downto 0);
    signal lp_s, bp_s   : std_logic_vector(13 downto 0);  -- sorties signées
    signal dac_a, dac_b : std_logic_vector(13 downto 0);

begin

    -- Voie A de l'ADC : 14 bits en complément à 2 (bits 15 et 14 = signe).
    x_a <= adc_tdata(13 downto 0);

    -- Passe-bande : entrée signée sur 16 bits, déjà étendue par l'ADC.
    bp_x <= adc_tdata(15 downto 0);
    -- Gain ~512 dans la bande : on garde les bits 22 à 9 (gain ~1).
    bp_s <= bp_y(22 downto 9);

    -- Passe-bas : entrée non signée, on inverse le bit de signe
    -- (complément à 2 -> binaire décalé), et l'inverse en sortie.
    lp_x <= unsigned((not x_a(13)) & x_a(12 downto 0));
    inst_low : fir_low port map (clk => clk, enable => '1', x => lp_x, y => lp_y);
    lp_s <= (not lp_y(13)) & std_logic_vector(lp_y(12 downto 0));

    process(clk)
    begin
        if rising_edge(clk) then
            if sel = '0' then
                dac_a <= lp_s;
                dac_b <= bp_s;
            else
                dac_a <= bp_s;
                dac_b <= lp_s;
            end if;
        end if;
    end process;

    -- 2 MSB de chaque voie = copie du bit de signe (bit 13).
    -- axis_red_pitaya_dac convertit la voie B (signe & not reste) mais passe
    -- la voie A brute : on fait donc cette conversion ici pour la voie A.
    dac_tdata <= dac_b(13) & dac_b(13) & dac_b
               & dac_a(13) & dac_a(13) & dac_a(13) & (not dac_a(12 downto 0));

end behav;
