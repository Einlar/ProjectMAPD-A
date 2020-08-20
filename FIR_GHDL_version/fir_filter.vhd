library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter_4 is
  generic(
    N_TAPS     : natural;
    DATA_WIDTH : natural
	);
  port (
    i_clk     : in  std_logic;
    i_rstb    : in  std_logic;
    we_fir : in std_logic;
    load:    in std_logic := '0';
    i_coeff : in  std_logic_vector (DATA_WIDTH -1 downto 0);
    i_data    : in  std_logic_vector(DATA_WIDTH -1 downto 0);
    o_data    : out std_logic_vector(DATA_WIDTH -1 downto 0));
end fir_filter_4;

architecture rtl of fir_filter_4 is

  type t_data_pipe is array (0 to N_TAPS-1) of signed(DATA_WIDTH -1 downto 0); --Matrix N_TAPSx8
  type t_coeff is array (0 to N_TAPS-1) of signed(DATA_WIDTH -1 downto 0); --Matrix N_TAPSx8

  type t_mult is array (0 to N_TAPS-1) of signed(2*DATA_WIDTH-1 downto 0); --Matrix 4x16
  type t_add_st0 is array (0 to N_TAPS/2 -1) of signed(2*DATA_WIDTH downto 0); --Matrix 2x17

  signal r_coeff   : t_coeff; --Matrix 4x8
  signal p_data    : t_data_pipe; --Matrix 4x8
  signal r_mult    : t_mult; --Matrix 4x16
  signal r_add_st0 : t_add_st0; --Matrix 2x17
  signal r_add_st1 : signed(2*DATA_WIDTH+1 downto 0); --Vector 18

begin

  p_input : process (i_rstb, i_clk)
  begin
    if(i_rstb = '1') then --Reset all signals
      p_data  <= (others => (others => '0'));
      r_coeff <= (others => (others => '0'));
    elsif(rising_edge(i_clk) and we_fir = '1') then --Insert new byte at the beginning, shift the other 3 --RE 1
      p_data     <= signed(i_data)&p_data(0 to p_data'length-2);
      if load = '1' then
        r_coeff <= signed(i_coeff)&r_coeff(0 to r_coeff'length-2);
      end if;
    end if;
  end process p_input;

  p_mult : process (i_rstb, i_clk) --Multiply the bytes with the coefficients
  begin
    if(i_rstb = '1') then
      r_mult <= (others => (others => '0'));
    elsif(rising_edge(i_clk)) then 
      for k in 0 to N_TAPS-1 loop
        r_mult(k) <= p_data(k) * r_coeff(k);
      end loop;
    end if;
  end process p_mult;

  p_add_st0 : process (i_rstb, i_clk) --Reduction first step
  begin
    if(i_rstb = '1') then
      r_add_st0 <= (others => (others => '0'));
    elsif(rising_edge(i_clk)) then
      for k in 0 to N_TAPS/2-1 loop
        r_add_st0(k) <= resize(r_mult(2*k), 2*DATA_WIDTH+1) + resize(r_mult(2*k+1), 2*DATA_WIDTH+1);
      end loop;
    end if;
  end process p_add_st0;

  p_add_st1 : process (i_rstb, i_clk) --Reduction second step
  variable tmp: signed(2*DATA_WIDTH+1 downto 0):= (others => '0');
  begin
    tmp := (others => '0');
    if(i_rstb = '1') then
      r_add_st1 <= (others => '0');
    elsif(rising_edge(i_clk)) then 
      for k in 0 to N_TAPS/2-1 loop
        tmp := tmp + resize(r_add_st0(k), 2*DATA_WIDTH+2);
      end loop;
      r_add_st1 <= tmp;
    end if;
  end process p_add_st1;

  p_output : process (i_rstb, i_clk) --Compute output
  begin
    if(i_rstb = '1') then
      o_data <= (others => '0');
    elsif(rising_edge(i_clk)) then 
      o_data <= std_logic_vector(r_add_st1(DATA_WIDTH-1 downto 0)); 
    end if;
  end process p_output;
end rtl;