library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_fir is
end tb_fir;

architecture Behavioral of tb_fir is

    component myfiltre_passband is
        port (
            aclk_0               : in  std_logic;
            m_axis_data_tdata_0  : out std_logic_vector(23 downto 0);
            m_axis_data_tvalid_0 : out std_logic;
            s_axis_data_tdata_0  : in  std_logic_vector(15 downto 0);
            s_axis_data_tready_0 : out std_logic
        );
    end component;

    constant fs : real := 15.625e6;  -- fréquence d'échantillonnage (Hz)
    constant A  : real := 4000.0;    -- amplitude des sinus (< 8191)

    signal clk        : std_logic := '0';
    signal data_in    : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out   : std_logic_vector(23 downto 0);
    signal data_valid : std_logic;
    signal data_ready : std_logic;

    -- Copies signées, pour l'affichage analogique dans le chronogramme.
    signal x : signed(15 downto 0);
    signal y : signed(23 downto 0);

begin

    -- 15,625 MHz : période de 64 ns
    clk <= not clk after 32 ns;

    x <= signed(data_in);
    y <= signed(data_out);

    dut : myfiltre_passband
        port map (
            aclk_0               => clk,
            m_axis_data_tdata_0  => data_out,
            m_axis_data_tvalid_0 => data_valid,
            s_axis_data_tdata_0  => data_in,
            s_axis_data_tready_0 => data_ready
        );

    stimulus : process
        -- Envoie n échantillons d'un sinus de fréquence f.
        procedure sinus(f : real; n : natural) is
        begin
            for k in 0 to n - 1 loop
                data_in <= std_logic_vector(to_signed(
                    integer(round(A * sin(2.0 * MATH_PI * f * real(k) / fs))), 16));
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        -- Attend que le FIR puisse accepter des données.
        wait until rising_edge(clk);
        while data_ready /= '1' loop
            wait until rising_edge(clk);
        end loop;

        -- 1) Réponse impulsionnelle : 8191 pendant un échantillon.
        -- Après la latence (22 coups d'horloge), la sortie doit valoir
        -- 8191 * coefficient entier (2, 4, 4, -2, -11, ..., 67, ..., 2).
        data_in <= std_logic_vector(to_signed(8191, 16));
        wait until rising_edge(clk);
        data_in <= (others => '0');
        wait for 5 us;

        -- 2) Réponse à des sinus (1000 échantillons = 64 us chacun).
        -- Gain attendu (coefficients entiers, x512) :
        --   0,5 MHz  (bande coupée) : ~3    -> |y| ~ 14 000
        --   2,25 MHz (bande passante) : ~512 -> |y| ~ 2 000 000
        --   5 MHz    (bande coupée) : ~0,1  -> |y| ~ 400
        sinus(0.5e6, 1000);
        sinus(2.25e6, 1000);
        sinus(5.0e6, 1000);
        data_in <= (others => '0');

        wait for 5 us;
        report "Fin du test";
        wait;
    end process;

end Behavioral;
