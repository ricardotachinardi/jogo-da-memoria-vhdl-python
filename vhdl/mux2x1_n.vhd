--------------------------------------------------------------------------
-- Arquivo   : mux2x1_n.vhd
-- Projeto   : Jogo do Desafio da Memoria
--------------------------------------------------------------------------
-- Descricao : multiplexador 2x1 com entradas de n bits (generic)
--
-- adaptado a partir do codigo my_4t1_mux.vhd do livro "Free Range VHDL"
--
-- exemplo de uso:
--   signal selecao : std_logic;
--   signal vetor0  : std_logic_vector(7 downto 0);
--   signal vetor1  : std_logic_vector(7 downto 0);
--   signal leds    : std_logic_vector(7 downto 0);
--
--   MUX1: mux2x1_n
--         generic map ( BITS => 8 )
--         port map (
--             D1      => vetor1,
--             D0      => vetor0,
--             SEL     => selecao,
--             MUX_OUT => leds
--         );
--
-- declaracao do componente:
--
-- component mux2x1_n
--     generic (
--        constant BITS: integer
--     );
--     port(
--         D0      : in  std_logic_vector (BITS-1 downto 0);
--         D1      : in  std_logic_vector (BITS-1 downto 0);
--         SEL     : in  std_logic;
--         MUX_OUT : out std_logic_vector (BITS-1 downto 0)
--     );
-- end component;
--
--------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     11/02/2020  1.0     Edson Midorikawa  criacao
--     04/02/2022  1.1     Edson Midorikawa  revisao
--------------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity mux2x1_n is
    generic (
        constant BITS: integer := 4
    );
    port(
        D0      : in  std_logic_vector (BITS-1 downto 0);
        D1      : in  std_logic_vector (BITS-1 downto 0);
        SEL     : in  std_logic_vector (3 downto 0);
        MUX_OUT : out std_logic_vector (BITS-1 downto 0)
    );
end entity;

architecture comportamental of mux2x1_n is
begin

    MUX_OUT <= D0 when (SEL = "0001") else
               D1 when (SEL = "0010") else
               D1;

end architecture;
