library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;


entity tb_top is
--  Port ( );
end tb_top;

architecture Behavioral of tb_top is
constant ADDR_WIDTH : integer := 10;
constant N_TAPS     : integer := 16; 
constant DATA_WIDTH : integer := 32;
constant HALF_RAM : natural := 2 ** (ADDR_WIDTH - 1);
component top is
    Port ( 
        clk     : in  std_logic;
        rstb    : in  std_logic;
        i_coeff : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        addr_a  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        we_a    : in  std_logic;
        write_a : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        read_a  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        n_state : out natural range 0 to 3;
        load    : in  std_logic := '0'
    );
end component;
    
    signal clk        : std_logic := '0';
    signal rstb, we_a : std_logic;
    
    signal i_coeff    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal load       : std_logic := '0';
    
    signal write_a	  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal read_a	  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal n_state    : natural range 0 to 3;
    signal addr_a     : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    
    file file_VECTORS : text;
    file file_RESULTS : text;
    file file_COEFFICIENTS : text;

begin  

    DUT : top
    port map (
        clk     => clk,               
        rstb    => rstb,             
        i_coeff => i_coeff,             
        addr_a  => addr_a,
        we_a    => we_a,
        write_a => write_a,             
        read_a  => read_a,
        n_state => n_state,
        load    => load
    );             

  
    pl : process --Clock generation
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process; --pl
  
    WaveGen_Proc : process --Main process
    variable CurrentLine    : line;
    variable v_ILINE        : line;
    variable v_TAPS         : line;
    variable v_OLINE        : line;
    variable i_data_integer : integer := 0;
    variable o_data_integer : integer := 0;
    variable i_coeff_integer: integer := 0;
    
    begin
        file_open(file_VECTORS, "input_vectors.txt", read_mode);
        file_open(file_RESULTS, "output_results.txt", write_mode);
        file_open(file_COEFFICIENTS, "fir_taps.txt", read_mode);
        
        --Reset phase
        we_a <= '0';
        rstb <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rstb <= '0';
        
        --Load phase
        addr_a <= (others => '0');
        we_a <= '1'; 
        wait until rising_edge(clk); --Propagate state
        
        --Loop over lower half of RAM and load samples from file
        for i in 0 to 2 ** (ADDR_WIDTH - 1) - 1 loop 
            if not endfile(file_VECTORS) then
                readline(file_VECTORS, v_ILINE);
                read(v_ILINE, i_data_integer);
                write_a <= std_logic_vector(to_signed(i_data_integer, write_a'length));
            else
                write_a <= (others => '0'); --Pad with trailing 0s
            end if;
            
            wait until rising_edge(clk);
            
            addr_a <= std_logic_vector(unsigned(addr_a) + 1);
        end loop;
        
        --Read/write phase
        we_a <= '0'; 
        wait until rising_edge(clk); --Propagate state
        
        --Load coefficients
        load <= '1'; 
        for i in 0 to N_TAPS-1 loop
            readline(file_COEFFICIENTS, v_TAPS);
            read(v_TAPS, i_coeff_integer);
            i_coeff <= std_logic_vector(to_signed(i_coeff_integer, i_coeff'length));
            wait until rising_edge(clk); --Wait for loading
            wait until rising_edge(clk);
        end loop;
        load <= '0';
        
        --Wait for computations (i.e. until the FPGA is idle)
        while n_state /= 0 loop
            wait until rising_edge(clk); 
        end loop;
        
        --Output phase
        --The first N_TAPS + 1 addresses contain gibberish (due to the time needed for initializing the FIR)
        --so they are skipped
        
        addr_a <= std_logic_vector(to_unsigned(N_TAPS + 2 + HALF_RAM, addr_a'length)); --Start from N_TAPS + 2
        wait until rising_edge(clk); -- Propagate state
        
        for i in N_TAPS + 3 to 2 ** (ADDR_WIDTH - 1) - 1 loop --Loop over the upper half of RAM
            addr_a <= std_logic_vector(to_unsigned(i + HALF_RAM, addr_a'length));
            wait until rising_edge(clk);
            
            o_data_integer := to_integer(signed(read_a)); --Write to file
            write(v_OLINE, o_data_integer, left, DATA_WIDTH);
            writeline(file_RESULTS, v_OLINE);  
        
        end loop;
        
        file_close(file_VECTORS);
        file_close(file_RESULTS);
        
        wait;
    end process WaveGen_Proc;
        
end Behavioral;