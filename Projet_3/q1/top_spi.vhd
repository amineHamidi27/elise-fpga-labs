library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_spi is
    port (
        adc_clk_p_i, adc_clk_n_i : in std_logic;            -- 125 MHz clock
        SW      : in  std_logic_vector(3 downto 0);
        Button  : in  std_logic;
        led_o   : out std_logic_vector(7 downto 0);
        gfedcba : out std_logic_vector(6 downto 0);         -- 7-segment display
        GPIO    : out std_logic_vector(3 downto 0)          -- SDATA, SCLK, FSYNC, RESET
    );
end top_spi;

architecture a of top_spi is
    signal clk_nobuf, clk : std_logic;
    signal word           : std_logic_vector(15 downto 0);  -- word to send
    signal nibble         : std_logic_vector(3 downto 0);   -- half-byte displayed
    signal sclk, sdata, fsync, enable, fin : std_logic;

    -- Xilinx primitives for the clock (as in ADC_DAC.vhd)
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

    -- Choice of the word with SW(1 downto 0) (0x2200 and your frequency words)
    process(SW(1 downto 0))
    begin
        case SW(1 downto 0) is
            when "00" => word <= x"2200"; -- control register: D13 = 1 (2 packets), D9 = 1 (hardware reset)
            when "01" => word <= x"43A8"; -- FREQ0, 14 LSB of W (1 MHz)
            when "10" => word <= x"40EA"; -- FREQ0, 14 MSB of W (1 MHz)
            when others => word <= x"C000"; -- PHASE0 = 0
        end case;
    end process;

    -- instance of spi_tx
    inst_spi_tx : entity work.spi_tx
        generic map (tscale => 20, N => 16)
        port map (
            clk    => clk,
            enable => enable,
            data   => word,
            sclk   => sclk,
            sdata  => sdata,
            fin    => fin
        );

    -- instance of fsm_spi
    inst_fsm_spi : entity work.fsm_spi
        port map (
            clk    => clk,
            button => Button,
            fin    => fin,
            fsync  => fsync,
            enable => enable
        );

    -- half-byte chosen with SW(3 downto 2), and 7-segment decoding
    -- LEDs = byte containing this half-byte
    process(SW(3 downto 2), word)
    begin
        case SW(3 downto 2) is
            when "00" => 
                nibble <= word(3 downto 0);   -- Bits 3-0
                led_o  <= word(7 downto 0);   -- Display lower byte
            when "01" => 
                nibble <= word(7 downto 4);   -- Bits 7-4
                led_o  <= word(7 downto 0);   -- Display lower byte
            when "10" => 
                nibble <= word(11 downto 8);  -- Bits 11-8
                led_o  <= word(15 downto 8);  -- Display upper byte
            when others => 
                nibble <= word(15 downto 12); -- Bits 15-12
                led_o  <= word(15 downto 8);  -- Display upper byte
        end case;
    end process;

    process(nibble)
    begin
        case nibble is   -- active-low display: '0' turns a segment on
            when "0000" => gfedcba <= "1000000"; -- 0
            when "0001" => gfedcba <= "1111001"; -- 1
            when "0010" => gfedcba <= "0100100"; -- 2
            when "0011" => gfedcba <= "0110000"; -- 3
            when "0100" => gfedcba <= "0011001"; -- 4
            when "0101" => gfedcba <= "0010010"; -- 5
            when "0110" => gfedcba <= "0000010"; -- 6
            when "0111" => gfedcba <= "1111000"; -- 7
            when "1000" => gfedcba <= "0000000"; -- 8
            when "1001" => gfedcba <= "0010000"; -- 9
            when "1010" => gfedcba <= "0001000"; -- A
            when "1011" => gfedcba <= "0000011"; -- b
            when "1100" => gfedcba <= "1000110"; -- C
            when "1101" => gfedcba <= "0100001"; -- d
            when "1110" => gfedcba <= "0000110"; -- E
            when "1111" => gfedcba <= "0001110"; -- F
            when others => gfedcba <= "1111111"; -- off
        end case;
    end process;

    GPIO(0) <= sdata;
    GPIO(1) <= sclk;
    GPIO(2) <= fsync;
    GPIO(3) <= '0';          -- RESET of the DDS, inactive

end a;