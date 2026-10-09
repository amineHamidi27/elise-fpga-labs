library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Réponse impulsionnelle (Dirac) du passe-bande FIR Compiler.
-- 1) Dirac de 1    : la sortie donne directement les 31 coefficients entiers
--                    (round(b*512)) : 2, 4, 4, -2, -11, ..., 67, ..., 4, 4, 2
-- 2) Dirac de 8191 : même forme, multipliée par 8191 (plus visible en analogique)
-- Latence du FIR : 22 coups d'horloge. Durée à simuler : run 15 us

entity tb_fir_dirac is
end tb_fir_dirac;

architecture Behavioral of tb_fir_dirac is

    component myfiltre_passband is
        port (
            aclk_0               : in  std_logic;
            m_axis_data_tdata_0  : out std_logic_vector(23 downto 0);
            m_axis_data_tvalid_0 : out std_logic;
            s_axis_data_tdata_0  : in  std_logic_vector(15 downto 0);
            s_axis_data_tready_0 : out std_logic
        );
    end component;

    signal clk        : std_logic := '0';
    signal data_in    : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out   : std_logic_vector(23 downto 0);
    signal data_valid : std_logic;
    signal data_ready : std_logic;

    -- Copies signées, pour l'affichage dans le chronogramme.
    signal x : signed(15 downto 0);
    signal y : signed(23 downto 0);
    -- Numéro de l'échantillon de sortie depuis le Dirac (0 à 30 = coefficients).
    signal n : integer := -1;

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
        -- Envoie un Dirac d'amplitude a, puis 60 zéros.
        procedure dirac(a : integer) is
        begin
            data_in <= std_logic_vector(to_signed(a, 16));
            wait until rising_edge(clk);
            data_in <= (others => '0');
            for k in 1 to 60 loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        -- Attend que le FIR puisse accepter des données.
        wait until rising_edge(clk);
        while data_ready /= '1' loop
            wait until rising_edge(clk);
        end loop;

        dirac(1);
        dirac(8191);

        report "Fin du test";
        wait;
    end process;

    -- Affiche dans la console les 31 sorties qui suivent chaque Dirac
    -- (non nulles), c'est-à-dire les coefficients.
    observe : process(clk)
    begin
        if rising_edge(clk) and data_valid = '1' then
            if to_integer(y) /= 0 and n < 0 then
                n <= 1;
                report "coef 0 = " & integer'image(to_integer(y));
            elsif n >= 1 and n <= 30 then
                n <= n + 1;
                report "coef " & integer'image(n) & " = " & integer'image(to_integer(y));
            elsif n > 30 then
                n <= -1;
            end if;
        end if;
    end process;

end Behavioral;
