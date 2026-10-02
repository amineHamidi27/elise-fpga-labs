library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;          -- pour sin() et MATH_PI (tests 3 et 4)

entity tb_fir_low is
end tb_fir_low;

architecture sim of tb_fir_low is
    component fir_low is
        generic (
            b0 : integer := 18;
            b1 : integer := 123;
            b2 : integer := 230
        );
        port (
            clk    : in  std_logic;
            enable : in  std_logic;
            x      : in  unsigned(13 downto 0);
            y      : out unsigned(13 downto 0)
        );
    end component;

    constant T : time := 64 ns;
    signal clk     : std_logic := '0';
    signal enable  : std_logic := '1';
    signal x, y    : unsigned(13 downto 0) := (others => '0');
    signal sim_end : boolean := false;

begin
    uut: fir_low
        port map (clk => clk, enable => enable, x => x, y => y);


    -- même horloge que dans le projet 1
    clk_proc: process
    begin
        while not sim_end loop
            clk <= '0'; wait for T/2;
            clk <= '1'; wait for T/2;
        end loop;
        wait;
    end process;

    stim: process
    constant TS : real := 64.0e-9;
    begin
        -- Test 1 : impulsion de 512 pendant un cycle
           x <= to_unsigned(512, 14); wait for T;
           x <= to_unsigned(0, 14);   wait for 10*T;

        -- Test 2 : constante 16383 pendant ~10 cycles
            x <= to_unsigned(16383, 14); wait for 10*T;
        -- Tests 3  : sinus, un échantillon par période T
           for k in 0 to 319 loop
            x <= to_unsigned(integer(8192.0 + 8000.0*sin(2.0*MATH_PI*100.0e3*real(k)*TS)), 14);
            wait for T;
            end loop;
        -- Tests 4  : sinus, un échantillon par période T
           for k in 0 to 99 loop
            x <= to_unsigned(integer(8192.0 + 8000.0*sin(2.0*MATH_PI*500.0e3*real(k)*TS)), 14);
            wait for T;
            end loop;
        -- Tests  5 : sinus, un échantillon par période T
           for k in 0 to 39 loop
            x <= to_unsigned(integer(8192.0 + 8000.0*sin(2.0*MATH_PI*3.31e6*real(k)*TS)), 14);
            wait for T;
            end loop;
        -- Tests  6 : sinus, un échantillon par période T
           for k in 0 to 39 loop
            x <= to_unsigned(integer(8192.0 + 8000.0*sin(2.0*MATH_PI*5.0e6*real(k)*TS)), 14);
            wait for T;
            end loop;
        --   avec TS = 64.0e-9 et F = 100.0e3 (test 3) puis 5.0e6 (test 4)

        sim_end <= true;
        wait;
    end process;
end sim;
