-- Test que genera, en 191 accesos a la interfaz SPI, la secuencia de datos de temperatura:
-- de 0 a +150 seguida de -40 a -1
 
-- Reloj 50 MHz
-- Es necesario completar la sentencia de emplazamiento del dut
-- El esclavo SPI funciona durante 191 accesos barriendo todas las posibles temperaturas y finalmente el mismo detiene el test

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity test_interfaz_spi is
end entity;

architecture test of test_interfaz_spi is
  signal clk:       std_logic;
  signal nRst:      std_logic;
  signal CS:        std_logic;
  signal CL:        std_logic;
  signal SDAT:      std_logic;
  signal switch_p1:   std_logic;
  signal switch_P2:   std_logic;
  signal mux_disp: std_logic_vector(4 downto 0);
  signal seg:      std_logic_vector(6 downto 0);
  constant T_clk: time := 20 ns;      

begin 
estructural: entity work.MEDT(struct)
     port map( clk           	=> clk,
    		nRst         	=> nRst,
    		switch_p1	=> switch_p1,
   		switch_P2	=> switch_P2,
    		CL		=> CL,
    		CS 		=> CS,
    		SDAT	  	=> SDAT,
    		mux_disp 	=> mux_disp,
    		seg 		=> seg
  );



slave: entity work.spi_slave(sim)
  port map(
  nRst => nRst,
  CS   => CS, 
  CL   => CL,
  Tclk => T_clk,
  SDAT => SDAT
);

process     -- Reloj
begin
  wait for T_clk/2;
    clk <= '0';

  wait for T_clk/2;
    clk <= '1';

end process;

process    -- Reset 
begin


-- proceso del test comentar y descomentar las lineas segun se quiera probar
--comprobacion de que hace los cambios bien
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait until clk'event and clk = '1';
  nRst <= '0';
  switch_p2 <= '1';
  switch_p1 <= '1';
  wait until clk'event and clk = '1';
  nRst <= '1';
-------hasta aqui modo celsius 4 segundos
-------cambiar a modo kelvin.
  wait until clk'event and clk = '1';
  switch_p1 <= '0';
  wait until clk'event and clk = '1';
  switch_p1 <= '1';
-------cambiar a modo fahrenheit.
--  wait until clk'event and clk = '1';
--  switch_p1 <= '0';
--  wait until clk'event and clk = '1';
--  switch_p1 <= '1';
------cambiar a 6s
  wait until clk'event and clk = '1';
  switch_p2 <= '0';
  wait until clk'event and clk = '1';
  switch_p2 <= '1';
------cambiar a 8s
  wait until clk'event and clk = '1';
  switch_p2 <= '0';
  wait until clk'event and clk = '1';
  switch_p2 <= '1';
------cambiar a 10s
  wait until clk'event and clk = '1';
  switch_p2 <= '0';
  wait until clk'event and clk = '1';
  switch_p2 <= '1';
------cambiar a 12s
--  wait until clk'event and clk = '1';
--  switch_p2 <= '0';
--  wait until clk'event and clk = '1';
--  switch_p2 <= '1';

  wait;
end process;

end test;

