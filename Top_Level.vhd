library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity Top_Level is
        port (
        btn0              : in std_logic; 
        iClk                : in std_logic;
        
        PS2_Clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
        PS2_Data   : IN  STD_LOGIC;   
        -- LCD I2C
        LCD_SDA             : inout std_logic;
        LCD_SCL             : inout std_logic;
        
        -- On board LEDS
        led0_g              : out std_logic := '0';
        led1_g              : out std_logic;
    
        UART_RX             : in std_logic;
        UART_TX             : out std_logic
        
--        LED0                   : out std_logic;
--        LED1                    : out std_logic;
--        LED2                    : out std_logic;
--        LED3                    : out std_logic
        );
end Top_Level;

architecture Structural of Top_Level is

-------------------------------------------------------------------------------------------------

    component lcd_controller is
        Port (
            clk         : in STD_LOGIC; -- 125 MHz System Clock
            reset_n     : in std_logic;
            d           : in std_logic_vector(6 downto 0); -- input character
            e_n         : in std_logic; -- enable signal, (next character) 
            ck_scl      : inout STD_LOGIC;
            ck_sda      : inout STD_LOGIC
        );
    end component;

-------------------------------------------------------------------------------------------------

component btn_debounce_toggle is
	generic ( CNTR_MAX: STD_LOGIC_VECTOR(15 downto 0) := X"FFFF"); 
    Port ( BTN_I 		: in   STD_LOGIC;
           CLK 			: in   STD_LOGIC;
           BTN_O 		: out  STD_LOGIC;
           TOGGLE_O	   	: out  STD_LOGIC;
		   PULSE_O 		: out  STD_LOGIC);
	end component;

-------------------------------------------------------------------------------------------------

