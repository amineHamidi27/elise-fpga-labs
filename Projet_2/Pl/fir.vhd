--b=[0.03494, 0.24069, 0.44874, 0.24069, 0.03494]  *512
--b=[18         ,    123,     230,     123,     18 ]


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fir is 
    generic (
        b0 : integer :=18;
        b1 : integer :=123;
        b2 : integer :=230;
        b3 : integer :=123;
        b4 : integer :=18
    );
    port (
        clk : IN STD_LOGIC;
        enable : in STD_LOGIC;
        x : in  unsigned(13 downto 0);
        y : out  unsigned(13 downto 0)
    );
end entity;

architecture behav of fir is 
-- conversion integer to unsigned 
 constant b0_uns : unsigned(7 downto 0 ) := to_unsigned(b0,8);
 constant b1_uns : unsigned(7 downto 0 ) := to_unsigned(b1,8);
 constant b2_uns : unsigned(7 downto 0 ) := to_unsigned(b2,8);
 constant b3_uns : unsigned(7 downto 0 ) := to_unsigned(b3,8);
 constant b4_uns : unsigned(7 downto 0 ) := to_unsigned(b4,8);

--signals 
signal x0, x1,x2,x3,x4 : unsigned (13 downto 0) := (others=> '0'); 
-- product of delay and coef
signal p0, p1,p2,p3,p4 : unsigned (21 downto 0) := (others=> '0'); -- 14 +8 bits
-- sommes 
signal sum : unsigned( 22 downto 0) := (others => '0');
begin 
process(clk , enable )
    begin 
    if rising_edge(clk) then 
        if enable  = '1' then 
        x0 <= x;
        x1 <= x0;
        x2 <=x1;
        x3 <=x2;
        x4 <=x3;

        p0 <= x0 * b0_uns;
        p1 <= x1 * b1_uns;
        p2 <= x2 * b2_uns;
        p3 <= x3 * b3_uns;
        p4 <= x4 * b4_uns;

      sum <= resize(p0, 23) + resize(p1, 23) + resize(p2, 23) + resize(p3, 23) + resize(p4, 23);
       y <= sum(22 downto 9);
     end if;
    end if;
end process;
end behav;