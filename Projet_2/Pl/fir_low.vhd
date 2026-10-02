--b=[0.03494, 0.24069, 0.44874, 0.24069, 0.03494]  *512
--b=[18         ,    123,     230,     123,     18 ]


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fir_low is 
    generic (
        b0 : integer :=18;
        b1 : integer :=123;
        b2 : integer :=230
    );
    port (
        clk : IN STD_LOGIC;
        enable : in STD_LOGIC;
        x : in  unsigned(13 downto 0);
        y : out  unsigned(13 downto 0)
    );
end entity;

architecture behav of fir_low is 
-- conversion integer to unsigned 
 constant b0_uns : unsigned(7 downto 0 ) := to_unsigned(b0,8);
 constant b1_uns : unsigned(7 downto 0 ) := to_unsigned(b1,8);
 constant b2_uns : unsigned(7 downto 0 ) := to_unsigned(b2,8);

--signals 
signal x0, x1,x2,x3,x4 : unsigned (13 downto 0) := (others=> '0'); 
-- product of delay and coef
signal p0, p1,p2 : unsigned (22 downto 0) := (others=> '0'); -- 14 *8 bits
-- sommes 
signal s04 : unsigned( 14 downto 0) := (others => '0');
signal s13 : unsigned( 14 downto 0) := (others => '0');
signal s2 : unsigned( 14 downto 0) := (others => '0');
signal sum : unsigned( 22 downto 0) := (others => '0');
begin 
    s04 <= resize(x0, 15) + resize(x4, 15);
    s13 <= resize(x1, 15) + resize(x3, 15);
process(clk , enable )
    begin 
    if rising_edge(clk) then 
        if enable  = '1' then 
        x0 <= unsigned(x);
        x1 <= x0;
        x2 <=x1;
        x3 <=x2;
        x4 <=x3;

        p0 <= s04 * b0_uns;
        p1 <= s13 * b1_uns;
        p2 <= resize(x2 * b2_uns, 23);

      sum <= resize(p0, 23) + resize(p1, 23) + resize(p2, 23);
       y <= sum(22 downto 9);
     end if;
    end if;
end process;
end behav;