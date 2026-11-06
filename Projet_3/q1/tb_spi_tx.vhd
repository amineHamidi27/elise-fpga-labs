-- testbench of spi_tx
library ieee;
use ieee.std_logic_1164.all;

entity tb_spi_tx is
end tb_spi_tx;

architecture sim of tb_spi_tx is
    constant T : time := 8 ns;     -- 125 MHz
    signal clk    : std_logic := '0';
    signal enable : std_logic := '0';
    signal data   : std_logic_vector(15 downto 0) := x"2200";
    signal sclk, sdata, fin : std_logic;
begin

    uut : entity work.spi_tx
        generic map (tscale => 20, N => 16)
        port map (clk => clk, enable => enable, data => data,
                  sclk => sclk, sdata => sdata, fin => fin);

    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    process
    begin
        -- enable = '0', then '1' to send the first word
        enable <= '0';
        wait for 10 * T;
        enable <= '1';

        -- wait for fin, then enable = '0'
        wait until fin ='1';
        wait for T ;
        enable <='0';

        -- second word, changed while enable = '0'
        data <= x"4000";
        wait for 50 *T; --gap bettween packetss
        enable <='1';

        wait until fin ='1';
        wait for T;
        enable <='0';
        wait;
    end process;

end sim;
