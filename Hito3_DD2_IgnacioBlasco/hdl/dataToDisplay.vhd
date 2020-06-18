library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dataToDisplay is
port(clk:	  in    std_logic;  			-- Reloj de 50MHz
     nRst:        in    std_logic;   			-- Reset asíncrono
     data_out:	in 	std_logic_vector( 8 downto 0);  -- temperatura en c2
     flag_data_read: in	std_logic;			-- a 1 cuando el dato esta listo para ser convertido
     switch_p1 :  in	std_logic;                      -- pulsador 1
     mod_BCD: buffer  std_logic_vector( 11 downto 0);  -- numero a mostrar en bcd
     sgn: buffer std_logic;				-- signo del numero a mostrar 
     escala: buffer std_logic_vector(1 downto 0)

    );
end entity;

architecture rtl of dataToDisplay is
  signal switch_p1_T1: std_logic;                   -- estado del switch en t1
  signal switch_p1_T2: std_logic;                   -- estado del switch en t2
  signal num_bin: std_logic_vector(8 downto 0);      -- numero en binario natural (modulo)
  signal num_bin_decenas: std_logic_vector(8 downto 0);  -- señal con las decenas y undidades del numero en binario natural
  signal num_bin_unidades: std_logic_vector(8 downto 0); -- señal con las unidades del numero en binario natural
--señales apra las conversiones
  signal data_fheit_aux: std_logic_vector( 15 downto 0);	-- señal para realizar la conversiona fahrenheit
  signal data_kelvin: 	std_logic_vector( 11 downto 0);	-- temperatura en kelvin
  signal data_fheit:  	std_logic_vector( 11 downto 0);	-- temperatura en fahrenheit
  signal data_cels:   	std_logic_vector( 8 downto 0); 	-- temperatura en celsius
  signal pulsacion: 	std_logic; 
  begin
--------Proceso que registra las pulsaciones del switch
 
  process(clk, nRst)
  begin
    if nRst = '0' then
      switch_p1_T1 <= '0';    --reset asincono de las señales
      switch_p1_T2 <= '0';		
			
    elsif clk = '1' and clk'event then
      switch_p1_T1 <= switch_p1;		--registramos la señal 
      switch_p1_T2 <= switch_p1_T1;	--actualizamos el instante anterior

    end if;
  end process;
  pulsacion <= '1' when switch_p1_T2 = '1' and switch_p1_T1= '0' else --
	       '0';

--sumador de modulo 3, cuando el estado esta a 1 la temperatura se representa en celsius, cuando esta a 2 en kelvin y cuando esta a 3 es fahrenheit
  process(clk, nRst)
  begin
    if nRst = '0' then
      escala <=  (0 => '1', others => '0'); 	
        
    elsif clk = '1' and clk'event then
      if  pulsacion = '1'  then			--entrada de habilitacion del sumador
        if  escala = 3 then			--si estado vale 2, vuelve a 0, si no se suma 1
 	  escala <=  (0 => '1', others => '0');
     
        else
	  escala <= escala + 1; 
	end if;
      end if;
    end if;
  end process;
  
--registro de la temperatura en celsius
  process(clk, nRst)
  begin
    if nRst = '0' then
      data_cels <= (others => '0'); 	-- estado controla que se va a mostrar si celsius, kelvin o fahrenheit
        
    elsif clk = '1' and clk'event then
      if  flag_data_read = '1'  then	-- si ahora vale 1 y antes 0, entonces cambio estado
        data_cels <= data_out;

      end if;
    end if;
  end process;

--obtencion de las conversiones
  data_kelvin <=   data_cels(8)&data_cels(8)&data_cels(8)&data_cels + 273; --Extiende con signo y suma 273

  data_fheit_aux <= (data_cels(8)&data_cels(8)&data_cels(8)&data_cels&"0000") --Multiplica el numero x1 y se suma al resto
		+ (data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels&"000") --Multiplica el numero x0.5 y se suma al resto
		+ (data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels&"00")--Multiplica el numero x0.25 y se suma al resto
  		+ (data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels(8)&data_cels); --Multiplica el numero x0.0625 y suma al resto

