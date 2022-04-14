
library ieee;
use ieee.std_logic_1164.all;

entity mux4x1_n is
    generic (
        constant BITS: integer := 4
    );
    port(
        D0      : in  std_logic_vector (BITS-1 downto 0);
        D1      : in  std_logic_vector (BITS-1 downto 0);
		D2      : in  std_logic_vector (BITS-1 downto 0);
		D3      : in  std_logic_vector (BITS-1 downto 0);
        SEL     : in  std_logic_vector (3 downto 0);
        MUX_OUT : out std_logic_vector (BITS-1 downto 0)
    );
end entity;

architecture comportamental of mux4x1_n is
begin

    MUX_OUT <= D0 when (SEL = "0001") else
               D1 when (SEL = "0010") else
			   D2 when (SEL = "0100") else
			   D3 when (SEL = "1000") else
               D0;

end architecture;
