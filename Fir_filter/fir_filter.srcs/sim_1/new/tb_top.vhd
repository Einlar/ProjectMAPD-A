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
    component top is
    Port ( 
            t_clk     : in  std_logic;
            t_rstb    : in  std_logic;
            i_coeff_0 : in  std_logic_vector(7 downto 0);
            i_coeff_1 : in  std_logic_vector(7 downto 0);
            i_coeff_2 : in  std_logic_vector(7 downto 0);
            i_coeff_3 : in  std_logic_vector(7 downto 0);
            data_a	: in std_logic_vector(7 downto 0);
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
    end component;
    
    signal clk : std_logic := '0';
    signal rstb : std_logic;
    
    signal read_data : std_logic := '0';
    signal compute : std_logic := '0';
    
    signal i_coeff_0  : std_logic_vector(7 downto 0) := X"01";  -- [in]
    signal i_coeff_1  : std_logic_vector(7 downto 0) := X"01";  -- [in]
    signal i_coeff_2  : std_logic_vector(7 downto 0) := X"01";  -- [in]
    signal i_coeff_3  : std_logic_vector(7 downto 0) := X"01";  -- [in]

    signal data_a	: std_logic_vector(7 downto 0);
    signal q_b		: std_logic_vector(7 downto 0);
    signal n_state : natural range 0 to 2;
    signal rrama, rramb, wramb : std_logic_vector(7 downto 0);
    signal busy : std_logic;
    
    signal p_addra :  natural range 0 to 15;
    signal p_addrb :  natural range 16 to 31;
    signal p_counter : natural range 0 to 16;
    
    constant RAM_SIZE : natural := 16;
    constant c_WIDTH  : natural := 8;
    file file_VECTORS : text;
    file file_RESULTS : text;

begin  -- architecture test

  -- component instantiation
  DUT : top
    port map (
      t_clk     => clk,               -- [in  std_logic]
      t_rstb    => rstb,              -- [in  std_logic]
      i_coeff_0 => i_coeff_0,           -- [in  std_logic_vector(7 downto 0)]
      i_coeff_1 => i_coeff_1,           -- [in  std_logic_vector(7 downto 0)]
      i_coeff_2 => i_coeff_2,           -- [in  std_logic_vector(7 downto 0)]
      i_coeff_3 => i_coeff_3,           -- [in  std_logic_vector(7 downto 0)]
      data_a    => data_a,              -- [in  std_logic_vector(7 downto 0)]
      q_b          => q_b,
      read_data    => read_data,
      compute => compute,
      n_state => n_state,
      rrama => rrama,
      rramb => rramb,
      wramb => wramb,
      busy => busy,
      p_addra => p_addra,
      p_addrb => p_addrb,
      p_counter => p_counter
      );             -- [out std_logic_vector(9 downto 0)]

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
    variable v_OLINE        : line;
    variable i_data_integer : integer := 0;
    variable o_data_integer : integer := 0;
    variable i_data_slv     : std_logic_vector(7 downto 0);
    variable count_lines : integer := 0;
    variable first_cycle : boolean := True;
    variable last_cycle : boolean := False;
    variable lines_left : natural := 0;
    
  begin
    -- insert signal assignments here
    file_open(file_VECTORS, "input_vectors.txt", read_mode);
    file_open(file_RESULTS, "output_results.txt", write_mode);
    
    rstb <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rstb <= '0';
    
    read_data <= '1'; --Set Read mode
    wait until rising_edge(clk); --Propagate state
    
    while not endfile(file_VECTORS) loop

        readline(file_VECTORS, v_ILINE);
        read(v_ILINE, i_data_integer);
        data_a <= std_logic_vector(to_unsigned(i_data_integer, data_a'length));
        
        wait until rising_edge(clk);
        
        while busy = '1' loop
            wait until rising_edge(clk);
        end loop;
      
          --o_data_integer := to_integer(unsigned(q_b));
          --write(v_OLINE, o_data_integer, left, c_WIDTH);
          --writeline(file_RESULTS, v_OLINE);
      
    end loop;
    
    file_close(file_VECTORS);
    file_close(file_RESULTS);

    wait;
  end process WaveGen_Proc;


end Behavioral;
