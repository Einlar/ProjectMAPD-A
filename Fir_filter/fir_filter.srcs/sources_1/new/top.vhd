----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.08.2020 15:22:02
-- Design Name: 
-- Module Name: top - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
    Port ( 
                t_clk     : in  std_logic;
                t_rstb    : in  std_logic;
                i_coeff_0 : in  std_logic_vector(7 downto 0);
                i_coeff_1 : in  std_logic_vector(7 downto 0);
                i_coeff_2 : in  std_logic_vector(7 downto 0);
                i_coeff_3 : in  std_logic_vector(7 downto 0);
                -- data input
                --i_data    : in  std_logic_vector(7 downto 0);
                -- filtered data 
                --o_data    : out std_logic_vector(7 downto 0);
                data_a	: in std_logic_vector(7 downto 0);
                --data_b	: in std_logic_vector(7 downto 0);
                --addr_a	: in natural range 0 to 15;
                --addr_b	: in natural range 16 to 31;
                --q_a		: out std_logic_vector(7 downto 0);
                q_b		: out std_logic_vector(7 downto 0);
                read_data : in std_logic;
                compute : in std_logic;
                n_state : out natural range 0 to 2;
                rrama : out std_logic_vector(7 downto 0);
                rramb : out std_logic_vector(7 downto 0);
                wramb : out std_logic_vector(7 downto 0);
                busy : out std_logic;
                p_addra : out natural range 0 to 15;
                p_addrb : out natural range 16 to 31;
                p_counter : out natural range 0 to 16
            );
end top;

architecture rtl of top is
    component fir_filter_4
      port (
            i_clk     : in  std_logic;
            i_rstb    : in  std_logic;
            -- coefficient
            i_coeff_0 : in  std_logic_vector(7 downto 0);
            i_coeff_1 : in  std_logic_vector(7 downto 0);
            i_coeff_2 : in  std_logic_vector(7 downto 0);
            i_coeff_3 : in  std_logic_vector(7 downto 0);
            -- data input
            i_data    : in  std_logic_vector(7 downto 0);
            -- filtered data 
            o_data   : out std_logic_vector(7 downto 0)
        );
    end component; --fir_filter_4;
    
    component dpram
	port 
	(	
		data_a	: in std_logic_vector(7 downto 0);
		data_b	: in std_logic_vector(7 downto 0);
		addr_a	: in natural range 0 to 15;
		addr_b	: in natural range 16 to 31;
		we_a	: in std_logic := '1';
		we_b	: in std_logic := '1';
		clk		: in std_logic;
		q_a		: out std_logic_vector(7 downto 0);
		q_b		: out std_logic_vector(7 downto 0);
		rst_dpr : in std_logic
	 );
    end component; --dpram
    
    type state is (s_idle, s_io, s_fir); --States for the FSM
    
    signal state_curr, state_next : state;
    
    constant RAM_SIZE : natural := 16;
    signal write_ram_b : std_logic_vector(7 downto 0);
    signal read_ram_a, read_ram_b : std_logic_vector(7 downto 0);
    signal addra : natural range 0 to RAM_SIZE-1;
    signal addrb : natural range RAM_SIZE to 2 * RAM_SIZE - 1;
    signal fir_input, fir_output : std_logic_vector(7 downto 0);
    signal we_a, we_b : std_logic;
    signal counter : natural range 0 to 2 * RAM_SIZE;
    signal rst_counter : std_logic := '0';
    
begin
   fir : fir_filter_4 port map (
        i_clk     => t_clk     ,
        i_rstb    => t_rstb    ,
        i_coeff_0 => i_coeff_0 ,
        i_coeff_1 => i_coeff_1 ,
        i_coeff_2 => i_coeff_2 ,
        i_coeff_3 => i_coeff_3,
        i_data    => fir_input   ,
        o_data    => fir_output  
   );
   
   uut : dpram port map (
        data_a    => data_a    ,
        data_b    => write_ram_b    ,
        addr_a    => addra    ,
        addr_b    => addrb    ,
        we_a      => we_a      ,
        we_b      => we_b      ,
        clk       => t_clk       ,
        q_a       => read_ram_a       ,
        q_b       => q_b      ,
        rst_dpr   => t_rstb  
   );
   
   rrama <= read_ram_a;
   rramb <= read_ram_b;
   wramb <= write_ram_b;
   p_addra <= addra;
   p_addrb <= addrb;
   p_counter <= counter;
   
    p_reg : process(t_clk, t_rstb) is --Current State Register
    begin

        if t_rstb = '1' then --Rest to "idle" state if reset button is pressed
            state_curr <= s_idle;
        elsif rising_edge(t_clk) then --Otherwise move to next state
            state_curr <= state_next;
        end if;
    end process;
    
    p_cmb : process(state_curr, read_data, compute, t_clk) is --State Logic
    begin            
        case state_curr is
            when s_idle => --Idle state: do nothing
                n_state <= 0;
                
                we_a <= '0';
                we_b <= '0';
                
                counter <= 0;
                busy <= '0';
                
                state_next <= s_idle;
                
                if read_data = '1' then
                    addra <= 0;
                    addrb <= RAM_SIZE;
                    state_next <= s_io;
                end if;
                
            when s_io => --Input/Output state: write from file to RAM A + read from RAM B to file
                n_state <= 1;
                
                we_a <= '1';
                we_b <= '0';
                
                --busy <= '0';
                
                if rising_edge(t_clk) then
                    if addra /= RAM_SIZE - 1 then -- /= means "not equal to"
                        addra <= addra + 1;
                        addrb <= addrb + 1;
                    end if;
                end if;
               
                if rising_edge(t_clk) and addra = RAM_SIZE - 2 then
                    busy <= '1';
                    state_next <= s_fir;
                    rst_counter <= '1';
                end if;     
                       
            when s_fir => --FIR State: compute the filter, read from RAM A and write to RAM B
                n_state <= 2;
                
                we_a <= '0';
                we_b <= '1';
                
                if rst_counter = '1' then
                    addra <= 0;
                    addrb <= RAM_SIZE;
                    rst_counter <= '0';
                end if;
    
                if rising_edge(t_clk) then
                    if counter /= 2 * RAM_SIZE - 1 then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                    end if;
                    
                    if (counter mod 2) = 0 then
                        fir_input <= read_ram_a;
                    else
                        write_ram_b <= fir_output;
                        if addra /= RAM_SIZE - 1 then -- /= means "not equal to"
                            addra <= addra + 1;
                            addrb <= addrb + 1;
                        else
                            addra <= 0;
                            addrb <= RAM_SIZE;
                        end if;
                    end if;
                   
                end if;
                

               

               
                                
                --fir_input <= read_ram_a;
                --write_ram_b <= fir_output;
            
            when others =>
                state_next <= s_idle;
            
            end case;
    end process;
    

end architecture rtl;
