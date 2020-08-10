----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.01.2020 12:41:23
-- Design Name: 
-- Module Name: counter_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter_tb is
--  Port ( );
end counter_tb;

architecture Behavioral of counter_tb is
    component counter is
        Port (clk   : in std_logic; -- internal clock
              rst   : in std_logic; -- reset button
              stop  : in std_logic; -- stop button
              start : in std_logic; -- start button
              y_red : out std_logic_vector(3 downto 0); -- 4 red LEDs 
              y_blu : out std_logic_vector(3 downto 0)); -- 4 blue LEDs
    end component; --counter
    
    signal clk, rst, stop, start : std_logic;
    signal y_red : std_logic_vector(3 downto 0);
    signal y_blu : std_logic_vector(3 downto 0);
begin

    uut : counter port map (clk => clk, rst => rst, stop => stop, start => start, y_red => y_red, y_blu => y_blu); 

    p_clock : process --simulate clock
        begin
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;  
        end process; --p_clock
        
    p_start : process --press start button
        begin
            start <= '0';
            stop  <= '0';
            rst <= '1'; --initial reset
            wait for 10 ns;
            rst <= '0';
            wait for 5 ns;
            
            start <= '1'; --simulate button press of "start"
            wait for 10 ns;
            start <= '0';
            
            wait for 500 ns;
            
            stop <= '1'; --simulate button press of "stop"
            wait for 10 ns;
            stop <= '0';
            wait for 100 ns;
            
            start <= '1';
            wait for 10 ns;
            start <= '0';
            wait for 100 ns;
            
            rst <= '1';
            wait for 10 ns;
            rst <= '0';
            wait;
            
            
        end process; --p_start
end Behavioral;

