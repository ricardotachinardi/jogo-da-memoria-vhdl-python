library ieee;
use ieee.std_logic_1164.all;

entity ring_counter_tb is
end ring_counter_tb;

architecture behavior of ring_counter_tb is
	-- declaracao do componente para teste unitario
	component ring_counter
		port (
			clock : in std_logic;
			reset : in std_logic;
			output : out std_logic_vector(3 downto 0)
		);
	end component;

	--inputs
	signal reset : std_logic := '0';
	--outputs
	signal output : std_logic_vector(3 downto 0);
	-- periodo de clock
	constant clock_period : time := 10 ns;
	signal clock : std_logic := '0';

begin
	-- instanciar uut
	uut : ring_counter
	port map(
		clock => clock, 
		reset => reset, 
		output => output
	);

	-- clock process
	clock_process : process
	begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
	end process;
	
	
	stim_proc : process
	begin
		report "BOT";		-- segura o estado de reset por 100ns
		wait for clock_period * 10;
		reset <= '1';
		wait for clock_period * 10;
		reset <= '0';
		wait for clock_period * 10;
		report "EOT";
		wait;

	end process;
end architecture;