--Con esta sentencia quito los decimales y sumo 32, redondeando al entero mas proximo.
  data_fheit <= data_fheit_aux (15 downto 4) +32 when data_fheit_aux (3) = '0' else 	-- Si el bit 3 (2^-1=0.5) esta a 0 entonces se queda tal cual (suma 32)
	        data_fheit_aux (15 downto 4) + 33;					-- Si el bit esta a 1, redondeo al entero mas proximo. (suma 32 +1)



---------Obtencion del signo
  sgn <= '1' when (escala=1 and data_cels(8) ='1') or (escala=2 and data_kelvin(11) ='1') or (escala=3 and data_fheit(11) ='1') else
	 '0';

--------Proceso para pasar los datos de c2  a binario natural
  num_bin <= data_cels 			   when escala=1 and sgn = '0' else
          not(data_cels-1)     		   when escala=1 and sgn = '1' else
          data_kelvin(8 downto 0) 	   when escala=2 and sgn = '0' else
          not(data_kelvin(8 downto 0)-1)   when escala=2 and sgn = '1' else
          data_fheit(8 downto 0)	   when escala =3 and sgn ='0' else
          not (data_fheit (8 downto 0) -1) when escala=3 and sgn ='1'  else
          (others => '0');


------Pasar el modulo del numero(num_bin en binario natural) a BCD 
--obtencion de las centenas
  mod_BCD(11 downto 8) <= "0001" when num_bin >=100  and num_bin <200 else
		   		"0010"   when num_bin >=200  and num_bin <300 else
		   		"0011" 	 when num_bin >=300  and num_bin <400 else     
		  		"0100" 	 when num_bin >=400  and num_bin <500 else 
		  		"0000";  --apagado

--recalculo para las decenas (numero binario-centenas)
  num_bin_decenas <=  (num_bin(8 downto 0) - ((mod_BCD(10 downto 8)&"000000") + ('0'&mod_BCD(10 downto 8)&"00000") + ("0000"&mod_BCD(10 downto 8)&"00"))) ;

--obtencion de decenas
  mod_BCD(7 downto 4) <= "0000"+ 1 when (num_bin_decenas >=10  and num_bin_decenas <20) else
		   		 "0000"+2  when (num_bin_decenas >=20  and num_bin_decenas <30) else
		   		 "0000"+3  when (num_bin_decenas >=30  and num_bin_decenas <40) else    
		  		 "0000"+4  when (num_bin_decenas >=40  and num_bin_decenas <50) else
		  		 "0000"+5  when (num_bin_decenas >=50  and num_bin_decenas <60) else
		  		 "0000"+6  when (num_bin_decenas >=60  and num_bin_decenas <70) else
		  		 "0000"+7  when (num_bin_decenas >=70  and num_bin_decenas <80) else
		  		 "0000"+8  when (num_bin_decenas >=80  and num_bin_decenas <90) else
		  		 "0000"+9  when (num_bin_decenas >=90  and num_bin_decenas <100) else
		  		 "0000"; --apagado

--recalculo para las unidades (numero en binario - centenas del numero - decenas del numero)
  num_bin_unidades <=  (num_bin_decenas(8 downto 0) - (("00"&mod_BCD(7 downto 4) & "000") +  ("0000"&mod_BCD(7 downto 4)&"0"))) ;

--obtencion de unidades
  mod_BCD(3 downto 0) <=  "0000"+1 when num_bin_unidades = 1  else
		   		  "0000"+2 when num_bin_unidades = 2  else
		   		  "0000"+3 when num_bin_unidades = 3  else    
		  		  "0000"+4 when num_bin_unidades = 4  else
		  		  "0000"+5 when num_bin_unidades = 5  else
		  		  "0000"+6 when num_bin_unidades = 6  else
		  		  "0000"+7 when num_bin_unidades = 7  else
		  		  "0000"+8 when num_bin_unidades = 8  else
		  		  "0000"+9 when num_bin_unidades = 9  else
		  		  "0000"+0;

end rtl;




