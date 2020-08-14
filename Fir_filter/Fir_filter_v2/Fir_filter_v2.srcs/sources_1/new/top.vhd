library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    Port ( 
                clk    : in  std_logic;
                rstb   : in  std_logic;
                i_coeff_0 : in  std_logic_vector(7 downto 0);
                i_coeff_1 : in  std_logic_vector(7 downto 0);
                i_coeff_2 : in  std_logic_vector(7 downto 0);
                i_coeff_3 : in  std_logic_vector(7 downto 0);
                addr_a : in std_logic_vector(9 downto 0);
                we_a : in std_logic;
                write_a : in std_logic_vector(7 downto 0);
                read_a : out std_logic_vector(7 downto 0);
                n_state : out natural range 0 to 3
            );
end top;

architecture Behavioral of top is

constant ADDR_WIDTH : integer := 10;

component dpram
    generic(
      ADDR_WIDTH : natural
      );
    port(
		data_a	: in std_logic_vector(7 downto 0); 
		data_b	: in std_logic_vector(7 downto 0);
		addr_a : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		addr_b	: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		we_a	: in std_logic := '1'; 
		we_b	: in std_logic := '1';
		clk		: in std_logic;
		q_a		: out std_logic_vector(7 downto 0);
		q_b		: out std_logic_vector(7 downto 0);
		rst_dpr : in std_logic
      );
end component;

component fir_filter_4 is
  port (
    i_clk     : in  std_logic;
    i_rstb    : in  std_logic;
    i_coeff_0 : in  std_logic_vector(7 downto 0);
    i_coeff_1 : in  std_logic_vector(7 downto 0);
    i_coeff_2 : in  std_logic_vector(7 downto 0);
    i_coeff_3 : in  std_logic_vector(7 downto 0);
    i_data    : in  std_logic_vector(7 downto 0);
    o_data    : out std_logic_vector(7 downto 0);
    we_fir : in std_logic
    );
end component; 

signal addr_b : std_logic_vector(ADDR_WIDTH - 1 downto 0);
signal fir_input, fir_output, read_b, write_b : std_logic_vector(7 downto 0);
signal we_b : std_logic;
type state is (s_idle, s_load, s_read, s_write); --States for the FSM

constant HALF_RAM : natural := 2 ** (ADDR_WIDTH - 1) - 1;
signal counter : integer := 0;--std_logic_vector(ADDR_WIDTH - 2 downto 0);
    
signal state_curr, state_next : state;
signal we_fir : std_logic;

begin
dpr : dpram
    generic map(ADDR_WIDTH => ADDR_WIDTH)
    port map(
		data_a	=> write_a, 
		data_b	=> write_b,
		addr_a => addr_a,
		addr_b	=> addr_b,
		we_a	=> we_a,
		we_b	=> we_b,
		clk		=> clk,
		q_a		=> read_a,
		q_b		=> read_b,
		rst_dpr => rstb
     ); 
     
fir : fir_filter_4 
    port map(
        i_clk     => clk,
        i_rstb    => rstb,
        i_coeff_0 => i_coeff_0,
        i_coeff_1 => i_coeff_1,
        i_coeff_2 => i_coeff_2,
        i_coeff_3 => i_coeff_3,
        i_data     => fir_input,
        o_data   => fir_output,
        we_fir => we_fir
    );

    p_reg : process(clk, rstb) is --Current State Register
    begin
        if rstb = '1' then --Rest to "idle" state if reset button is pressed
            state_curr <= s_idle;
        elsif rising_edge(clk) then --Otherwise move to next state
            state_curr <= state_next;
        end if;
    end process;
    
    p_cmb : process(state_curr, we_a, clk) is
    begin
        case state_curr is
            when s_idle => 
                n_state <= 0;
                --counter <= 0; --(others => '0');
                
                we_fir <= '0';
                
                if we_a = '1' then
                    state_next <= s_load;
                end if;
                

            when s_load =>
                n_state <= 1;
                
                if we_a = '0' then
                    state_next <= s_read;
                end if;
                
                fir_input <= (others => '0');
            
            when s_read =>
                n_state <= 2;
                
                we_b <= '0';
                we_fir <= '1';
                
                addr_b <= std_logic_vector(to_unsigned(counter, addr_b'length));
                
                --addr_b(0) <= '0'; --Read from first half of RAM
                --addr_b(ADDR_WIDTH - 1 downto 1) <= counter;
                
                --fir_input <= read_b; --std_logic_vector(to_unsigned(counter, fir_input'length))
                
                state_next <= s_write;
                
            when s_write =>
                n_state <= 3;
                
                fir_input <= read_b;
                
                we_b <= '1';
                we_fir <= '0';
                
                addr_b <= std_logic_vector(to_unsigned(counter + HALF_RAM, addr_b'length));
                
                
                
                write_b <= fir_output;

                
                if counter /= HALF_RAM - 1 then
                    state_next <= s_read;
                else
                    state_next <= s_idle; 
                end if;
                
            when others =>
                state_next <= s_idle;
            
            end case;
    end process;
    
    p_counter : process(state_curr, clk) is
    begin
        if state_curr = s_write and rising_edge(clk) then
            if counter /= HALF_RAM then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;
        end if;
    end process;
    
end Behavioral;
