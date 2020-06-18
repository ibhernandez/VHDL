
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; 
entity Timer is
port(clk:	in     	std_logic;  			-- Reloj de 50MHz
     nRst:      in     	std_logic;   			-- Reset asíncrono
     ena_CS:    buffer  std_logic;   			-- chip select activo a nivel bajo
     switch_P2: in 	std_logic;
     tic:  	buffer  std_logic
    );
end entity;

architecture rtl of Timer is
  --Señales y constantes para la generacion del tick de 2.5ms
  constant fin_tick_2m5:	natural :=125000;--escalado a 0.2us 2.5s =125000;
signal contador_2m5: std_logic_vector (16 downto 0) ;
  --Señales y constantes para la generacion de ena_CS
  signal contador: std_logic_vector (12 downto 0) ;
  signal seleccion_tiempo: std_logic_vector(2 downto 0);
  signal fin_cnt: std_logic_vector(12 downto 0);	
  constant s4:	natural := 1600;	
  constant s6:	natural := 2400;	
  constant s8:	natural := 3200;	
  constant s10:	natural := 4000;	
  constant s12:	natural := 4800;	

  --señales para el pulsador 2
  signal switch_p2_T1: std_logic;                   -- estado del switch en t1
  signal switch_p2_T2: std_logic;                   -- estado del switch en t2
  signal pulsacion: 	std_logic; 
begin

--Generacion del tick de  2.5ms
  process(clk, nRst)
  begin
    if nRst = '0' then
      contador_2m5 <=  (0 => '1', others => '0');
  
    elsif clk'event and clk = '1' then   		-- Contamos ticks del reloj  de 50MHz
      if contador_2m5 < fin_tick_2m5 then
        contador_2m5 <= contador_2m5 +'1';
      else
	contador_2m5 <=  (0 => '1', others => '0');

      end if;
    end if;
  end process;

 tic <= '1' when contador_2m5 = fin_tick_2m5 else
	'0';




--Registro de las pulsaciones del switch
  process(clk, nRst)
  begin
    if nRst = '0' then
      switch_p2_T1 <= '0';    
      switch_p2_T2 <= '0';		
			
    elsif clk = '1' and clk'event then
      switch_p2_T1 <= switch_P2;	--registro de la pulsacion
      switch_p2_T2 <= switch_p2_T1;	--actualizacion del instante anterior

    end if;
  end process;
  pulsacion <= '1' when switch_p2_T2 = '1' and switch_p2_T1= '0' else --
	       '0';

--actualizacion del tiempo de refresco
  process(clk, nRst)
  begin
    if nRst = '0' then
      seleccion_tiempo <= (others => '0'); 	
        
    elsif clk = '1' and clk'event then
      if  pulsacion = '1'  then			--entrada de habilitacion del sumador
        if  seleccion_tiempo = 4 then			--si estado vale 2, vuelve a 0, si no se suma 1
 	  seleccion_tiempo <= (others => '0');
     
        else
	  seleccion_tiempo <= seleccion_tiempo + 1; 
	
	end if;
      end if;
    end if;
  end process;

--Actualizacion del fin de cuenta
fin_cnt <= "0000000000000" + S4  when seleccion_tiempo = 0 else
	   "0000000000000" + S6  when seleccion_tiempo = 1 else
           "0000000000000" + S8  when seleccion_tiempo = 2 else
           "0000000000000" + S10 when seleccion_tiempo = 3 else
	   "0000000000000" + S12;

-- Generacion de ena_CL
  process(clk, nRst)
  begin
    if nRst = '0' then
      contador <= (0 => '1', others => '0');
  
    elsif clk'event and clk = '1' then   		-- Contamos ticks del reloj  de 50MHz
      if tic ='1' then  
        if contador < fin_cnt then
          contador <= contador +'1';

        else
	  contador <= (0 => '1', others => '0');

        end if;
      end if;
    end if;
  end process;

 ena_CS <= '1' when contador = fin_cnt else
	'0';
 
end rtl;