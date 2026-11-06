library ieee;
use ieee.std_logic_1164.all;

entity test_spi_tx is
    port (
        adc_clk_p_i, adc_clk_n_i : in std_logic;     -- 125 MHz clock
        SW   : in  std_logic_vector(3 downto 0);     -- SW(0) = 1: repeated sending
        GPIO : out std_logic_vector(3 downto 0)      -- SDATA, SCLK, enable (trigger), unused
    );
end test_spi_tx;

architecture a of test_spi_tx is
    signal clk_nobuf, clk : std_logic;
    signal sclk, sdata, fin, enable : std_logic;

    component IBUFDS is
        port (I, IB : in std_logic; O : out std_logic);
    end component;
    component BUFG is
        port (I : in std_logic; O : out std_logic);
    end component;
begin

    -- clock: IBUFDS + BUFG
    clk_inst0 : IBUFDS port map (I => adc_clk_p_i, IB => adc_clk_n_i, O => clk_nobuf);
    clk_inst  : BUFG   port map (I => clk_nobuf, O => clk);

    -- enable from SW(0) and fin, so that the word is sent again after each fin
    -- Astuce combinatoire : quand fin passe à '1', enable passe à '0'. 
    -- Au coup d'horloge suivant, spi_tx se reset, fin repasse à '0', et enable remonte à '1' pour relancer une trame.
    enable <= SW(0) and not fin;

    -- instance of spi_tx (tscale = 20, N = 16), data = x"2200"
    inst_spi_tx : entity work.spi_tx
        generic map (
            tscale => 20, 
            N      => 16
        )
        port map (
            clk    => clk,
            enable => enable,
            data   => x"2200", -- Mot de configuration du DDS
            sclk   => sclk,
            sdata  => sdata,
            fin    => fin
        );

    -- GPIO(0) = sdata, GPIO(1) = sclk, GPIO(2) = enable, GPIO(3) = '0'
    GPIO(0) <= sdata;
    GPIO(1) <= sclk;
    GPIO(2) <= enable; -- Utile pour déclencher (trigger) l'oscilloscope sur le début de la trame
    GPIO(3) <= '0';

end a;