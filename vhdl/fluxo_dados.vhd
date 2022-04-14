library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fluxo_dados is
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

		fimTMRjogada: out std_logic;
		fimTMR: out std_logic;

		escreve_mem_random: in std_logic;
		
		db_output_regRandom: out std_logic_vector(3 downto 0);
		db_ring: out std_logic_vector(3 downto 0)

);
end entity;

architecture estrutural of fluxo_dados is

	signal s_sequencia: std_logic_vector(3 downto 0);
	signal s_not_zeraS: std_logic;

	signal s_endereco: std_logic_vector(3 downto 0);
	signal s_not_zeraE: std_logic;

	signal s_jogada: std_logic_vector(3 downto 0);
	signal s_not_registraR: std_logic;

	signal s_dado: std_logic_vector(3 downto 0);

	signal s_not_escreveM: std_logic;
	signal s_not_registraM: std_logic;

	signal s_modo_de_jogo: std_logic_vector(3 downto 0);

	signal s_not_registraModoDeJogo: std_logic;
	signal s_dado_memoria_1: std_logic_vector(3 downto 0);
	signal s_dado_memoria_2: std_logic_vector(3 downto 0);

  -- edge_detector
  	signal s_botaoacionado: std_logic;

	signal s_fimTMRjogada1 : std_logic;
	signal s_fimTMRjogada2 : std_logic;
	signal s_fimTMRjogada3 : std_logic;
	signal s_fimTMRjogada4 : std_logic;

	signal s_output_ring_counter : std_logic_vector(3 downto 0);
	signal s_output_RegRandom : std_logic_vector(3 downto 0);
	signal s_dado_memoria_random: std_logic_vector(3 downto 0);
	signal s_not_escreve_mem_random: std_logic;


component ring_counter is
	port (
		clock : in std_logic;
		reset : in std_logic;
		output : out std_logic_vector (3 downto 0)
	);
end component;

component mux4x1_n
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
end component;

component mux4x1_timer is
    generic (
        constant BITS: integer := 4
    );
    port(
        D0      : in  std_logic;
        D1      : in  std_logic;
		D2      : in  std_logic;
		D3      : in  std_logic;
        SEL     : in  std_logic_vector (3 downto 0);
        MUX_OUT : out std_logic
    );
end component;

	component contador_163
    port (
        clock : in  std_logic;
        clr   : in  std_logic;
        ld    : in  std_logic;
        ent   : in  std_logic;
        enp   : in  std_logic;
        D     : in  std_logic_vector (3 downto 0);
        Q     : out std_logic_vector (3 downto 0);
        rco   : out std_logic
   );
  end component;

  component ram_16x4 is
    port (
        clk          : in  std_logic;
        endereco     : in  std_logic_vector(3 downto 0);
        dado_entrada : in  std_logic_vector(3 downto 0);
        we           : in  std_logic;
        ce           : in  std_logic;
        dado_saida   : out std_logic_vector(3 downto 0)
    );
  end component;

  component ram_16x4_2 is
    port (
 	   clk          : in  std_logic;
 	   endereco     : in  std_logic_vector(3 downto 0);
 	   dado_entrada : in  std_logic_vector(3 downto 0);
 	   we           : in  std_logic;
 	   ce           : in  std_logic;
 	   dado_saida   : out std_logic_vector(3 downto 0)
    );
  end component;

  component registrador_173
    port (
      clock : in  std_logic;
      clear : in  std_logic;
      en1   : in  std_logic;
      en2   : in  std_logic;
      D     : in  std_logic_vector (3 downto 0);
      Q     : out std_logic_vector (3 downto 0)
    );
  end component;

  component comparador_85
    port (
      i_A3   : in  std_logic;
      i_B3   : in  std_logic;
      i_A2   : in  std_logic;
      i_B2   : in  std_logic;
      i_A1   : in  std_logic;
      i_B1   : in  std_logic;
      i_A0   : in  std_logic;
      i_B0   : in  std_logic;
      i_AGTB : in  std_logic;
      i_ALTB : in  std_logic;
      i_AEQB : in  std_logic;
      o_AGTB : out std_logic;
      o_ALTB : out std_logic;
      o_AEQB : out std_logic
    );
  end component;

  component contador_m is
    generic (
      constant M: integer -- modulo do contador
    );
    port (
      clock   : in  std_logic;
      zera_as : in  std_logic;
      zera_s  : in  std_logic;
      conta   : in  std_logic;
      Q       : out std_logic_vector(natural(ceil(log2(real(M))))-1 downto 0);
      fim     : out std_logic;
      meio    : out std_logic
    );
  end component;

  component edge_detector
  port (
    clock  : in  std_logic;
    reset  : in  std_logic;
    sinal  : in  std_logic;
    pulso  : out std_logic
  );
  end component;

