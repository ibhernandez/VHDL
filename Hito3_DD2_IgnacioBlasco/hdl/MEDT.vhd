
library ieee;
use ieee.std_logic_1164.all;

entity MEDT is 

port(
    clk           : in std_logic;
    nRst          : in std_logic;
    switch_p1	  : in std_logic;
    switch_P2	  : in std_logic;
    CL		  : buffer std_logic;
    CS 		  : buffer std_logic;
    SDAT	  : in std_logic;
    mux_disp 	  : buffer std_logic_vector(4 downto 0);
    seg 	  : buffer std_logic_vector(6 downto 0)
    );  
end entity;

architecture struct of MEDT is
  signal data_out:  	 std_logic_vector(8 downto 0);
  signal flag_data_read: std_logic;
  signal ena_CS        : std_logic;
  signal tic      : std_logic;
  signal escala   : std_logic_vector(1 downto 0);
  signal sgn 	  : std_logic;
  signal mod_BCD  : std_logic_vector( 11 downto 0);

begin

dut: entity work.interfaz_spi(rtl)	-- Completar nombre
     port map(clk 	=> clk,  	-- in reloj de 50MHz
              nRst 	=> nRst, 	-- in reset asincrono
              CS 	=> CS,   	-- in chip select
              CL 	=> CL,   	-- in reloj del spi
              SDAT 	=> SDAT, 	-- in dato de entrada de la linea so
 	      data_out 	=> data_out,	--out buffer con los datos de la transaccion
	      ena_CS 	=> ena_CS,   	-- enable chip select
              flag_data_read => flag_data_read               
     );
timer: entity work.Timer(rtl)	-- Completar nombre
     port map(clk 	=> clk,  	-- in reloj de 50MHz
              nRst 	=> nRst, 	-- in reset asincrono
              ena_CS 	=> ena_CS,   	-- enable chip select
	      tic  	=> tic,
	      switch_P2 => switch_P2
     );

conversiones: entity work.dataToDisplay(rtl)
     port map(clk 	=> clk,  		-- in reloj de 50MHz
              nRst 	=> nRst, 		-- in reset asincrono
	      data_out 	=> data_out,
	      flag_data_read => flag_data_read,
              switch_p1 => switch_p1,
	      sgn 	=> sgn,
     	      mod_BCD 	=> mod_BCD, 
	      escala 	=> escala
     );

representacion: entity work.presentacion_temperatura(rtl)
     port map(clk 	=> clk,
     	      nRst 	=> nRst,
              tic 	=> tic,
     	      escala 	=> escala,
     	      sgn 	=> sgn,
     	      mod_BCD 	=> mod_BCD,
     	      mux_disp 	=> mux_disp,
     	      seg 	=> seg
  );
end struct;