library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram is
    generic(
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural  
	);
	port 
	(	
		data_a	: in std_logic_vector(DATA_WIDTH -1 downto 0); 
		data_b	: in std_logic_vector(DATA_WIDTH -1 downto 0);
		addr_a : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		addr_b	: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		we_a	: in std_logic := '1'; 
		we_b	: in std_logic := '1';
		clk		: in std_logic;
		q_a		: out std_logic_vector(DATA_WIDTH -1 downto 0);
		q_b		: out std_logic_vector(DATA_WIDTH -1 downto 0);
		rst_dpr : in std_logic
	 );
	
end dpram;

architecture rtl of dpram is
	
	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector(DATA_WIDTH -1 downto 0);
	type memory_t is array(2 ** ADDR_WIDTH - 1 downto 0) of word_t; 
	
	-- Declare the RAM
	shared variable ram : memory_t;
	
	signal loc_a, loc_b : integer;

begin
    loc_a <= to_integer(unsigned(addr_a));
    
	-- Port A
	process(clk)
	begin
		if(rising_edge(clk)) then 
			if(we_a = '1') then
				ram(loc_a) := data_a;
			end if;
			q_a <= ram(loc_a);
		end if;
	end process;
	
	loc_b <= to_integer(unsigned(addr_b));
	
	-- Port B
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(we_b = '1') then
				ram(loc_b) := data_b; 
			end if;
			q_b <= ram(loc_b);
		end if;
	end process;
end rtl;