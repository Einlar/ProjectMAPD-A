library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use STD.textio.all;
-------------------------------------------------------------------------------


entity dpram_tb is

end entity dpram_tb;

architecture test of dpram_tb is

    component dpram is
        port 
        (	
            data_a	: in std_logic_vector(7 downto 0);
            data_b	: in std_logic_vector(7 downto 0);
            addr_a	: in natural range 0 to 63;
            addr_b	: in natural range 0 to 63;
            we_a	: in std_logic := '1';
            we_b	: in std_logic := '1';
            clk		: in std_logic;
            q_a		: out std_logic_vector(7 downto 0);
            q_b		: out std_logic_vector(7 downto 0);
            rst_dpr : in std_logic
         );
        
    end component; --dpram
    
    signal  data_a	: std_logic_vector(7 downto 0);
    signal  data_b	: std_logic_vector(7 downto 0);
    signal  addr_a	: natural range 0 to 63;
    signal  addr_b	: natural range 0 to 63;
    signal  we_a    : std_logic := '1';
    signal  we_b    : std_logic := '1';
    signal  clk	    : std_logic;
    signal  q_a	    : std_logic_vector(7 downto 0);
    signal  q_b	    : std_logic_vector(7 downto 0);
    signal rst_dpr : std_logic;
    signal   clk_enable   : boolean := true; 
    constant c_WIDTH      : natural := 8;
    file     file_VECTORS : text;
    file     file_RESULTS : text;
    
begin
    DUT :  dpram
        port map (
            data_a  =>  data_a  ,
            data_b  =>  data_b  ,
            addr_a  =>  addr_a  ,
            addr_b  =>  addr_b  ,
            we_a    =>  we_a    , 
            we_b    =>  we_b    , 
            clk	    =>  clk	    ,  
            q_a	    =>  q_a	    ,  
            q_b	    =>  q_b	    ,
            rst_dpr =>  rst_dpr ); 

    
   pl : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process; --pl
    
    reset : process
    begin
        rst_dpr <= '1'; wait for 10 us; rst_dpr <= '0'; wait;
    end process; --reset

    WaveGen_Proc : process
        variable CurrentLine    : line;
        variable v_ILINE        : line;
        variable v_OLINE        : line;
        variable i_data_integer : integer := 0;
        variable o_data_integer : integer := 0;
      begin
        -- insert signal assignments here
        file_open(file_VECTORS, "input_vectors.txt", read_mode);
        file_open(file_RESULTS, "output_results.txt", write_mode);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        while not endfile(file_VECTORS) loop
            readline(file_VECTORS, v_ILINE);
            read(v_ILINE, i_data_integer);
            data_a         <= std_logic_vector(to_signed(i_data_integer, data_a'length));
            wait until rising_edge(clk);
            o_data_integer := to_integer(signed(q_b)); --data_a
            write(v_OLINE, o_data_integer, left, c_WIDTH);
            writeline(file_RESULTS, v_OLINE);
        end loop;
        file_close(file_VECTORS);
        file_close(file_RESULTS);
        clk_enable <= false;
        wait;
    end process WaveGen_Proc;

end architecture test;

-------------------------------------------------------------------------------

configuration dpram_tb_cfg of dpram_tb is
  for test
  end for;
end dpram_tb_cfg;

-------------------------------------------------------------------------------