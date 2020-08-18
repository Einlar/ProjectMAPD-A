----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.08.2020 18:22:40
-- Design Name: 
-- Module Name: tb_top - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_top is
--  Port ( );
end tb_top;

architecture Behavioral of tb_top is
constant ADDR_WIDTH : integer := 10;
constant N_TAPS : integer := 16;
constant DATA_WIDTH : integer := 32;
component top is
    Port ( 
                clk    : in  std_logic;
                rstb   : in  std_logic;
                i_coeff : in  std_logic_vector(DATA_WIDTH-1 downto 0);
                --i_coeff_1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
                --i_coeff_2 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
                --i_coeff_3 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
                addr_a : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
                we_a : in std_logic;
                write_a : in std_logic_vector(DATA_WIDTH-1 downto 0);
                read_a : out std_logic_vector(DATA_WIDTH-1 downto 0);
                n_state : out natural range 0 to 3;
                load    : in std_logic := '0'
            );
end component;
    
    signal clk : std_logic := '0';
    signal rstb, we_a : std_logic;
    
    signal i_coeff  : std_logic_vector(DATA_WIDTH-1 downto 0);  -- [in]
    --signal i_coeff_1  : std_logic_vector(DATA_WIDTH-1 downto 0) := X"01";  -- [in]
    --signal i_coeff_2  : std_logic_vector(DATA_WIDTH-1 downto 0) := X"01";  -- [in]
    --signal i_coeff_3  : std_logic_vector(DATA_WIDTH-1 downto 0) := X"01";  -- [in]
    signal load       : std_logic := '0';

    signal write_a	: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal read_a	: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal n_state : natural range 0 to 3;
    signal addr_a : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    
    file file_VECTORS : text;
    file file_RESULTS : text;
    file file_COEFFICIENTS : text;

begin  -- architecture test

  -- component instantiation
  DUT : top
    port map (
      clk     => clk,               
      rstb    => rstb,             
      i_coeff => i_coeff,           
      --i_coeff_1 => i_coeff_1,       
      --i_coeff_2 => i_coeff_2,        
      --i_coeff_3 => i_coeff_3,      
      addr_a => addr_a,
      we_a => we_a,
      write_a    => write_a,             
      read_a     => read_a,
      n_state => n_state,
      load => load
      );             

  -- clock generation
   pl : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process; --pl
  
  -- Input/Output
  WaveGen_Proc : process
    variable CurrentLine    : line;
    variable v_ILINE        : line;
    variable v_TAPS         : line;
    variable v_OLINE        : line;
    variable i_data_integer : integer := 0;
    variable o_data_integer : integer := 0;
    variable i_coeff_integer: integer := 0;
    variable i_data_slv     : std_logic_vector(DATA_WIDTH downto 0);
    variable count_lines : integer := 0;
    
  begin
    -- insert signal assignments here
    file_open(file_VECTORS, "input_vectors.txt", read_mode);
    file_open(file_RESULTS, "output_results.txt", write_mode);
    file_open(file_COEFFICIENTS, "fir_taps.txt", read_mode);
    
    we_a <= '0';
    rstb <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rstb <= '0';
    
    addr_a <= (others => '0');
    we_a <= '1'; --Set Load mode
    wait until rising_edge(clk); --Propagate state
    
    for i in 0 to 2 ** (ADDR_WIDTH - 1) - 1 loop
        if not endfile(file_VECTORS) then
            readline(file_VECTORS, v_ILINE);
            read(v_ILINE, i_data_integer);
            write_a <= std_logic_vector(to_signed(i_data_integer, write_a'length));
        else
            write_a <= (others => '0');
        end if;
        
        wait until rising_edge(clk);
        
        addr_a <= std_logic_vector(unsigned(addr_a) + 1);
    end loop;
    
    we_a <= '0'; -- Set Read/Write mode
    wait until rising_edge(clk); --Propagate state
    
    load <= '1';
    for i in 0 to N_TAPS-1 loop
      readline(file_COEFFICIENTS, v_TAPS);
      read(v_TAPS, i_coeff_integer);
      i_coeff <= std_logic_vector(to_signed(i_coeff_integer, i_coeff'length));
      wait until rising_edge(clk); --Wait for loading
      wait until rising_edge(clk);
    end loop;
    load <= '0';


    while n_state /= 0 loop
        wait until rising_edge(clk); --Wait for computations
    end loop;
 
    addr_a <= std_logic_vector(to_unsigned(N_TAPS + 512, addr_a'length));
    wait until rising_edge(clk); -- Propagate state
    
    for i in N_TAPS+1 to 2 ** (ADDR_WIDTH - 1) - 1 loop   --Write

        addr_a <= std_logic_vector(to_unsigned(i + 512, addr_a'length));
        wait until rising_edge(clk);
        
        o_data_integer := to_integer(signed(read_a));
        write(v_OLINE, o_data_integer, left, DATA_WIDTH);
        writeline(file_RESULTS, v_OLINE);  

    end loop;
    
    file_close(file_VECTORS);
    file_close(file_RESULTS);

    wait;
  end process WaveGen_Proc;


end Behavioral;