component ps2_keyboard_to_ascii is
GENERIC(
      clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
        Port (
            clk        : IN  STD_LOGIC;                     --system clock input
            ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
            ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
            ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
            ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    end component;

-------------------------------------------------------------------------------------------------


component Reset_Delay is
        Port (
            iCLK        : IN  STD_LOGIC;                     --system clock input
            oRESET      : OUT  STD_LOGIC                    --clock signal from PS2 keyboard
            
        );
    end component;

-------------------------------------------------------------------------------------------------
        
 component clock_div is
  generic(
    clock     : integer := 125;  --The internal board clock rate in MHz
    Baud_rate : integer := 9600; --The baud rate you want to hit
    Bytes     : integer := 16    --The number of byts you want to send
  );
  Port (
    iClk        : in std_logic;
    reset       : in std_logic;
    oTX_Clk_Div : out std_logic;
    oRX_Clk_Div : out std_logic
  );
end component;

-------------------------------------------------------------------------------------------------

component uart is
        Port (
            reset       :in  std_logic;
            txclk       :in  std_logic;
            ld_tx_data  :in  std_logic;
            tx_data     :in  std_logic_vector (7 downto 0);
            tx_enable   :in  std_logic;
            tx_out      :out std_logic;
            tx_empty    :out std_logic;
            rxclk       :in  std_logic;
            uld_rx_data :in  std_logic;
            rx_data     :out std_logic_vector (7 downto 0);
            rx_enable   :in  std_logic;
            rx_in       :in  std_logic;
            rx_empty    :out std_logic
        );
    end component;

-------------------------------------------------------------------------------------------------



    -- ==========================================
    -- INTERNAL SIGNALS
    -- ==========================================
    
    
   
    --signal EightBitDataFromADC  : std_logic_vector (7 downto 0);
    signal btn0_o            : std_logic;
    signal Reset_o           : std_logic;
    signal Reset_Master      : std_logic;
    signal iReset            : std_logic;
    signal ascii_code        : std_logic_VECTOR(6 DOWNTO 0);
    signal ascii_code8       : std_logic_VECTOR(7 DOWNTO 0);
    signal rx_data           : std_logic_Vector(7 downto 0);
    signal ascii_new         : std_logic;
    signal ld_tx_data        : std_logic;
    signal uld_rx_data       : std_logic;
    signal rx_enable         : std_logic;
    signal rx_in             : std_logic;
    signal TX_Clk            : std_logic;
    signal RX_Clk            : std_logic;
    signal ascii_new_pulse   : std_logic;
    signal pulseCounter      : unsigned(7 downto 0) := X"00";
    signal tenPulse     : std_logic := '0';
    signal tempPulse    : std_logic := '0';
    signal tx_empty     : std_logic;
    signal Q0, Q1       : std_logic;
begin

Reset_Master <= Reset_o or iReset;
led0_g       <= tempPulse;
led1_g       <= Reset_Master;
ascii_code8  <= '0' & ascii_code;

--process(tx_clk, ascii_new_pulse)
--begin
--    if rising_edge(ascii_new_pulse) then
--            pulseCounter <= x"00";
--    end if;

--    if rising_edge(tx_clk) then
--        if pulseCounter /= x"09" then
--            pulseCounter <= pulseCounter + 1;
--            tenPulse <= '1';
--        else
--            tenPulse <= '0';
--        end if;
--    end if;
--end process;

--process(tx_empty, ascii_new_pulse)
--begin
--    if rising_edge(ascii_new_pulse) then
--        tempPulse <= '1';
--    end if;
    
--    if falling_edge(tx_empty) then
--        tempPulse <= '0';
--    end if;
--end process;

process(iclk, ascii_new)
begin
        if rising_edge(ascii_new) and tx_empty = '1' then
            tempPulse <= '1';
        end if;
        
        if tx_empty = '0' then
            tempPulse <= '0';
        end if;
end process;



    -- ==========================================
    -- Port Maping
    -- ==========================================
  
    inst_lcd_controller : lcd_controller
        port map(
            clk        => iClk,
            reset_n    => Reset_Master,
            d          => ascii_code,
            e_n        => '1' ,
            ck_scl     => LCD_SCL,
            ck_sda     => LCD_SDA
        );

 -------------------------------------------------------------------------------------------------

   
        debounce_bnt0 : entity work.btn_debounce_toggle
        generic map ( CNTR_MAX => X"0FFF" )
        port map (
            BTN_I    => btn0,
            CLK      => iClk,
            BTN_O    => iReset,
            TOGGLE_O => open,
            PULSE_O  => open
        );

 -------------------------------------------------------------------------------------------------

   
--        debounce_PS2_Clk : entity work.btn_debounce_toggle
--        generic map ( CNTR_MAX => X"0FFF" )
--        port map (
--            BTN_I    => ascii_new,
--            CLK      => tx_clk,
--            BTN_O    => open,
--            TOGGLE_O => open,
--            PULSE_O  => ascii_new_pulse
--        );


	btn_toggle_process : process(tx_clk)
	begin
		if (rising_edge(tx_clk)) then
			Q0 <= ascii_new;
			Q1 <= Q0;
			ascii_new_pulse   <= not Q1 and Q0;
		end if;
	end process;


 -------------------------------------------------------------------------------------------------

inst_ps2_keyboard_to_ascii : entity work.ps2_keyboard_to_ascii
GENERIC map(
      clk_freq                  => 125_000_000, --system clock frequency in Hz
      ps2_debounce_counter_size => 9)         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
        port map (
            clk          => iClk,
            ps2_clk      => PS2_Clk,
            ps2_data     => PS2_Data,
            ascii_new    => ascii_new,
            ascii_code  => ascii_code
        );
   
 -------------------------------------------------------------------------------------------------

inst_Reset_Delay : entity work.Reset_Delay
        port map (
            iCLK    => iClk,
            oRESET  => Reset_o
        );
        

 -------------------------------------------------------------------------------------------------

inst_CLK_div_Uart : entity work.clock_div
  generic map(
    clock     => 125,  --The internal board clock rate in MHz
    Baud_rate => 9600, --The baud rate you want to hit
    Bytes     => 16    --The number of byts you want to send
  )
  Port map(
    iClk        => iClk,
    reset       => Reset_Master,
    oTX_Clk_Div => TX_Clk,
    oRX_Clk_Div => RX_Clk
  );

-------------------------------------------------------------------------------------------------

inst_uart : entity work.uart
        port map (
            reset           =>   Reset_Master,
            txclk           =>   TX_Clk,
            ld_tx_data      =>   ascii_new_pulse, --- '1'
            tx_data         =>   ascii_code8,
            tx_enable       =>   '1', ----ascii_new_pulse
            tx_out          =>   UART_TX,    --The Pin to TX
            tx_empty        =>   tx_empty,
            rxclk           =>   RX_Clk,
            uld_rx_data     =>   uld_rx_data,
            rx_data         =>   rx_data,
            rx_enable       =>   rx_enable,
            rx_in           =>   rx_in,
            rx_empty        =>   open    
        );


end Structural;