----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Joshua Smith
-- 
-- Create Date: 02/13/2026 03:10:23 PM
-- Design Name: 
-- Module Name: clock_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_gen is
  generic(
    DataS : integer := 8;
    N1    : integer := 125000;
    N2    : integer := 41666
  );
  Port (
    iClk     : in std_logic;
    reset    : in std_logic;
    ADC      : in std_logic_vector(DataS-1 downto 0);
    oClk_Gen : out std_logic
  );
end clock_gen;

architecture Behavioral of clock_gen is

    signal N           : integer :=0;
    signal clk_cnt	   : integer range 0 to 125000;
	signal clk_en	   : std_logic;
	signal clk_gen	   : std_logic := '1';

begin

MATHULATION: process(iClk)
	 begin
	   if reset = '1' then
	       N <= 0;
	   else
           N <= 41666+((125000-41666)/255)*(255-to_integer(unsigned(ADC)));
          -- N <= 41666+((125000-41666)/255)*(255-69);
          -- N <= 41666+((125000-41666)/255)*(255-0);
       end if;
end process;

Clock_Generation: process(iClk)
	 begin
	   if rising_edge(iClk) then
	       if reset = '1' then
	           clk_cnt <= 0;
	           clk_gen <= '0';
	       else
	           if (clk_cnt = N) then
	               clk_gen <= not clk_gen;
	               clk_cnt <= 0;
	           else
	               clk_cnt <= clk_cnt +1;
	           end if;
	       end if;
       end if;
end process;

oClk_Gen <= clk_gen;

end Behavioral;
