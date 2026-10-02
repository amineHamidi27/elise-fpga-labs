library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dds_top is
    port (
        -- Horloge differentielle 125 MHz
        adc_clk_p_i : in  std_logic;
        adc_clk_n_i : in  std_logic;

        -- 4 switchs + 4 GPIO 
        SW          : in  std_logic_vector(3 downto 0);
        GPIO        : in  std_logic_vector(3 downto 0);
        led_o       : out std_logic_vector(7 downto 0);

        -- DAC 
        dac_clk_o   : out std_logic;
        dac_rst_o   : out std_logic;
        dac_sel_o   : out std_logic;
        dac_wrt_o   : out std_logic;
        dac_dat_o   : out std_logic_vector(13 downto 0)
    );
end entity dds_top;

architecture rtl of dds_top is

    signal clk_nobuf_s : std_logic;
    signal clk125      : std_logic;
    signal w_s            : std_logic_vector(9 downto 0);
    signal phase_offset_s : std_logic_vector(9 downto 0);
    signal dds_data_s     : std_logic_vector(13 downto 0);

    component IBUFDS is
        port (
            I  : in  std_logic;
            IB : in  std_logic;
            O  : out std_logic
        );
    end component;

    component BUFG is
        port (
            I : in  std_logic;
            O : out std_logic
        );
    end component;

    component dds is
        generic (
            N : integer := 10
        );
        port (
            clk          : in  std_logic;
            w            : in  std_logic_vector(N - 1 downto 0);
            phase_offset : in  std_logic_vector(N - 1 downto 0);
            sine_out      : out std_logic_vector(13 downto 0)
        );
    end component;

begin

    -- 1. Conditionnement horloge
    clk_inst0: IBUFDS port map (I => adc_clk_p_i, IB => adc_clk_n_i, O => clk_nobuf_s);
    clk_inst1: BUFG   port map (I => clk_nobuf_s, O => clk125);

    phase_offset_s <= (others => '0');
    w_s <= "00" & SW & GPIO;

    -- Retour visuel de l'etat des entrees sur les LEDs
    led_o <= SW & GPIO;

    -- 3. Instanciation  DDS
    inst_dds: dds
        generic map (
            N => 10
        )
        port map (
            clk          => clk125,
            w            => w_s,
            phase_offset => phase_offset_s,
            sine_out      => dds_data_s
        );

    -- 4. Signaux de synchronisation DAC
    dac_clk_o <= not clk125;
    dac_wrt_o <= not clk125;
    dac_rst_o <= '0';
    dac_sel_o <= '0';

    process(clk125)
    begin
        if rising_edge(clk125) then
        -- dac_dat_o <= not dds_data_s;
            dac_dat_o <= dds_data_s;
        end if;
    end process;
end architecture rtl;
