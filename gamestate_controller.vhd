----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/05/2026 01:56:27 PM
-- Design Name: 
-- Module Name: gamestate_controller - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gamestate_controller is
    --TODO: give this a better name
    generic( clk_speed : integer := 125_000_000;
        scroll_time : integer := 1_000); -- scroll time in ms
  Port ( clk    : in std_logic;
    reset_n     : in std_logic;
    iEn         : in std_logic; -- do i need this?
    
    d           : in std_logic_vector(7 downto 0);
    gameState   : in std_logic_vector(7 downto 0);
    wins        : in std_logic_vector(15 downto 0); --should this be unsigned
    games       : in std_logic_vector(15 downto 0); --should this be unsinged
    
    q           : out std_logic_vector(7 downto 0);
    oEn         : out std_logic);
end gamestate_controller;

architecture Behavioral of gamestate_controller is

    signal uClk : std_logic := '0'; -- update clock
    signal sClk : std_logic := '0'; -- scroll clock
    
    --todo: may need to be unsigned
    signal uCnt : integer := 0;
    signal sCnt : integer := 0;
    
    --TODO: calculate the proper countmax for the above clocks
    --based on the generic clock speed value
    signal uMax : integer := 10;
    signal sMax : integer := 10;

    type charArray is array(0 to 81) of std_logic_vector(7 downto 0);
    signal newBuff : charArray;
    signal winBuff : charArray;
    signal loseBuff : charArray;
    signal gameBuff : charArray;
    
    type state is (reset, newG, play, win, loss, gameover);
    signal message_state : state := reset;
    
    -- Helper Function for Strings
    function get_char(c : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    end function;

begin
    -- "New Game?"
    newBuff <= (others => get_char(' '));
    newBuff(0) <= get_char('N');
    newBuff(1) <= get_char('e');
    newBuff(2) <= get_char('w');
    newBuff(3) <= get_char(' ');
    newBuff(4) <= get_char('G');
    newBuff(5) <= get_char('a');
    newBuff(6) <= get_char('m');
    newBuff(7) <= get_char('e');
    newBuff(8) <= get_char('?');
    
    -- "Well done! You have solved N puzzles out of M"
    winBuff <= (others => get_char(' '));
    winBuff(0) <= get_char('W'); winBuff(1) <= get_char('e'); winBuff(2) <= get_char('l');
    winBuff(3) <= get_char('l'); winBuff(4) <= get_char(' '); winBuff(5) <= get_char('d');
    winBuff(6) <= get_char('o'); winBuff(7) <= get_char('n'); winBuff(8) <= get_char('e');
    winBuff(9) <= get_char('!'); winBuff(10) <= get_char(' '); winBuff(11) <= get_char('Y');
    winBuff(12) <= get_char('o'); winBuff(13) <= get_char('u'); winBuff(14) <= get_char(' ');
    winBuff(15) <= get_char('h'); winBuff(16) <= get_char('a'); winBuff(17) <= get_char('v');
    winBuff(18) <= get_char('e'); winBuff(19) <= get_char(' '); winBuff(20) <= get_char('s');
    winBuff(21) <= get_char('o'); winBuff(22) <= get_char('l'); winBuff(23) <= get_char('v');
    winBuff(24) <= get_char('e'); winBuff(25) <= get_char('d'); winBuff(26) <= get_char(' ');
    --TODO: change this to diisplay decimal
    winBuff(27) <= wins(15 downto 8);
    winBuff(28) <= wins(7 downto 0);
    winBuff(29) <= get_char(' '); winBuff(30) <= get_char('p'); winBuff(31) <= get_char('u');
    winBuff(32) <= get_char('z'); winBuff(33) <= get_char('z'); winBuff(34) <= get_char('l');
    winBuff(35) <= get_char('e'); winBuff(36) <= get_char('s'); winBuff(37) <= get_char(' ');
    winBuff(38) <= get_char('o'); winBuff(39) <= get_char('u'); winBuff(40) <= get_char('t');
    winBuff(41) <= get_char(' '); winBuff(42) <= get_char('o'); winBuff(43) <= get_char('f');
    winBuff(44) <= get_char(' ');
    --TODO: decimal
    winBuff(45) <= games(15 downto 8);
    winBuff(46) <= games(7 downto 0);
    
    -- "Sorry! The correct word was XXXXX. You have solved N puzzles out of M"
    loseBuff <= (others => get_char(' '));
    loseBuff(0) <= get_char('S'); loseBuff(1) <= get_char('o'); loseBuff(2) <= get_char('r');
    loseBuff(3) <= get_char('r'); loseBuff(4) <= get_char('y'); loseBuff(5) <= get_char('!');
    loseBuff(6) <= get_char(' '); loseBuff(7) <= get_char('T'); loseBuff(8) <= get_char('h');
    loseBuff(9) <= get_char('e'); loseBuff(10) <= get_char(' '); loseBuff(11) <= get_char('c');
    loseBuff(12) <= get_char('o'); loseBuff(13) <= get_char('r'); loseBuff(14) <= get_char('r');
    loseBuff(15) <= get_char('e'); loseBuff(16) <= get_char('c'); loseBuff(17) <= get_char('t');
    loseBuff(18) <= get_char(' '); loseBuff(19) <= get_char('w'); loseBuff(20) <= get_char('o');
    loseBuff(21) <= get_char('r'); loseBuff(22) <= get_char('d'); loseBuff(23) <= get_char(' ');
    loseBuff(24) <= get_char('w'); loseBuff(25) <= get_char('a'); loseBuff(26) <= get_char('s');
    loseBuff(27) <= get_char(' ');
    -- TODO: how do i get the answer word in?
    loseBuff(28) <= ;
    loseBuff(29) <= ;
    loseBuff(30) <= ;
    loseBuff(31) <= ;
    loseBuff(32) <= ;
    loseBuff(33) <= ;
    loseBuff(34) <= ;
    loseBuff(35) <= ;
    loseBuff(36) <= ;
    loseBuff(37) <= ;
    loseBuff(38) <= ;
    loseBuff(39) <= ;
    loseBuff(40) <= ;
    loseBuff(41) <= ;
    loseBuff(42) <= ;
    loseBuff(43) <= ;
    loseBuff(44) <= get_char(' '); loseBuff(45) <= get_char('Y'); loseBuff(46) <= get_char('o');
    loseBuff(47) <= get_char('u'); loseBuff(48) <= get_char(' '); loseBuff(49) <= get_char('h');
    loseBuff(50) <= get_char('a'); loseBuff(51) <= get_char('v'); loseBuff(52) <= get_char('e');
    loseBuff(53) <= get_char(' '); loseBuff(54) <= get_char('s'); loseBuff(55) <= get_char('o');
    loseBuff(56) <= get_char('l'); loseBuff(57) <= get_char('v'); loseBuff(58) <= get_char('e');
    loseBuff(59) <= get_char('d'); loseBuff(60) <= get_char(' ');
    --TODO: decimal
    loseBuff(61) <= wins(15 downto 8);
    loseBuff(62) <= wins(7 downto 0);
    loseBuff(63) <= get_char(' '); loseBuff(64) <= get_char('p'); loseBuff(65) <= get_char('u');
    loseBuff(66) <= get_char('z'); loseBuff(67) <= get_char('z'); loseBuff(68) <= get_char('l');
    loseBuff(69) <= get_char('e'); loseBuff(70) <= get_char('s'); loseBuff(71) <= get_char(' ');
    loseBuff(72) <= get_char('o'); loseBuff(73) <= get_char('u'); loseBuff(74) <= get_char('t');
    loseBuff(75) <= get_char(' '); loseBuff(76) <= get_char('o'); loseBuff(77) <= get_char('f');
    loseBuff(78) <= get_char(' ');
    --TODO: decimal
    loseBuff(79) <= games(15 downto 8);
    loseBuff(80) <= games(7 downto 0);
    
    -- "GAME OVER"
    gameBuff <= (others => get_char(' '));
    gameBuff(0) <= get_char('G');
    gameBuff(1) <= get_char('A');
    gameBuff(2) <= get_char('M');
    gameBuff(3) <= get_char('E');
    gameBuff(4) <= get_char(' ');
    gameBuff(5) <= get_char('O');
    gameBuff(6) <= get_char('V');
    gameBuff(7) <= get_char('E');
    gameBuff(8) <= get_char('R');
    
    --TODO:create two clock enablers, one for updating the lcd buffer
    --the second for "scrolling" messages
    --
    -- the updating clock should be the same speed as the data in
    -- 9600?
    -- the scrolling clockk should be some slower rate for reading
    -- something like half a second
    process(clk)
    begin
        if reset_n = '0' then
            uCnt <= 0;
            uClk <= '0';
            sCnt <= 0;
            sClk <= '0';
        elsif rising_edge(clk) then
            if uCnt = uMax then
                uCnt <= 0;
                uClk <= '1';
            else
                uCnt <= uCnt + 1;
                uClk <= '0';
            end if;
            
            if sCnt = sMax then
                sCnt <= 0;
                sClk <= '1';
            else
                sCnt <= sCnt + 1;
                sClk <= '0';    
            end if;
        end if;
    end process;

    
    --TODO: state machine controlled by 'gameState' that sends
    -- 'd' and update enable signal during "normal play" states
    -- and sends the new/win/loss with the "scrolling" enable
    -- during "not-normal play" states
    --
    -- new game, normal play, win, loss, game over
    -- new game
    --  send new game 0 to 15 at update speed
    -- normal play
    --  send d at update speed
    -- win
    --  send win 0 to 15 at update speed, 
    --  send 16 to 46 at scroll speed,
    -- loss 
    --  send loss 0 to 15 at update speed,
    --  send 16 to 80 at scroll speed,
    -- game over
    --  send game over 0 to 15 at update speed
    process(clk, uClk, SClk)
    begin
        if rising_edge(clk) then
            
        end if;
    end process;


end Behavioral;
