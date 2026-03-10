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
    
    --TODO: what size is this
    d           : in std_logic_vector(7 downto 0);
   
    oGs         : out unsigned(3 downto 0); 
    q           : out std_logic_vector(127 downto 0);
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
    signal sMax : integer := (scroll_time*(10**(-3)))*clk_speed;

    type byteArray is array(0 to 20) of std_logic_vector(7 downto 0);
    signal regBuff : byteArray;

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
    
    signal n : integer := 0;

begin
    --TODO: make a buffer of shif registers to hold
    --the hidden word, win/loss, and gamestate data
    --from uart rx
    --
    --use the literal gamestate data to control the 
    --state machine 
    --pipe the hidden word buffer directly out to the LCD controller
    --during "normal play"
    --use this buffer to complete the loss game state output message

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
    winBuff(27) <= regBuff(16);
    winBuff(28) <= regBuff(17);
    winBuff(29) <= get_char(' '); winBuff(30) <= get_char('p'); winBuff(31) <= get_char('u');
    winBuff(32) <= get_char('z'); winBuff(33) <= get_char('z'); winBuff(34) <= get_char('l');
    winBuff(35) <= get_char('e'); winBuff(36) <= get_char('s'); winBuff(37) <= get_char(' ');
    winBuff(38) <= get_char('o'); winBuff(39) <= get_char('u'); winBuff(40) <= get_char('t');
    winBuff(41) <= get_char(' '); winBuff(42) <= get_char('o'); winBuff(43) <= get_char('f');
    winBuff(44) <= get_char(' ');
    --TODO: decimal
    winBuff(45) <= regBuff(18);
    winBuff(46) <= regBuff(19);
    
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
    --TODO: this may be backwards, fix afterward
    loseBuff(28) <= regBuff(0);
    loseBuff(29) <= regBuff(1);
    loseBuff(30) <= regBuff(2);
    loseBuff(31) <= regBuff(3);
    loseBuff(32) <= regBuff(4);
    loseBuff(33) <= regBuff(5);
    loseBuff(34) <= regBuff(6);
    loseBuff(35) <= regBuff(7);
    loseBuff(36) <= regBuff(8);
    loseBuff(37) <= regBuff(9);
    loseBuff(38) <= regBuff(10);
    loseBuff(39) <= regBuff(11);
    loseBuff(40) <= regBuff(12);
    loseBuff(41) <= regBuff(13);
    loseBuff(42) <= regBuff(14);
    loseBuff(43) <= regBuff(15);
    loseBuff(44) <= get_char(' '); loseBuff(45) <= get_char('Y'); loseBuff(46) <= get_char('o');
    loseBuff(47) <= get_char('u'); loseBuff(48) <= get_char(' '); loseBuff(49) <= get_char('h');
    loseBuff(50) <= get_char('a'); loseBuff(51) <= get_char('v'); loseBuff(52) <= get_char('e');
    loseBuff(53) <= get_char(' '); loseBuff(54) <= get_char('s'); loseBuff(55) <= get_char('o');
    loseBuff(56) <= get_char('l'); loseBuff(57) <= get_char('v'); loseBuff(58) <= get_char('e');
    loseBuff(59) <= get_char('d'); loseBuff(60) <= get_char(' ');
    --TODO: decimal
    loseBuff(61) <= regBuff(16);
    loseBuff(62) <= regBuff(17);
    loseBuff(63) <= get_char(' '); loseBuff(64) <= get_char('p'); loseBuff(65) <= get_char('u');
    loseBuff(66) <= get_char('z'); loseBuff(67) <= get_char('z'); loseBuff(68) <= get_char('l');
    loseBuff(69) <= get_char('e'); loseBuff(70) <= get_char('s'); loseBuff(71) <= get_char(' ');
    loseBuff(72) <= get_char('o'); loseBuff(73) <= get_char('u'); loseBuff(74) <= get_char('t');
    loseBuff(75) <= get_char(' '); loseBuff(76) <= get_char('o'); loseBuff(77) <= get_char('f');
    loseBuff(78) <= get_char(' ');
    --TODO: decimal
    loseBuff(79) <= regBuff(18);
    loseBuff(80) <= regBuff(19);
    
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
    
    process(clk)
    begin --TODO: this may be backwards
        if rising_edge(clk) and iEn = '1' then
            regBuff(0)  <= regBuff(1);
            regBuff(1)  <= regBuff(2);
            regBuff(2)  <= regBuff(3); 
            regBuff(3)  <= regBuff(4); 
            regBuff(4)  <= regBuff(5); 
            regBuff(5)  <= regBuff(6); 
            regBuff(6)  <= regBuff(7); 
            regBuff(7)  <= regBuff(8); 
            regBuff(8)  <= regBuff(9); 
            regBuff(9)  <= regBuff(10);
            regBuff(10) <= regBuff(11);
            regBuff(11) <= regBuff(12);
            regBuff(12) <= regBuff(13);
            regBuff(13) <= regBuff(14);
            regBuff(14) <= regBuff(15);
            regBuff(15) <= regBuff(16);
            regBuff(16) <= regBuff(17);
            regBuff(17) <= regBuff(18);
            regBuff(18) <= regBuff(19);
            regBuff(19) <= regBuff(20);
            regBuff(20) <= d;
        end if;
    end process;
    
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
            case regBuff(20) is
                when x"00" => --new game
                    q(127 downto 120) <= newBuff(0);
                    q(119 downto 112) <= newBuff(1);
                    q(111 downto 104) <= newBuff(2);
                    q(103 downto 96) <= newBuff(3);
                    q(95 downto 88) <= newBuff(4);
                    q(87 downto 80) <= newBuff(5);
                    q(79 downto 72) <= newBuff(6);
                    q(71 downto 64) <= newBuff(7);
                    q(63 downto 56) <= newBuff(8);
                    q(55 downto 48) <= newBuff(9);
                    q(47 downto 40) <= newBuff(10);
                    q(39 downto 32) <= newBuff(11);
                    q(31 downto 24) <= newBuff(12);
                    q(23 downto 16) <= newBuff(13);
                    q(15 downto 8) <= newBuff(14);
                    q(7 downto 0) <= newBuff(15);
                    oGs <= X"6";
                    n <= 0;
                when x"01" => --normal play
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"5";
                when x"02" => --TODO: ther must be a better way to do this?
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"4";
                when x"03" =>
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"3";
                when x"04" =>
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"2";
                when x"05" =>
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"1";
                when x"06" =>
                    q(127 downto 120) <= regBuff(0);
                    q(119 downto 112) <= regBuff(1);
                    q(111 downto 104) <= regBuff(2);
                    q(103 downto 96) <= regBuff(3);
                    q(95 downto 88) <= regBuff(4);
                    q(87 downto 80) <= regBuff(5);
                    q(79 downto 72) <= regBuff(6);
                    q(71 downto 64) <= regBuff(7);
                    q(63 downto 56) <= regBuff(8);
                    q(55 downto 48) <= regBuff(9);
                    q(47 downto 40) <= regBuff(10);
                    q(39 downto 32) <= regBuff(11);
                    q(31 downto 24) <= regBuff(12);
                    q(23 downto 16) <= regBuff(13);
                    q(15 downto 8) <= regBuff(14);
                    q(7 downto 0) <= regBuff(15);
                    oGs <= x"0";
                when x"07" => --win
                    --TODO: more than 16 characters, need to scroll
                    q(127 downto 120)   <= winBuff(n + 0);
                    q(119 downto 112)   <= winBuff(n + 1);
                    q(111 downto 104)   <= winBuff(n + 2);
                    q(103 downto 96)    <= winBuff(n + 3);
                    q(95 downto 88)     <= winBuff(n + 4);
                    q(87 downto 80)     <= winBuff(n + 5);
                    q(79 downto 72)     <= winBuff(n + 6);
                    q(71 downto 64)     <= winBuff(n + 7);
                    q(63 downto 56)     <= winBuff(n + 8);
                    q(55 downto 48)     <= winBuff(n + 9);
                    q(47 downto 40)     <= winBuff(n + 10);
                    q(39 downto 32)     <= winBuff(n + 11);
                    q(31 downto 24)     <= winBuff(n + 12);
                    q(23 downto 16)     <= winBuff(n + 13);
                    q(15 downto 8)      <= winBuff(n + 14);
                    q(7 downto 0)       <= winBuff(n + 15);
                    
                    if rising_edge(sClk) and n /= 31 then
                        n <= n + 1;
                    elsif n = 31 then
                        --tODO: what do i do here
                    end if;                    
                when x"08" => --loss
                    --TODO: more than 16 characters, need to scroll
                    q(127 downto 120)   <= loseBuff(n + 0);
                    q(119 downto 112)   <= loseBuff(n + 1);
                    q(111 downto 104)   <= loseBuff(n + 2);
                    q(103 downto 96)    <= loseBuff(n + 3);
                    q(95 downto 88)     <= loseBuff(n + 4);
                    q(87 downto 80)     <= loseBuff(n + 5);
                    q(79 downto 72)     <= loseBuff(n + 6);
                    q(71 downto 64)     <= loseBuff(n + 7);
                    q(63 downto 56)     <= loseBuff(n + 8);
                    q(55 downto 48)     <= loseBuff(n + 9);
                    q(47 downto 40)     <= loseBuff(n + 10);
                    q(39 downto 32)     <= loseBuff(n + 11);
                    q(31 downto 24)     <= loseBuff(n + 12);
                    q(23 downto 16)     <= loseBuff(n + 13);
                    q(15 downto 8)      <= loseBuff(n + 14);
                    q(7 downto 0)       <= loseBuff(n + 15);
                    
                    if rising_edge(sClk) and n /= 31 then
                        n <= n + 1;
                    elsif n = 31 then
                        --tODO: what do i do here
                    end if; --TODO: more than 16 characters, need to scroll
                when x"09" => --game over
                    q(127 downto 120)   <= gameBuff(0);
                    q(119 downto 112)   <= gameBuff(1);
                    q(111 downto 104)   <= gameBuff(2);
                    q(103 downto 96)    <= gameBuff(3);
                    q(95 downto 88)     <= gameBuff(4);
                    q(87 downto 80)     <= gameBuff(5);
                    q(79 downto 72)     <= gameBuff(6);
                    q(71 downto 64)     <= gameBuff(7);
                    q(63 downto 56)     <= gameBuff(8);
                    q(55 downto 48)     <= gameBuff(9);
                    q(47 downto 40)     <= gameBuff(10);
                    q(39 downto 32)     <= gameBuff(11);
                    q(31 downto 24)     <= gameBuff(12);
                    q(23 downto 16)     <= gameBuff(13);
                    q(15 downto 8)      <= gameBuff(14);
                    q(7 downto 0)       <= gameBuff(15);
                    n <= 0;
                when others =>
                    n <= 0;
                    oGs <= x"f";
            end case;
        end if;
    end process;
end Behavioral;
