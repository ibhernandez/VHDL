library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_unsigned.all;

entity spi_slave is port(
  nRst : in std_logic;
  CS   : in std_logic; 
  CL   : in std_logic;
  Tclk : in time;
  SDAT : buffer std_logic
);
end entity;

architecture sim of spi_slave is
signal temp: std_logic_vector(15 downto 0);
begin

process  -- Genera la secuencia de temperaturas del test
  variable t_i: std_logic_vector(15 downto 0);

begin
  wait until nRst'event and nRst = '0';
    temp <= X"0003";
    t_i := X"0003";

  wait until nRst'event and nRst = '1';

  for i in 1 to 191 loop
     wait until CS'event and CS = '0';
     wait until CS'event and CS = '1';
     if t_i(15 downto 7) /= 150 then
       t_i(15 downto 7) := t_i(15 downto 7) + 1;

     else
       t_i := X"EC03";


     end if;
     temp <= t_i;

  end loop;

  wait for 100*Tclk;

  assert false
  report "fone"
  severity failure;

end process;

process   -- Maneja SDAT
  variable dato: std_logic_vector(15 downto 0) := X"0003";

begin
  wait until CS'event and CS = '0';
    dato := temp;
    SDAT <= dato(15) after 70 ns;   
    dato := dato(14 downto 0)&'Z';

  loop
    if CS =  '0' then
      wait until (CL'event and CL = '0') or (CS'event and CS = '1');
      if CS = '0' then
        SDAT <= dato(15) after 70 ns;   
        dato := dato(14 downto 0)&'Z';

      else
        SDAT <= 'Z';
        exit;

      end if;
    end if;
  end loop;

end process;


end sim;