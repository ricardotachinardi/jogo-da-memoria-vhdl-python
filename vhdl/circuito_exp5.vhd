library ieee;
use ieee.std_logic_1164.all;

entity circuito_exp5 is
	port (
	clock : in std_logic;
	reset : in std_logic;
	iniciar : in std_logic;
	botoes : in std_logic_vector(3 downto 0);

	db_clock : out std_logic;
	db_contagem : out std_logic_vector (6 downto 0);
	db_jogadafeita : out std_logic_vector (6 downto 0);
	db_memoria : out std_logic_vector (6 downto 0);
	db_sequencia : out std_logic_vector (6 downto 0);
	db_tem_jogada : out std_logic;
	db_fimseq : out std_logic;
	db_igualjogada : out std_logic;
	db_igualseq : out std_logic;

	db_estado : out std_logic_vector(6 downto 0);

	leds: out std_logic_vector(3 downto 0);
	ganhou : out std_logic;
	perdeu : out std_logic;
	pronto : out std_logic;

	seleciona_modo_de_jogo_MQTT : out std_logic;
	espera_jogada_MQTT : out std_logic;
	final_acertou_MQTT : out std_logic;
	final_errou_MQTT  : out std_logic;
	
	sete_seg_vazio1 : out std_logic_vector(6 downto 0);
	sete_seg_vazio2 : out std_logic_vector(6 downto 0)

	);
end entity;

architecture estrutural of circuito_exp5 is

	-- sinais que saem da UC e entram na FD
	signal s_contaS: std_logic;
	signal s_zeraS: std_logic;
	signal s_contaE: std_logic;
	signal s_zeraE: std_logic;
	signal s_registraR: std_logic;
	signal s_registraM: std_logic;
	signal s_limpaR: std_logic;
	signal s_limpaM: std_logic;
	signal s_contaTMR: std_logic;
	signal s_zeraTMR: std_logic;
	signal s_fimS: std_logic;
	signal s_fimE: std_logic;
	signal s_db_FD_sequencia: std_logic_vector(3 downto 0);
	signal s_db_FD_contagem: std_logic_vector(3 downto 0);
	signal s_db_FD_jogada: std_logic_vector(3 downto 0);
	signal s_db_FD_memoria: std_logic_vector(3 downto 0);
	signal s_igualS: std_logic;
	signal s_igualJ: std_logic;
	signal s_jogada_feita: std_logic;
	signal s_fimTMR: std_logic;
	signal s_db_UC_estado: std_logic_vector(4 downto 0);

	signal s_fimTMRjogada: std_logic;
	signal	s_registraModoDeJogo : std_logic;
	signal	s_limpaModoDeJogo : std_logic;

	signal s_db_sel: std_logic_vector(3 downto 0);
	signal s_db_FD_ring:  std_logic_vector(3 downto 0);

	signal s_escreve_mem_random : std_logic;

	component fluxo_dados is
		port (
			contaS: in std_logic;
			zeraS: in std_logic;
			clock: in std_logic;
			contaE: in std_logic;
			zeraE: in std_logic;
			escreveM: in std_logic;
			botoes: in std_logic_vector(3 downto 0);
			registraR: in std_logic;
			registraM: in std_logic;
			limpaR: in std_logic;
			limpaM: in std_logic;

			registraModoDeJogo: in std_logic;
			limpaModoDeJogo: in std_logic;

			contaTMR: in std_logic;
			zeraTMR: in std_logic;


			fimS: out std_logic;
			fimE: out std_logic;
			db_sequencia: out std_logic_vector(3 downto 0);
			db_contagem: out std_logic_vector(3 downto 0);
			db_jogada: out std_logic_vector(3 downto 0);
			db_memoria: out std_logic_vector(3 downto 0);
			leds: out std_logic_vector(3 downto 0);
			db_tem_jogada: out std_logic;
			igualS: out std_logic; -- enderecoIgualSequencia
			igualJ: out std_logic; -- chavesIgualMemoria
			jogada_feita: out std_logic;

			db_sel: out std_logic_vector(3 downto 0);

			db_ring 	 : out std_logic_vector(3 downto 0);

			fimTMRjogada : out std_logic;
			fimTMR: out std_logic;

			escreve_mem_random: in std_logic
	);
	end component;

	component unidade_controle is
		port (
			clock     : in  std_logic;
			reset     : in  std_logic;
			iniciar   : in  std_logic;
			jogada 	  : in  std_logic;

			fimE      : in  std_logic;
			fimS      : in  std_logic;
			fimTMR    : in  std_logic;
			fimTMRjogada: in std_logic;

			igualS	  : in  std_logic;
			igualJ	  : in  std_logic;

			contaE    : out std_logic;
			contaS    : out std_logic;
			contaTMR  : out std_logic;

			zeraE     : out std_logic;
			zeraS     : out std_logic;
			zeraTMR   : out std_logic;

			registraR : out std_logic;
			registraM : out std_logic;
			registraModoDeJogo : out std_logic;

			ganhou    : out std_logic;
			perdeu	  : out std_logic;

			limpaR	  : out std_logic;
			limpaM	  : out std_logic;
			limpaModoDeJogo : out std_logic;

			pronto    : out std_logic;

			db_estado : out std_logic_vector(4 downto 0);

			modo_de_jogo : in std_logic_vector(3 downto 0);

			seleciona_modo_de_jogo_MQTT : out std_logic;
			espera_jogada_MQTT : out std_logic;
			final_acertou_MQTT : out std_logic;
			final_errou_MQTT  : out std_logic;

			escreve_mem_random : out std_logic
		);
	end component;

	component hexa7seg is
    	port (
	        hexa : in  std_logic_vector(3 downto 0);
	        sseg : out std_logic_vector(6 downto 0)
	    );
    end component;

	component estado7seg is
		port (
			estado : in  std_logic_vector(4 downto 0);
			sseg   : out std_logic_vector(6 downto 0)
		);
	end component;

