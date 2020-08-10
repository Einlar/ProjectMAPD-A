library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram is
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
	
end dpram;

architecture rtl of dpram is
	
	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector(7 downto 0);
	type memory_t is array(63 downto 0) of word_t;
	
	-- Declare the RAM
	shared variable ram : memory_t;

begin

	-- Port A
	process(clk)
	begin
		if(rising_edge(clk)) then 
			if(we_a = '1') then
				ram(addr_a) := data_a;
			end if;
			q_a <= ram(addr_a);
		end if;
	end process;
	
	-- Port B
	process(clk)
	   variable temp : signed(7 downto 0);
	begin
		if(rising_edge(clk)) then
			if(we_b = '1') then
			    temp := signed(data_a) + 1;
				ram(addr_b) := std_logic_vector(temp); --data_b
			end if;
			q_b <= ram(addr_b);
		end if;
	end process;
end rtl;