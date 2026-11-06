-- testbench of fsm_spi (alone: fin is given by the testbench)
library ieee;
use ieee.std_logic_1164.all;

entity tb_fsm_spi is
end tb_fsm_spi;

architecture sim of tb_fsm_spi is
    constant T : time := 8 ns;
    signal clk    : std_logic := '0';
    signal button : std_logic := '0';
    signal fin    : std_logic := '0';
    signal fsync, enable : std_logic;
begin

    uut : entity work.fsm_spi
        port map (clk => clk, button => button, fin => fin,
                  fsync => fsync, enable => enable);

    process
    begin
        clk <= '0'; wait for T/2;
        clk <= '1'; wait for T/2;
    end process;

    process
    begin
        -- Initial wait
        wait for 2 * T;

        -- press the button
        button <= '1';
        wait for 4 * T; 
        
        -- fin arrives while the button is still pressed
        -- We assert 'fin' while leaving 'button' high to test the WAIT_RELEASE logic
        fin <= '1';
        wait for T;
        fin <= '0';
        
        -- Observe the WAIT_RELEASE state (button is still pressed)
        wait for 4 * T; 

        -- release the button: return to IDLE
        button <= '0';
        
        -- Observe the return to IDLE state
        wait for 4 * T; 
        
        -- Optional: Test the scenario where the button is released BEFORE fin arrives
        button <= '1';
        wait for 2 * T;
        button <= '0'; -- Release early
        
        wait for 4 * T;
        fin <= '1';
        wait for T;
        fin <= '0';

        wait;
    end process;

end sim;
