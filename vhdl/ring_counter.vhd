library ieee;
use ieee.std_logic_1164.all;
entity ring_counter is
	port (
		clock : in std_logic;
		reset : in std_logic;
		output : out std_logic_vector (3 downto 0)
	);
end ring_counter;
architecture behavioral of ring_counter is
	signal temp : std_logic_vector(3 downto 0) := "0001";
begin
	process (reset, clock)
	begin
		if reset ='1' then
			temp <= "0001";
		elsif rising_edge(clock) then
			temp(1) <= temp(0);
			temp(2) <= temp(1);
			temp(3) <= temp(2);
			temp(0) <= temp(3);
		end if;
	end process;
	output <= temp;
end behavioral;