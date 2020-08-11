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
                addr_a	: in natural range 0 to 15;
                addr_b	: in natural range 16 to 31;
                --q_a		: out std_logic_vector(7 downto 0);
                q_b		: out std_logic_vector(7 downto 0);
                read_data : in std_logic;
                compute : in std_logic
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
    
    signal write_ram_b : std_logic_vector(7 downto 0);
    signal read_ram_a, read_ram_b : std_logic_vector(7 downto 0);
    signal fir_input, fir_output : std_logic_vector(7 downto 0);
    signal we_a, we_b : std_logic;
    
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
        addr_a    => addr_a    ,
        addr_b    => addr_b    ,
        we_a      => we_a      ,
        we_b      => we_b      ,
        clk       => t_clk       ,
        q_a       => read_ram_a       ,
        q_b       => q_b      ,
        rst_dpr   => t_rstb  
   );
   
   
    p_reg : process(t_clk, t_rstb) is --Current State Register
    begin
        if t_rstb = '1' then --Rest to "idle" state if reset button is pressed
            state_curr <= s_idle;
        elsif rising_edge(t_clk) then --Otherwise move to next state
            state_curr <= state_next;
        end if;
    end process;
    
    p_cmb : process(state_curr) is --State Logic
    begin            
        case state_curr is
            when s_idle => --Idle state: do nothing
                we_a <= '0';
                we_b <= '0';
                
                state_next <= s_idle;
                if read_data = '1' then
                    state_next <= s_io;
                end if;
                
            when s_io => --Input/Output state: write from file to RAM A + read from RAM B to file
                we_a <= '1';
                we_b <= '0';
                
                state_next <= s_io;
                
                if compute = '1' then
                    state_next <= s_fir;
                elsif read_data = '0' then
                    state_next <= s_idle; --if both read_data and compute are '0' 
                end if;
                       
            when s_fir => --FIR State: compute the filter, read from RAM A and write to RAM B
                we_a <= '0';
                we_b <= '1';
                
                fir_input <= read_ram_a;
                write_ram_b <= fir_output;
                
                if compute = '0' then 
                    if read_data = '1' then
                        state_next <= s_io;
                    else
                        state_next <= s_idle; --Discard last block of data
                    end if;
                end if;
            
            when others =>
                state_next <= s_idle;
            
            end case;
    end process;
    

end architecture rtl;