begin
	s_not_zeraS <= not zeraS;
	s_not_zeraE <= not zeraE;
	s_not_registraR <= not registraR;
  s_not_escreveM <= not escreveM;
	s_not_registraM <= not registraM;
	s_not_registraModoDeJogo <= not registraModoDeJogo;
	s_not_escreve_mem_random <= not escreve_mem_random;
	
	
  -- edge_detector
  s_botaoacionado <= botoes(0) or botoes(1) or botoes(2) or botoes(3);

	ContSeq: contador_163
		port map (
			clock => clock,
			clr   => s_not_zeraS, -- clr ativo baixo
			ld    => '1',
			ent   => '1',
			enp   => contaS,
			D     => "0000",
			Q     => s_sequencia,
			rco   => fimS
		);
	db_sequencia <= s_sequencia;

	ContEnd: contador_163
    port map (
      clock => clock,
      clr   => s_not_zeraE, -- clr ativo baixo
      ld    => '1',
      ent   => '1',
      enp   => contaE,
      D     => "0000",
      Q     => s_endereco,
      rco   => fimE
    );
	db_contagem <= s_endereco;

	CompSeq: comparador_85
		port map (
			i_A3   => s_sequencia(3),
			i_B3   => s_endereco(3),
			i_A2   => s_sequencia(2),
			i_B2   => s_endereco(2),
			i_A1   => s_sequencia(1),
			i_B1   => s_endereco(1),
			i_A0   => s_sequencia(0),
			i_B0   => s_endereco(0),
			i_AGTB => '0',
			i_ALTB => '0',
			i_AEQB => '1',
			o_AGTB => open,
			o_ALTB => open,
			o_AEQB => igualS
		);

	RegBotoes: registrador_173
		port map (
			clock => clock,
			clear => limpaR,
			en1   => s_not_registraR, -- en1 ativo baixo
			en2   => '0',
			D     => botoes,
			Q     => s_jogada
		);
	db_jogada <= s_jogada;

	-- NOVOS COMPONENTES PARA O PROJETO --------------------------------

	RingCounter: ring_counter
	port map(
		clock => clock,
		reset => '0',
		output => s_output_ring_counter
	);
	
	db_ring <= s_output_ring_counter;

	MemJogRandom: entity work.ram_16x4(ram_modelsim)
	--MemJogAleatorio: entity work.ram_16x4(ram_mif)

		port map (
			clk          => clock,
			endereco     => s_endereco,
			dado_entrada => s_output_ring_counter,
			we           => s_not_escreve_mem_random,
			ce           => '0',
			dado_saida   => s_dado_memoria_random
		);


	MuxMemoria: mux4x1_n
	generic map(
         BITS => 4
    )
    port map(
        D0      => s_dado_memoria_1,
        D1      => s_dado_memoria_2,
		D2		=> s_dado_memoria_random,
		D3		=> s_dado_memoria_random,
        SEL     => s_modo_de_jogo,
        MUX_OUT => s_dado
    );

	MuxTimer: mux4x1_timer
	generic map(
         BITS => 4
    )
    port map(
        D0      => s_fimTMRjogada1,
        D1      => s_fimTMRjogada2,
		D2		=> s_fimTMRjogada3,
		D3		=> s_fimTMRjogada4,
        SEL     => s_modo_de_jogo,
        MUX_OUT => fimTMRjogada
    );
	db_sel <= s_modo_de_jogo;

	RegModoDeJogo: registrador_173
    port map (
      clock => clock,
      clear => limpaModoDeJogo,
      en1   => s_not_registraModoDeJogo, -- en1 ativo baixo
      en2   => '0',
      D     => botoes,
      Q     => s_modo_de_jogo
    );


	--MemJog1: ram_16x4
	MemJog1: entity work.ram_16x4(ram_modelsim)
	--MemJog1: entity work.ram_16x4(ram_mif)

		port map (
			clk          => clock,
			endereco     => s_endereco,
			dado_entrada => s_jogada,
			we           => '1', -- we ativo baixo
			ce           => '0',
			dado_saida   => s_dado_memoria_1
		);

	 MemJog2: entity work.ram_16x4_2(ram_modelsim)
	--MemJog2: entity work.ram_16x4_2(ram_mif)
		port map (
			clk          => clock,
			endereco     => s_endereco,
			dado_entrada => s_jogada,
			we           => '1', -- we ativo baixo
			ce           => '0',
			dado_saida   => s_dado_memoria_2
		);

	TimerJogada1: contador_m
		generic map(
			M => 7000
		)
	    port map(
	      clock   => clock,
	      zera_as => zeraTMR,
	      zera_s  => '0',
	      conta   => contaTMR,
	      Q       => open,
	      fim     => s_fimTMRjogada1,
	      meio    => open
	    );

	TimerJogada2: contador_m
		generic map(
			M => 6000
		)
	    port map(
	      clock   => clock,
	      zera_as => zeraTMR,
	      zera_s  => '0',
	      conta   => contaTMR,
	      Q       => open,
	      fim     => s_fimTMRjogada2,
	      meio    => open
	    );

	TimerJogada3: contador_m
		generic map(
			M => 5000
		)
	    port map(
	      clock   => clock,
	      zera_as => zeraTMR,
	      zera_s  => '0',
	      conta   => contaTMR,
	      Q       => open,
	      fim     => s_fimTMRjogada3,
	      meio    => open
	    );

	TimerJogada4: contador_m
		generic map(
			M => 4000
		)
	    port map(
	      clock   => clock,
	      zera_as => zeraTMR,
	      zera_s  => '0',
	      conta   => contaTMR,
	      Q       => open,
	      fim     => s_fimTMRjogada4,
	      meio    => open
	    );
	db_memoria <= s_dado;

	CompJog: comparador_85
		port map (
			i_A3   => s_dado(3),
			i_B3   => s_jogada(3),
			i_A2   => s_dado(2),
			i_B2   => s_jogada(2),
			i_A1   => s_dado(1),
			i_B1   => s_jogada(1),
			i_A0   => s_dado(0),
			i_B0   => s_jogada(0),
			i_AGTB => '0',
			i_ALTB => '0',
			i_AEQB => '1',
			o_AGTB => open,
			o_ALTB => open,
			o_AEQB => igualJ
		);

    RegMem: registrador_173
    port map (
      clock => clock,
      clear => limpaM,
      en1   => s_not_registraM, -- en1 ativo baixo
      en2   => '0',
      D     => s_dado,
      Q     => leds
    );



	Timer: contador_m
	generic map(
		M => 600
	)
    port map(
      clock   => clock,
      zera_as => zeraTMR,
      zera_s  => '0',
      conta   => contaTMR,
      Q       => open,
      fim     => fimTMR,
      meio    => open
    );

    JGD: edge_detector
      port map (
          clock  => clock,
          reset  => '0',
          sinal  => s_botaoacionado,
          pulso  => jogada_feita
    );
  db_tem_jogada <= s_botaoacionado;

end estrutural;
