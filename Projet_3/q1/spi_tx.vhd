-- entity 1: generates SCLK (prescaler tscale) and sends N bits on SDATA, MSb first
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tx is
    generic (
        tscale : integer := 20;   -- SCLK period in clk periods (> 2)
        N      : integer := 16    -- number of bits to send
    );
    port (
        clk    : in  std_logic;
        enable : in  std_logic;                        -- '1': send, '0': reset
        data   : in  std_logic_vector(N-1 downto 0);   -- word to send
        sclk   : out std_logic;
        sdata  : out std_logic;
        fin    : out std_logic                         -- '1' when the N bits are sent
    );
end spi_tx;

architecture rtl of spi_tx is
    --  counter of the frequency divider (0 to tscale-1)
    signal count : integer  range 0 to tscale-1 := 0;  
    --  bit counter (which bit is being sent)
    signal bit_counter : integer range 0 to N-1 := N-1;
 
begin

    process
    begin
        wait until rising_edge(clk);
        if enable = '0' then
            -- reset: sclk = '1', count = 0, bit_counter = N-1, MSb ready on sdata
        sclk <= '1';
        count<= 0;
        bit_counter <= N-1;
        fin <= '0';
        sdata <=  data(N-1);
          
        else
            -- divider: SCLK falls at count = tscale/2-1 and rises at count = tscale-1,
            -- where SDATA takes the next bit (MSb first); fin = '1' after the N-th bit
        if fin = '0' then
            if count = tscale -1 then 
            count <=0;
            sclk <= '1';
            
            if bit_counter > 0 then 
                bit_counter <= bit_counter - 1;
                sdata <= data(bit_counter - 1);
            else 
            fin <= '1';
            end if;
        else
        count <= count +1;

        if count = (tscale/2)-1 then 
            sclk <= '0';
            end if;
        end if;
        end if ;

        end if;
    end process;

end rtl;
