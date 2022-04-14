
library ieee;
use ieee.std_logic_1164.all;

entity timer_selector is
    port(
        SEL     : in  std_logic_vector (3 downto 0);
        MUX_OUT : out integer
    );
end entity;

architecture comportamental of timer_selector is
begin

    MUX_OUT <= 300 when (SEL = "0001") else
			   700 when (SEL = "0010") else
			   1100 when (SEL = "0100") else
			   1100 when (SEL = "1000") else
				500;

end architecture;
