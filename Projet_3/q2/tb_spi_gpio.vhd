library ieee;
use ieee.std_logic_1164.all;

entity tb_spi_gpio is
end tb_spi_gpio;

architecture sim of tb_spi_gpio is
    constant T : time := 8 ns;     -- 125 MHz
    signal clk   : std_logic := '0';
    signal word  : std_logic_vector(15 downto 0) := (others => '0');
    signal ctrl  : std_logic_vector(9 downto 0)  := (others => '0');
    signal sdata, sclk, fsync, dds_reset : std_logic;
begin

    uut : entity work.spi_gpio
        port map (clk => clk, word => word, ctrl => ctrl,
                  sdata => sdata, sclk => sclk, fsync => fsync, dds_reset => dds_reset);

    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    process
    begin
        -- Initial system wait
        wait for 10 * T;

        -- Write the configuration word (x"2200"), then pulse ctrl(0) to send
        word <= x"2200";
        wait for 2 * T; 
        ctrl(0) <= '1';
        wait for 4 * T;  -- Short simulated PS AXI write pulse
        ctrl(0) <= '0';

        -- Wait for the transmission to start, then wait for it to finish
        wait until fsync = '1';
        wait for 50 * T; -- Gap between AXI transfers

        -- Same for x"43A8" (e.g., LSB packet for a new frequency)
        word <= x"43A8";
        wait for 2 * T;
        ctrl(0) <= '1';
        wait for 4 * T;
        ctrl(0) <= '0';
        
        wait until fsync = '1';
        wait for 50 * T;

        -- Same for x"40EA" (e.g., MSB packet for a new frequency)
        word <= x"40EA";
        wait for 2 * T;
        ctrl(0) <= '1';
        wait for 4 * T;
        ctrl(0) <= '0';
        
        wait until fsync = '1';
        wait for 50 * T;

        wait;
    end process;

end sim;
