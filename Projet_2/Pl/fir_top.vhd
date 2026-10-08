library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fir_top is
    Port (
        -- adc_clk_p_i, adc_clk_n_i, led_o, adc_dat_a_i, adc_dat_b_i,
        adc_clk_p_i, adc_clk_n_i : in STD_LOGIC;
	    led_o : buffer STD_LOGIC_VECTOR (7 downto 0);
    	adc_dat_a_i : in std_logic_vector(13 downto 0);
    	adc_dat_b_i : in std_logic_vector(13 downto 0);
        -- dac_clk_o, dac_rst_o, dac_sel_o, dac_wrt_o, dac_dat_o
        dac_clk_o : out std_logic;
        dac_rst_o : out std_logic;
        dac_sel_o : out std_logic;
        dac_wrt_o : out std_logic;
        dac_dat_o : out std_logic_vector(13 downto 0)
    );
end fir_top;

architecture a of fir_top is
    -- signaux de ADC_DAC.vhd : div, clk125, clk_nobuf_s, aclk, dat_a_reg, dat_b_reg
	signal div : integer range 0 to 7;
	signal clk125, clk_nobuf_s : std_logic;
	signal aclk : std_logic;
	signal dat_a_reg,dat_b_reg : std_logic_vector(13 downto 0);
    -- signaux du filtre :

    -- fir_x, fir_y : unsigned(13 downto 0)
        signal fir_x, fir_y : unsigned(13 downto 0);

    component IBUFDS is
		port(I, IB: IN std_logic;
			O : OUT std_logic);
	end component;
	component BUFG is
		port(I: IN std_logic;
			O : OUT std_logic);
	end component;

    -- component fir_low (copié de tb_fir_low.vhd)
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


begin
    -- 1) horloge : IBUFDS + BUFG (copiés de ADC_DAC.vhd)
    clk_inst0: IBUFDS PORT MAP(I=>adc_clk_p_i,IB =>adc_clk_n_i,O =>clk_nobuf_s);
    clk_inst: BUFG  PORT MAP(I=>clk_nobuf_s, O=>clk125);
    -- 2) filtre
    fir_x <= unsigned(dat_a_reg);
    inst_fir: fir_low port map (clk => clk125, enable => aclk, x => fir_x, y => fir_y);


    -- 3) process du compteur (copié de ADC_DAC.vhd)
 process
      begin
          wait until rising_edge (clk125);
              CASE div is
              WHEN 0 =>
              	div <= 1;
				aclk <='0';
				dac_wrt_o <= '0'; 
				dac_clk_o <= '0';
				dac_sel_o <= '1';
				dac_dat_o <= dat_b_reg;
              WHEN 1 =>
              	div <= 2;
				aclk <='1';
				dac_wrt_o <= '1'; 
				dac_clk_o <= '1';
				dac_sel_o <= '1';
				dac_dat_o <= dat_b_reg;
              WHEN 2 =>
              	div <= 3;
				aclk <='0';
				dac_wrt_o <= '1'; 
				dac_clk_o <= '1';
				dac_sel_o <= '1';
				dac_dat_o <= dat_b_reg;
              WHEN 3 =>
              	div <= 4;
				aclk <='0';
				dac_wrt_o <= '0'; 
				dac_clk_o <= '0';
				dac_sel_o <= '1';
				dac_dat_o <= dat_b_reg;	
              WHEN 4 =>
              	div <= 5;
				aclk <='0';
				dac_wrt_o <= '0'; 
				dac_clk_o <= '0';
				dac_sel_o <= '0';
				dac_dat_o <= std_logic_vector(fir_y);
              WHEN 5 =>
              	div <= 6;
				aclk <='0';
				dac_wrt_o <= '1'; 
				dac_clk_o <= '1';
				dac_sel_o <= '0';
				dac_dat_o <= std_logic_vector(fir_y);
              WHEN 6 =>
              	div <= 7;
				aclk <='0';
				dac_wrt_o <= '1'; 
				dac_clk_o <= '1';
				dac_sel_o <= '0';
				dac_dat_o <= std_logic_vector(fir_y);
              WHEN OTHERS =>
              	div <= 0;
				aclk <='0';
				dac_wrt_o <= '0'; 
				dac_clk_o <= '0';
				dac_sel_o <= '0';
				dac_dat_o <= std_logic_vector(fir_y);
			END CASE;
			
			if (aclk = '1')	then	--else latch	
	      		dat_a_reg <= adc_dat_a_i ;
	      		dat_b_reg <= adc_dat_b_i ;
	      	else
	      		dat_a_reg <= dat_a_reg ;
	      		dat_b_reg <= dat_b_reg ;	      	
	      	end if;
      end process;
    -- 4) sorties fixes
        dac_rst_o <= '0';
        led_o <=adc_dat_b_i(13 downto 6);
end a;
