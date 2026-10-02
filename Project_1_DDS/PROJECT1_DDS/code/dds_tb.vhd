library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dds_tb is

end dds_tb;

architecture Behavioral of dds_tb is
    -- Component
    component DDS is
        Generic ( N : integer := 10 );
        Port (
            clk         : in  STD_LOGIC;
            W           : in  STD_LOGIC_VECTOR(N-1 downto 0);
            phase_offset: in  STD_LOGIC_VECTOR(N-1 downto 0);
            sine_out    : out STD_LOGIC_VECTOR(13 downto 0)
        );
    end component;

    -- Signals
    signal clk         : STD_LOGIC := '0';
    signal W           : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal phase_offset: STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal sine_out    : STD_LOGIC_VECTOR(13 downto 0);

    -- Clock period (125 MHz)
    constant clk_period : time := 8 ns;
    signal sim_end : boolean := false;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: DDS 
        generic map ( N => 10 )
        port map (
            clk          => clk,
            W            => W,
            phase_offset => phase_offset,
            sine_out     => sine_out
        );

    -- Clock process definitions
    clk_process : process
    begin
        while not sim_end loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        wait for 100 ns;

        -- Test 0: W = 1 -> one full phase cycle (1024 steps)
        W            <= std_logic_vector(to_unsigned(1, 10));
        phase_offset <= std_logic_vector(to_unsigned(0, 10));
        wait for 1050 * clk_period;

        -- Test 1: Small W 
        W <= std_logic_vector(to_unsigned(4, 10));
        wait for 5 us;

        -- Test 2: Higher W 
        W <= std_logic_vector(to_unsigned(32, 10));
        wait for 5 us;

        -- Test 3: Add an offset (180 degrees)
        phase_offset <= std_logic_vector(to_unsigned(512, 10));
        wait for 5 us;

        -- Test 4a: W = 512 = 2^9 (exact Nyquist limit)
        -- f_out = 125 MHz * 512 / 1024 = 62.5 MHz
        phase_offset <= std_logic_vector(to_unsigned(0, 10));
        W <= std_logic_vector(to_unsigned(512, 10));
        wait for 2 us;

        -- Test 4b: W = 513 > 2^9 (Nyquist violated -> aliasing)
        W <= std_logic_vector(to_unsigned(513, 10));
        wait for 2 us;

        sim_end <= true;
        wait;
    end process;
end Behavioral;
