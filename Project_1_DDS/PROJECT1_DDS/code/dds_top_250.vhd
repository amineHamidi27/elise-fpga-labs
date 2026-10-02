-- Same approach as red_pitaya_pll.sv (github.com/RedPitaya/RedPitaya-FPGA):
-- a PLL generates 125 MHz for the data and 250 MHz for the DAC.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dds_top is
    port (
        adc_clk_p_i, adc_clk_n_i : in  std_logic;
        SW, GPIO                 : in  std_logic_vector(3 downto 0);
        led_o                    : out std_logic_vector(7 downto 0);
        dac_clk_o, dac_wrt_o     : out std_logic;
        dac_sel_o, dac_rst_o     : out std_logic;
        dac_dat_o                : out std_logic_vector(13 downto 0)
    );
end entity dds_top;

architecture rtl of dds_top is
    constant MID_SCALE : std_logic_vector(13 downto 0) := std_logic_vector(to_unsigned(8192, 14));
    signal clk_in, clk_in_buf       : std_logic;   -- 125 MHz from the pins
    signal clk_fb, clk250_pll, clk125_pll : std_logic;
    signal clk250, clk125           : std_logic;   -- PLL outputs after BUFG
    signal w_s                      : std_logic_vector(9 downto 0);
    signal sine_s                   : std_logic_vector(13 downto 0);
    signal chan_a                   : std_logic := '0';   -- '1' when channel A goes out next

    component IBUFDS is port (I, IB : in std_logic; O : out std_logic); end component;
    component BUFG   is port (I : in std_logic; O : out std_logic); end component;

    -- We kept only the PLL ports
    component PLLE2_ADV is
        generic (CLKFBOUT_MULT, DIVCLK_DIVIDE, CLKOUT0_DIVIDE, CLKOUT1_DIVIDE : integer;
                 CLKIN1_PERIOD : real);
        port (CLKIN1, CLKFBIN, CLKINSEL, RST, PWRDWN : in  std_logic;
              CLKOUT0, CLKOUT1, CLKFBOUT             : out std_logic);
    end component;

    component dds is
        generic (N : integer := 10);
        port (clk : in std_logic;
              W, phase_offset : in std_logic_vector(N-1 downto 0);
              sine_out : out std_logic_vector(13 downto 0));
    end component;
begin
    -- Clocks differential input -> PLL (VCO 1000 MHz) -> 250 MHz and 125 MHz
    ibuf_clk: IBUFDS port map (I => adc_clk_p_i, IB => adc_clk_n_i, O => clk_in);
    bufg_in:  BUFG   port map (I => clk_in, O => clk_in_buf);
    pll: PLLE2_ADV
        generic map (CLKFBOUT_MULT => 8, DIVCLK_DIVIDE => 1, CLKIN1_PERIOD => 8.0,
                     CLKOUT0_DIVIDE => 4,     --  250 MHz
                     CLKOUT1_DIVIDE => 8)     --  125 MHz
        port map (CLKIN1 => clk_in_buf,
                  CLKFBIN => clk_fb,
                  CLKINSEL => '1',
                  RST => '0',
                  PWRDWN => '0',
                  CLKOUT0 => clk250_pll,
                  CLKOUT1 => clk125_pll,
                  CLKFBOUT => clk_fb);
    bufg_250: BUFG port map (I => clk250_pll, O => clk250);
    bufg_125: BUFG port map (I => clk125_pll, O => clk125);

    -- DDS
    w_s   <= "00" & SW & GPIO;
    led_o <= SW & GPIO;
    inst_dds: dds
        generic map (N => 10)
        port map (clk => clk125, W => w_s, phase_offset => (others => '0'), sine_out => sine_s);

    -- DAC bus at 250 MHz: DDS sample with sel = '0' (OUT1), then mid-scale with sel = '1' (OUT2)
    process(clk250)
    begin
        if rising_edge(clk250) then
            chan_a <= not chan_a;
            if chan_a = '1' then
                dac_dat_o <= sine_s;
                dac_sel_o <= '0';
            else
                dac_dat_o <= MID_SCALE;
                dac_sel_o <= '1';
            end if;
        end if;
    end process;

    dac_clk_o <= not clk250;   -- the DAC latches on the falling edge of clk250
    dac_wrt_o <= not clk250;
    dac_rst_o <= '0';
end architecture rtl;
