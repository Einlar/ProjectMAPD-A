----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.01.2020 15:37:39
-- Design Name: 
-- Module Name: counter - rtl
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter is
    port( clk   : in std_logic; -- internal clock
          rst   : in std_logic; -- reset button
          stop  : in std_logic; -- stop button
          start : in std_logic; -- start button
          y_red : out std_logic_vector(3 downto 0); -- 4 red LEDs 
          y_blu : out std_logic_vector(3 downto 0)); -- 4 blue LEDs
end counter;

architecture rtl of counter is
    type state_t is (reset, running, stopped); --three possible states: "running" is the active one, when the stopwatch is counting, "stopped" holds the current count indefinitely, "reset" switches off the counter and erases the current count
    signal state      : state_t; 
    signal next_state : state_t; 
    signal slow_clk, slow_clk_p: std_logic;
    signal counter      : unsigned (28 downto 0); --counts clock cycles
    signal slow_counter : unsigned (3  downto 0); --human readable counter for the stopwatch
    
begin
    p_cnt : process(clk, rst) is 
    begin
        if (state = reset) then --reset counter
            counter <= (others => '0');
        elsif (state = running and rising_edge(clk)) then 
            counter <= counter +1;
        end if;
    end process;
     
    slow_clk <= counter(1); --make it quicker for simulation
     
    p_slow_cnt: process (clk, rst, slow_clk) is 
    begin
        if (state = reset) then
            slow_counter <= (others => '0');
        elsif (state = running and rising_edge(slow_clk)) then
            --slow_clk_p <= slow_clk;
            --if (slow_clk = '1' and slow_clk_p = '0') then
              slow_counter <= slow_counter + 1;
            --end if;
        end if;
     end process;
     
    -- y_out <= std_logic_vector(slow_counter);
     
    state_update : process (rst, start, stop, state, slow_counter) is 
    begin
        case state is
            when reset =>
                y_blu <= (others => '0'); --turn off all the LEDs
                y_red <= (others => '0'); 
                next_state <= reset;      --turn off counter
                if (start = '1') then     --allow restart
                    next_state <= running;    
                end if;
            when running =>
                next_state <= running;
                y_blu <= std_logic_vector(slow_counter);
                y_red <= (others => '0');
                --if (rst = '1' )then
                --    next_state <= reset;  
                if (stop ='1') then
                    next_state <= stopped;
                end if;    
            when stopped =>
                next_state <= stopped;
                y_red <= std_logic_vector(slow_counter);
                y_blu <= (others => '0');
                --if (rst = '1') then
                --    next_state <= reset;  
                if (start = '1') then
                    next_state <= running;
                end if;
            when others => null;  --better specify unwanted cases no differences in sim but important in implementation
        end case;
    end process state_update;
    
    
    state_memory : process (clk) is
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then --syncronous reset
                state <= reset;
            else
                state <= next_state;
            end if;
         end if;
     end process state_memory;
     
end rtl;