begin

	FD: fluxo_dados
		port map (
			contaS => s_contaS,
			zeraS => s_zeraS,
			clock => clock,
			contaE => s_contaE,
			zeraE => s_zeraE,
			escreveM => '0',
			botoes => botoes,
			registraR => s_registraR,
			registraM => s_registraM,
			limpaR => s_limpaR,
			limpaM => s_limpaM,

			registraModoDeJogo => s_registraModoDeJogo,
			limpaModoDeJogo => s_limpaModoDeJogo,

			contaTMR => s_contaTMR,
			zeraTMR => s_zeraTMR,

			fimS => s_fimS,
			fimE => s_fimE,
			db_sequencia => s_db_FD_sequencia,
			db_contagem => s_db_FD_contagem,
			db_jogada => s_db_FD_jogada,
			db_memoria => s_db_FD_memoria,
			leds => leds,
			db_tem_jogada => db_tem_jogada,
			igualS => s_igualS,
			igualJ => s_igualJ,
			jogada_feita => s_jogada_feita,

			db_sel => s_db_sel,
			db_ring => s_db_FD_ring,

			fimTMRjogada => s_fimTMRjogada,
			fimTMR => s_fimTMR,

			escreve_mem_random => s_escreve_mem_random

	);


	UC: unidade_controle
		port map (
			clock     => clock,
			reset     => reset,
			iniciar   => iniciar,
			jogada 	  => s_jogada_feita,

			fimE      => s_fimE,
			fimS      => s_fimS,
			fimTMR    => s_fimTMR,
			fimTMRjogada => s_fimTMRjogada,

			igualS	  => s_igualS,
			igualJ	  => s_igualJ,

			contaE    => s_contaE,
			contaS    => s_contaS,
			contaTMR  => s_contaTMR,

			zeraE     => s_zeraE,
			zeraS     => s_zeraS,
			zeraTMR   => s_zeraTMR,

			registraR => s_registraR,
			registraM => s_registraM,
			registraModoDeJogo => s_registraModoDeJogo,

			ganhou    => ganhou,
			perdeu	  => perdeu,

			limpaR	  => s_limpaR,
			limpaM	  => s_limpaM,
			limpaModoDeJogo => s_limpaModoDeJogo,
			pronto    => pronto,

			db_estado => s_db_UC_estado,
			modo_de_jogo => s_db_sel,

			seleciona_modo_de_jogo_MQTT => seleciona_modo_de_jogo_MQTT,
			espera_jogada_MQTT  => espera_jogada_MQTT,
			final_acertou_MQTT  => final_acertou_MQTT,
			final_errou_MQTT  => final_errou_MQTT,

			escreve_mem_random => s_escreve_mem_random
		);

	HEX0: hexa7seg
		port map (
			hexa => s_db_FD_contagem,
			sseg => db_contagem
		);

--	HEX1: hexa7seg
--		port map (
--			hexa => s_db_FD_memoria,
--			sseg => db_memoria
--		);
	 -- 
	 -- HEX2: hexa7seg
     -- 	port map (
	 -- 		hexa => s_db_FD_jogada,
	 -- 		sseg => db_jogadafeita
	 -- 	);


	HEX3: hexa7seg
		port map (
	        hexa => s_db_FD_sequencia,
	        sseg => db_sequencia
	    );

	HEX4: estado7seg
		port map (
	        estado => s_db_UC_estado,
	        sseg => db_estado
	    );

	db_clock <= clock;
	db_fimseq <= s_fimS;
	db_igualjogada <= s_igualJ;
	db_igualseq <= s_igualS;
	sete_seg_vazio1 <=  "1111111" ;
	sete_seg_vazio2 <=  "1111111" ;


end estrutural;
