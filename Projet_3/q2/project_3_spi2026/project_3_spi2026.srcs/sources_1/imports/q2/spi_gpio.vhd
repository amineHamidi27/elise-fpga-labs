library ieee;
use ieee.std_logic_1164.all;

entity spi_gpio is
    generic (
        tscale : integer := 20;   -- clk = 125 MHz (clk_out1) -> SCLK = 6.25 MHz
        N      : integer := 16
    );
    port (
        clk       : in  std_logic;                        -- clk_out1 of the clock wizard
        word      : in  std_logic_vector(15 downto 0);    -- GPIO channel 1: word to send
        ctrl      : in  std_logic_vector(9 downto 0);     -- GPIO channel 2: bit 0 = send
        sdata     : out std_logic;                        -- to the DDS (E1 pins)
        sclk      : out std_logic;
        fsync     : out std_logic;
        dds_reset : out std_logic
    );
end spi_gpio;

architecture rtl of spi_gpio is
    signal enable, fin : std_logic;
begin

    --instance of fsm_spi
    inst_fsm_spi : entity work.fsm_spi
        port map (
            clk => clk,
            button => ctrl(0),
            fin => fin,
            fsync => fsync,
            enable => enable

        );
    -- nstance of spi_tx 
    inst_spi_tx : entity work.spi_tx
        generic map (
            tscale => tscale,
            N      => N
        )
        port map (
            clk    => clk,
            enable => enable,
            data   => word,
            sclk   => sclk,
            sdata  => sdata,
            fin    => fin
        );
    --  dds_reset fixed at '0'
        dds_reset <='0';
end rtl;
