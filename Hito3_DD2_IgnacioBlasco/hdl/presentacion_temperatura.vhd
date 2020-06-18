library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity presentacion_temperatura is
port(clk:      in     std_logic;
     nRst:     in     std_logic;

     tic:      in     std_logic;
     
     escala:   in    std_logic_vector(1 downto 0);

     sgn:      in     std_logic;
     mod_BCD:  in     std_logic_vector(11 downto 0); 
 
     mux_disp: buffer std_logic_vector(4 downto 0);
     seg:      buffer std_logic_vector(6 downto 0)
    );          

end entity;

architecture rtl of presentacion_temperatura is
  signal cero_c:    std_logic;
  signal cero_d:    std_logic;
  signal pos_sgn_d: std_logic;
  signal pos_sgn_c: std_logic;

  signal BCD: std_logic_vector(3 downto 0);

  constant symb_grados_C: std_logic_vector(3 downto 0) := "1010";
  constant symb_grados_k: std_logic_vector(3 downto 0) := "1011";
  constant symb_grados_f: std_logic_vector(3 downto 0) := "1100";
  constant symb_menos:    std_logic_vector(3 downto 0) := "1110";
  constant symb_apagado:  std_logic_vector(3 downto 0) := "1111";

begin
  -- Control multiplexacion de displays

  process(clk, nRst)
  begin
    if nRst = '0' then
      mux_disp <= (0 => '0', others => '1');

    elsif clk'event and clk = '1' then
      if tic = '1' then      
        mux_disp <= mux_disp(3 downto 0)&mux_disp(4);

      end if;
    end if;
  end process;


  -- Eliminacion de ceros no significativos
     cero_c <= '1' when mod_BCD(11 downto 8) = 0 else
               '0';
     cero_d <= cero_c when mod_BCD(7 downto 4) = 0 else                         
               '0';                                                              

  -- Posicion del signo (en disp de centenas o de decenas)
     pos_sgn_d <= sgn when cero_d =  '1'  else
                  '0';
     pos_sgn_c <= sgn when cero_d =  '0'  else
                  '0';

  -- Mux decodificador BCD-7seg
  BCD <= symb_grados_C         when escala = 1 and mux_disp = 30  else
         symb_grados_k         when escala = 2 and mux_disp = 30  else
         symb_grados_f         when escala = 3 and mux_disp = 30  else

         mod_BCD(3 downto 0)   when                mux_disp = 27  else

         mod_BCD(7 downto 4)   when cero_d    = '0' and mux_disp = 23  else
         symb_menos            when pos_sgn_d = '1' and mux_disp = 23  else -- error. cambiada con la de abajo
         symb_apagado          when cero_d    = '1' and mux_disp = 23  else

         mod_BCD(11 downto 8)  when cero_c    = '0' and mux_disp = 15 else
         symb_menos            when pos_sgn_c = '1' and mux_disp = 15 else  -- error. cambiada con la de abajo
         symb_apagado          when cero_c    = '1' and mux_disp = 15 else

         symb_apagado;
                                          
  -- Decodificador BCD (ampliado) a 7 segmentos: salidas activas a nivel alto
  process(BCD)
  begin
    case BCD is            --abcdefg
      when "0000" => seg <= "1111110"; -- 0 
      when "0001" => seg <= "0110000"; -- 1
      when "0010" => seg <= "1101101"; -- 2 
      when "0011" => seg <= "1111001"; -- 3
      when "0100" => seg <= "0110011"; -- 4
      when "0101" => seg <= "1011011"; -- 5
      when "0110" => seg <= "1011111"; -- 6
      when "0111" => seg <= "1110000"; -- 7
      when "1000" => seg <= "1111111"; -- 8
      when "1001" => seg <= "1110011"; -- 9
      when "1010" => seg <= "0001101"; -- Grados (c)
      when "1011" => seg <= "1100011"; -- Grados (k)
      when "1100" => seg <= "1000111"; -- Grados (f)
      when "1110" => seg <= "0000001"; -- sgn - 
      when "1111" => seg <= "0000000"; -- Apagado
      when others => seg <= "XXXXXXX";
  
    end case;
  end process;
end rtl;  
  