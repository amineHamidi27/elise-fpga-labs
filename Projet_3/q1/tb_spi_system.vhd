library ieee;
use ieee.std_logic_1164.all;

entity tb_spi_system is
end tb_spi_system;

architecture sim of tb_spi_system is
    constant T : time := 8 ns;     -- 125 MHz
    signal clk    : std_logic := '0';
    signal button : std_logic := '0';
    signal data   : std_logic_vector(15 downto 0) := x"2200";
    signal sclk, sdata, fsync, enable, fin : std_logic;
begin

    -- Instance of spi_tx (clk, enable, data -> sclk, sdata, fin)
    inst_spi_tx : entity work.spi_tx
        generic map (
            tscale => 20, 
            N => 16
        )
        port map (
            clk    => clk,
            enable => enable,
            data   => data,
            sclk   => sclk,
            sdata  => sdata,
            fin    => fin
        );

    -- Instance of fsm_spi (clk, button, fin -> fsync, enable)
    inst_fsm_spi : entity work.fsm_spi
        port map (
            clk    => clk,
            button => button,
            fin    => fin,
            fsync  => fsync,
            enable => enable
        );

    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    process
    begin
        -- Initial wait
        wait for 10 * T;

        -- Short press (button released before the end of the sending)
        button <= '1';
        wait for 4 * T; 
        button <= '0';
        
        -- Wait for the end (fsync back to '1')
        wait until fsync = '1';
        wait for 50 * T; -- Gap between words
        
        -- Change data, then long press (button still pressed after fin)
        data <= x"4000";
        button <= '1';
        
        -- Wait for transmission to finish, but keep holding the button
        wait until fsync = '1'; 
        
        -- Wait a bit longer to verify no secondary transmission starts
        wait for 20 * T; 
        
        -- Release the button
        button <= '0';
        wait for 20 * T;

        wait;
    end process;

    -- Optional: process that rebuilds the word on the falling edges of sclk
    -- (like the DDS) and checks it with assert when fsync goes back to '1'
    process
        variable received_word : std_logic_vector(15 downto 0);
    begin
        while true loop
            -- Wait for the Moore machine to assert FSYNC (active low)
            wait until fsync = '0';
            
            -- Read 16 bits on the falling edges of SCLK
            for i in 15 downto 0 loop
                wait until falling_edge(sclk);
                received_word(i) := sdata;
            end loop;
            
            -- Wait for the transmission to officially close
            wait until fsync = '1';
            
            -- Verify the reconstructed word matches the input data
            assert received_word = data 
                report "SPI System Error: Reconstructed word does not match sent data." 
                severity error;
        end loop;
    end process;

end sim;