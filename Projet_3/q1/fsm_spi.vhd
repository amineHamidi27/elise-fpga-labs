-- entity 2: Moore machine, manages FSYNC and the enable of spi_tx
library ieee;
use ieee.std_logic_1164.all;

entity fsm_spi is
    port (
        clk    : in  std_logic;
        button : in  std_logic;    -- '1' when pressed
        fin    : in  std_logic;    -- from spi_tx
        fsync  : out std_logic;    -- SS/ of the DDS, active at '0'
        enable : out std_logic     -- to spi_tx
    );
end fsm_spi;

architecture rtl of fsm_spi is
    -- states of the diagram
    type state_t is (IDLE, START_SYNC, SENDING, WAIT_RELEASE);
    signal state : state_t := IDLE;
begin

    -- next state (on the clock edge)
    process
    begin
        wait until rising_edge(clk);
        case state is
            when IDLE =>
                -- Transition when the button is pressed
                if button = '1' then
                    state <= START_SYNC;
                end if;
                
            when START_SYNC =>
                -- FSYNC goes to 0 for 1 FPGA clock period before enabling SPI
                state <= SENDING;
                
            when SENDING =>
                -- Wait until the N bits are sent
                if fin = '1' then
                    state <= WAIT_RELEASE;
                end if;
                
            when WAIT_RELEASE =>
                -- Wait for the button to be released to avoid sending multiple times
                if button = '0' then
                    state <= IDLE;
                end if;
                
            when others =>
                state <= IDLE;
        end case;
    end process;

    -- outputs: depend only on the state (Moore)
    fsync  <= '0' when (state = START_SYNC or state = SENDING) else '1';
    enable <= '1' when state = SENDING else '0';

end rtl;
