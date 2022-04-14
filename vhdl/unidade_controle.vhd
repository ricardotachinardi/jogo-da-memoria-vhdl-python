library ieee;
use ieee.std_logic_1164.all;

entity unidade_controle is
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
end entity;

architecture fsm of unidade_controle is
	type t_estado is (inicial,
					  inicializa_elementos,

					  seleciona_modo_de_jogo,
					  espera_mais_modo_de_jogo,
					  registra_modo_de_jogo,

					  prepara_proximo_nivel,

					  carrega_dado,
					  mostra_dado,
					  zera_leds,
					  mostra_apagado,
					  proxima_posicao,

					  prepara_jogadas,
					  espera_jogada,
					  registra_jogada,
					  espera_mais,
					  compara_jogada,
					  proxima_jogada,

					  checa_jogo_terminou,
					  incrementa_endereco,
					  cria_prox_random,

					  vai_proximo_nivel,

					  final_acertou,
					  final_errou);
	signal Eatual, Eprox: t_estado;
begin

	-- memoria de estado
	process (clock,reset)
	begin
		if reset='1' then
			Eatual <= inicial;
		elsif clock'event and clock = '1' then
			Eatual <= Eprox;
		end if;
	end process;

	-- logica de proximo estado
	Eprox <=
		inicial     			when  Eatual=inicial and iniciar='0' else
		inicializa_elementos  	when  Eatual=inicial and iniciar='1' else

		seleciona_modo_de_jogo 	when  Eatual=inicializa_elementos else
		seleciona_modo_de_jogo  when  Eatual=seleciona_modo_de_jogo and jogada='0' else

		espera_mais_modo_de_jogo when  Eatual=seleciona_modo_de_jogo and jogada='1' else
		registra_modo_de_jogo	when  Eatual=espera_mais_modo_de_jogo  else

		prepara_proximo_nivel	when  Eatual=registra_modo_de_jogo else

		carrega_dado			when  Eatual=prepara_proximo_nivel else
		mostra_dado  			when  Eatual=carrega_dado else
		mostra_dado  			when  Eatual=mostra_dado and fimTMR='0' else
		zera_leds	  			when  Eatual=mostra_dado and fimTMR='1' else
		mostra_apagado			when  Eatual=zera_leds else
		mostra_apagado			when  Eatual=mostra_apagado and fimTMR='0' else
		proxima_posicao			when  Eatual=mostra_apagado and fimTMR='1' and igualS='0' else
		carrega_dado			when  Eatual=proxima_posicao else

		prepara_jogadas			when  Eatual=mostra_apagado and fimTMR='1' and igualS='1' else

		espera_jogada 			when  Eatual=prepara_jogadas  else
		espera_jogada 			when  Eatual=espera_jogada and jogada='0' and fimTMRjogada='0' else


		registra_jogada    		when  Eatual=espera_jogada and jogada='1' else
		espera_mais 			when  Eatual=registra_jogada else
		compara_jogada  		when  Eatual=espera_mais else
		proxima_jogada     		when  Eatual=compara_jogada and igualJ='1' and igualS='0' else
		espera_jogada			when  Eatual=proxima_jogada else

		checa_jogo_terminou		when  Eatual=compara_jogada and igualJ='1' and igualS='1' else
		incrementa_endereco		when Eatual=checa_jogo_terminou and modo_de_jogo = "0100" and fimS= '0' else

		cria_prox_random    when  Eatual=checa_jogo_terminou and modo_de_jogo = "1000"  and fimS= '0' else

		cria_prox_random    when  Eatual=incrementa_endereco  else

		vai_proximo_nivel		when  Eatual=checa_jogo_terminou and (modo_de_jogo = "0001" or modo_de_jogo = "0010") and fimS= '0' else

		vai_proximo_nivel		when  Eatual=cria_prox_random and fimS='0' else
		prepara_proximo_nivel   when  Eatual=vai_proximo_nivel else

		final_errou				when  Eatual=espera_jogada and fimTMRjogada='1' else
		final_errou     		when  Eatual=compara_jogada and igualJ='0' else
		final_errou     		when  Eatual=final_errou and iniciar='0' else
		inicializa_elementos   	when  Eatual=final_errou and iniciar='1' else

		final_acertou   		when  Eatual=checa_jogo_terminou and fimS='1' and fimE='1' else
		final_acertou   		when  Eatual=final_acertou and iniciar='0' else
		inicializa_elementos   	when  Eatual=final_acertou and iniciar='1' else

		inicial;

	-- logica de saída (maquina de Moore)


	with Eatual select
		escreve_mem_random <= 	'1' when espera_mais_modo_de_jogo | cria_prox_random,
								'0' when others;

	with Eatual select
		registraModoDeJogo <= 	'1' when registra_modo_de_jogo,
								'0' when others;

	---
	with Eatual select
		zeraE <=      '1' when inicializa_elementos | prepara_jogadas | vai_proximo_nivel,
					  '0' when others;

	with Eatual select
		zeraS <=      '1' when inicializa_elementos,
					  '0' when others;

	with Eatual select
		limpaR <=      '1' when inicializa_elementos | prepara_jogadas,
					   '0' when others;

	with Eatual select
		limpaM <=      '1' when inicializa_elementos | zera_leds | prepara_jogadas,
					   '0' when others;
   with Eatual select
		limpaModoDeJogo <=      '1' when inicializa_elementos,
					   '0' when others;

	with Eatual select
		zeraTMR <=      '1' when carrega_dado | zera_leds | proxima_jogada,
						'0' when others;

	with Eatual select
		registraM <=   '1' when carrega_dado,
					   '0' when others;

	with Eatual select
		contaTMR <=    '1' when mostra_dado | mostra_apagado | espera_jogada,
					   '0' when others;

	with Eatual select
		contaE <=      '1' when proxima_posicao | proxima_jogada | incrementa_endereco,
					   '0' when others;
	---------

	with Eatual select
		registraR <=   '1' when registra_jogada,
					  '0' when others;

	with Eatual select
		contaS <=     '1' when vai_proximo_nivel,
					  '0' when others;

	with Eatual select
		pronto <=     '1' when final_acertou | final_errou,
					  '0' when others;

	with Eatual select
		ganhou <=      '1' when final_acertou,
					   '0' when others;

	with Eatual select
		perdeu <=      '1' when  final_errou,
					   '0' when others;
						
	  with Eatual select
   		seleciona_modo_de_jogo_MQTT <=      '1' when seleciona_modo_de_jogo,
   					   '0' when others;

   	with Eatual select
   		espera_jogada_MQTT <=      '1' when  espera_jogada,
   					   '0' when others;

	   with Eatual select
   		final_acertou_MQTT <=      '1' when final_acertou,
   					   '0' when others;

   	with Eatual select
   		final_errou_MQTT <=      '1' when  final_errou,
   					   '0' when others;


	-- saida de depuracao (db_estado)
	with Eatual select
		db_estado <= "00000" when inicial,  			 -- 0
					 "00001" when inicializa_elementos,  -- 1
					 "01101" when seleciona_modo_de_jogo, -- letra "d"
					 "11011" when registra_modo_de_jogo,


					 "00010" when prepara_proximo_nivel, -- 2

					 "00011" when carrega_dado,    		 -- 3
					 "11110" when mostra_dado,  		 -- 4 linha embaixo
					 "00101" when zera_leds,			 -- 5
					 "11101" when mostra_apagado, 		 -- 6 linha em cima
					 "00111" when proxima_posicao,       -- 7

					 "01000" when prepara_jogadas,		-- 8
					 "11111" when espera_jogada,		-- 9 letra  "P" 
					 "01010" when registra_jogada,		-- A
					 "01011" when compara_jogada,		-- B
					 "01100" when proxima_jogada,		-- C

					 "01101" when checa_jogo_terminou,	-- D
					 "01110" when vai_proximo_nivel,    -- E

					 "01010" when final_acertou,     	-- letra  "A"
					 "01110" when final_errou,      	-- letra  "Ë"

					 "11100" when others;     			-- quadrado embaixo
end fsm;
