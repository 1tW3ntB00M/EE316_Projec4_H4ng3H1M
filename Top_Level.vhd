library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
        led0_g              : out std_logic;
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
    signal ascii_new         : std_logic;
    signal ld_tx_data        : std_logic;
    signal uld_rx_data        : std_logic;







begin

Reset_Master <= Reset_o or iReset;
led0_g       <= ascii_new;
led1_g       <= Reset_Master;


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

inst_ps2_keyboard_to_ascii : entity work.ps2_keyboard_to_ascii
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

--inst_uart : entity work.uart
--        port map (
--            reset           =>   Reset_Master,
--            txclk           =>   iClk,
--            ld_tx_data      =>   ld_tx_data,
--            tx_data         =>   ascii_code,
--            tx_enable       =>   ascii_new,
--            tx_out          =>   open,
--            tx_empty        =>   open,
--            rxclk           =>   iClk,
--            uld_rx_data     =>   uld_rx_data,
--            rx_data         =>   open,
--            rx_enable       =>   open,
--            rx_in           =>   open,
--            rx_empty        =>   open    
--        );





end Structural;