-- Controlador de la interfaz spi  cuando ena_cs se pone a nivel alto durante un ciclo de reloj, comienza la adquisicion de datos.
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity interfaz_spi is
port(clk:	in     	std_logic;  			-- Reloj de 50MHz
     nRst:      in     	std_logic;   			-- Reset asíncrono
     CS:      	buffer  std_logic;   			-- chip select activo a nivel bajo
     CL:        buffer 	std_logic;  			-- Reloj CL de 1MHz
     SDAT: 	in     	std_logic;   			-- Dato recibido por el sensor (so)
     data_out: 	buffer 	std_logic_vector(8 downto 0); 	-- Datos recibidos para ser procesados
     ena_CS:	in 	std_logic;
     flag_data_read: buffer	    std_logic
    );
end entity;

architecture rtl of interfaz_spi is
  -- Constantes correspondientes a las especificaciones de tiempo I2C en modo FAST
  -- Reloj de 50 MHz
  constant SPI_CL:	natural := 50;			-- Valor implementado = 1us
  constant SPI_CL_L:    natural := 25;        		-- Valor implementado = 500ns
  constant SPI_CL_H:    natural := 25;        		-- Valor implementado = 500ns
  constant datos_tot:	natural := 9; 			-- Valor implementado de 9 datos a leer

  -- Cuenta para generacion de CL 
  signal cnt_SPI:	std_logic_vector(5 downto 0); 	-- Lleva la cuenta del contador del reloj
  signal cnt_9:		std_logic_vector(3 downto 0); 	-- Lleva la cuenta del contador de bits recibidos
  signal cl_aux: 	std_logic;			-- Señal que permite filtrar el reloj cd cl parafiltrarlo de glitches
  signal data_readed:    std_logic;
  signal ena_data_read: std_logic;
begin



  --Generacion de CS
  process(clk, nRst)
    begin
    if nRst = '0' then
    	CS <= '1';
  
    elsif clk'event and clk = '1' then   
	if ena_CS = '1' then 
		CS <= '0';		--Si llega la habilitacion cs a 0
	elsif data_readed = '1' then
		CS <= '1';		--permanece a 0 hasta que el dato este listo, entonces cs a 1
 
	end if;
    end if;
  end process;




  -- Generacion de CL
  process(clk, nRst)
  begin
    if nRst = '0' then
      cnt_SPI <= (0 => '1', others => '0');  		-- Reseteamos el contador a 1 por el reset asincrono
  
    elsif clk'event and clk = '1' then   		-- Contamos ticks del reloj  de 50MHz
                              
        if cnt_SPI < SPI_CL and CS='0' then  	-- Si la cuenta es menor igual que 50 y esta a nivel bajo cs
          cnt_SPI <= cnt_SPI + 1;			-- Se incrementa la cuenta a 1
     
        else
          cnt_SPI <= (0 => '1', others => '0'); 	--Si no se resetea a 1

      end if;
    end if;
  end process;

 -- Habilitacion lectura de datos
  ena_data_read <= '1' when cnt_SPI = (SPI_CL_H) else
		'0';
  -- ********************* Generacion de CL ***************************
  cl_aux <= '1' when cnt_SPI > (SPI_CL_H - 1) and cnt_SPI /=SPI_CL  else  	-- reloj spi, si la cuenta es mayor que 25 ponemos a 1 el reloj  ( de 26 a 50 ambos incluidos)
        '0';				 			   		-- Si no a 0 ( de 1 a 25, ambos incluidos)
  --*******************************************************************
  --filtrado de cl
  process(clk, nRst)
  begin
    if nRst = '0' then 
	CL <= '0';
    
    elsif clk'event and clk = '1' then
	CL <= cl_aux;
    end if;
  end process;

	
  -- Registro de desplazamiento de 9 bits, cuando el contador llega a nueve, se envia señal de que estan todos los datos
  process(clk, nRst) -- Proceso pendiene del reloj CL, del reset asíncrono y del chio select
  begin
    if nRst='0' then 
	data_out <= (others => '0'); 			-- Tras el reset asíncrono ponemos los datos a 0
	cnt_9 <= (0 => '0', others => '0');	
    
    elsif clk'event and clk='1' then 

	if ena_data_read = '1'  then	
	    data_out <= data_out (7 downto 0) & SDAT;	
			
	    if  cnt_9 < datos_tot then
               cnt_9 <= cnt_9 + 1;
           
            elsif  cnt_9 = datos_tot then 				
	       cnt_9 <= (0 => '0', others => '0');	
	
	    end if;
	elsif CS = '1'  then	
	      cnt_9 <= (0 => '0', others => '0');			
        end if;
    end if;
  end process;

--********** Generacion de señal de listo ************************************
  data_readed <= '1' when cnt_9 = datos_tot else		-- Se pone a 1 cuando la cuenta llega a 9 para indicar que han llegado 9 bits
		'0';					-- 0 en cualquier otro caso.
  flag_data_read <= data_readed;
--****************************************************************************

end rtl;