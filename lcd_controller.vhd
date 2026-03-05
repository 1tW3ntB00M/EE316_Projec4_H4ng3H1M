library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_controller is
    Port ( 
        clk         : in STD_LOGIC; -- 125 MHz System Clock
        reset_n     : in std_logic;
        d           : in std_logic_vector(7 downto 0); -- input character
        e_n         : in std_logic; -- enable signal, (next character) 
        
        -- ChipKit I2C
        ck_scl      : inout STD_LOGIC;
        ck_sda      : inout STD_LOGIC
    );
end lcd_controller;

architecture Behavioral of lcd_controller is

    -- I2C Addresses
    --constant ADDR_ADC : std_logic_vector(6 downto 0) := "1001000"; -- 0x48 PCF8591
    constant ADDR_LCD : std_logic_vector(6 downto 0) := "0100111"; -- 0x27 PCF8574

    -- Timing Constants (based on 125MHz clock)
    constant TIME_40MS : integer := 5_000_000;
    constant TIME_2MS  : integer := 250_000;
    
    --TODO: dont use?
    -- Inputs
    signal btn_reset  : std_logic;
    signal btn_raw    : std_logic_vector(3 downto 0);
    signal btn_pulsed : std_logic_vector(3 downto 0);
    
    -- I2C Master Signals
    signal i2c_ena     : std_logic := '0';
    signal i2c_addr    : std_logic_vector(6 downto 0);
    signal i2c_rw      : std_logic := '0'; -- '0' Write, '1' Read
    signal i2c_data_wr : std_logic_vector(7 downto 0);
    signal i2c_busy    : std_logic;
    signal i2c_data_rd : std_logic_vector(7 downto 0);
    signal i2c_ack_err : std_logic;

--TODO: dont use
    -- Application Signals
    signal pwm_duty_val   : std_logic_vector(7 downto 0) := (others => '0');
    signal clk_ctrl_val   : std_logic_vector(7 downto 0) := (others => '0');
    signal selected_src   : integer range 0 to 3 := 0; 
    signal clk_gen_active : std_logic := '0';
    
    -- Data Registers
    signal adc_ldr   : std_logic_vector(7 downto 0) := (others => '0'); -- AIN0
    signal adc_temp  : std_logic_vector(7 downto 0) := (others => '0'); -- AIN1
    signal adc_wave  : std_logic_vector(7 downto 0) := (others => '0'); -- AIN2 (Waveform)
    signal adc_pot   : std_logic_vector(7 downto 0) := (others => '0'); -- AIN3 (Potentiometer)

    -- FSM State Definitions
    type state is (
        POWER_UP, 
        -- LCD Soft Reset Sequence (Robust Init)
        LCD_SOFT_RESET_1, LCD_WAIT_RAW_1, LCD_DELAY_1,
        LCD_SOFT_RESET_2, LCD_WAIT_RAW_2, LCD_DELAY_2,
        LCD_SOFT_RESET_3, LCD_WAIT_RAW_3,
        LCD_SET_4BIT,     LCD_WAIT_RAW_4,
        -- LCD Config Sequence
        LCD_INIT_2, LCD_INIT_3, LCD_INIT_4, LCD_INIT_5,

        -- Main Loop - Update LCD
        LCD_HOME, LCD_WRITE_L1, LCD_NEXT_LINE, LCD_WRITE_L2,
        -- LCD Low Level Helper States
        LCD_SEND_NIBBLE_HI, LCD_WAIT_HI_1, LCD_WAIT_HI_2,
        LCD_SEND_NIBBLE_LO, LCD_WAIT_LO_1, LCD_WAIT_LO_2
    );

    signal state_LCD : state := POWER_UP;
--    signal state_ADC : state_wave := POWER_UP;
    signal return_state : state; 
    
    signal timer : integer := 0;
    
    -- LCD Data Handling
    signal lcd_byte_to_send : std_logic_vector(7 downto 0);
    signal lcd_rs_mode      : std_logic := '0'; 
    signal lcd_char_index   : integer range 0 to 16 := 0;
    
    -- LCD Backlight bit
    constant LCD_BL : std_logic := '1'; 

    -- String buffers
    type char_array is array (0 to 15) of std_logic_vector(7 downto 0);
    signal line1_buffer : char_array;
    signal line2_buffer : char_array;

    -- Helper Function for Strings
    function get_char(c : character) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    end function;

begin
    -- -------------------------------------------------------------------------
    -- Component Instantiations
    -- -------------------------------------------------------------------------
    
    -- 1. I2C Master
    i2c_inst : entity work.i2c_master
    generic map( input_clk => 125_000_000, bus_clk => 100_000 ) 
    port map(
        clk => clk,
        reset_n => reset_n,
        ena => i2c_ena,
        addr => i2c_addr,
        rw => i2c_rw,
        data_wr => i2c_data_wr,
        busy => i2c_busy,
        data_rd => i2c_data_rd,
        ack_error => i2c_ack_err, 
        sda => ck_sda,
        scl => ck_scl
    );

    -- -------------------------------------------------------------------------
    -- LCD Buffer Generator
    -- -------------------------------------------------------------------------
    --TODO: i dont thinkk this needs 'selected_src'
    process(clk_gen_active)
    begin
        --TODO: this is also hard coded and needs to be
        --  replaced with
        -- Line 1: Source
        line1_buffer <= (others => get_char(' ')); -- Clear
        line1_buffer(0) <= get_char('S');
        line1_buffer(1) <= get_char('r');
        line1_buffer(2) <= get_char('c');
        line1_buffer(3) <= get_char(':');
        
        --TODO: this is hard coded, change this to set the buffer based
        --  on the input from the PC
        case selected_src is
            when 0 => -- LDR
                line1_buffer(5) <= get_char('L');
                line1_buffer(6) <= get_char('D');
                line1_buffer(7) <= get_char('R');
            when 1 => -- TEMP
                line1_buffer(5) <= get_char('T');
                line1_buffer(6) <= get_char('E');
                line1_buffer(7) <= get_char('M');
                line1_buffer(8) <= get_char('P');
            when 2 => -- WAVE
                line1_buffer(5) <= get_char('W');
                line1_buffer(6) <= get_char('A');
                line1_buffer(7) <= get_char('V');
                line1_buffer(8) <= get_char('E');
            when 3 => -- POT
                line1_buffer(5) <= get_char('P');
                line1_buffer(6) <= get_char('O');
                line1_buffer(7) <= get_char('T');
            when others => null;
        end case;

        -- TODO: use this for win loss
        -- Line 2: Clock Status
        line2_buffer <= (others => get_char(' ')); -- Clear
        line2_buffer(0) <= get_char('C');
        line2_buffer(1) <= get_char('l');
        line2_buffer(2) <= get_char('k');
        line2_buffer(3) <= get_char(':');
        
        if clk_gen_active = '1' then
            line2_buffer(5) <= get_char('O');
            line2_buffer(6) <= get_char('N');
        else
            line2_buffer(5) <= get_char('O');
            line2_buffer(6) <= get_char('F');
            line2_buffer(7) <= get_char('F');
        end if;
    end process;
                
    -- -------------------------------------------------------------------------
    -- MAIN I2C FSM
    -- -------------------------------------------------------------------------
    process(clk)
        variable upper_nib : std_logic_vector(3 downto 0);
        variable lower_nib : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state_LCD <= POWER_UP;
--                state_ADC <= POWER_UP;
                timer <= 0;
                i2c_ena <= '0';
                i2c_data_wr <= (others => '0');
            else
                case state_LCD is
                    
                    -- 1. Power Up Wait (40ms)
                    when POWER_UP =>
                        if timer < TIME_40MS then
                            timer <= timer + 1;
                        else
                            timer <= 0;
                            -- Jump straight to LCD init, ADC control happens in main loop
                            state_LCD <= LCD_SOFT_RESET_1;
                        end if;

                    -- ---------------------------------------------------------
                    -- LCD ROBUST INITIALIZATION (Soft Reset)
                    -- ---------------------------------------------------------
                    when LCD_SOFT_RESET_1 =>
                        i2c_data_wr <= "0011" & LCD_BL & '1' & '0' & '0';
                        i2c_addr <= ADDR_LCD;
                        i2c_rw <= '0';
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_RAW_1;

                    when LCD_WAIT_RAW_1 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            if i2c_data_wr(2) = '1' then 
                                i2c_data_wr(2) <= '0';
                                i2c_ena <= '1';
                            else 
                                timer <= 0;
                                state_LCD <= LCD_DELAY_1; 
                            end if;
                        end if;

                    when LCD_DELAY_1 =>
                        if timer < 625000 then 
                            timer <= timer + 1;
                        else
                            state_LCD <= LCD_SOFT_RESET_2;
                        end if;

                    when LCD_SOFT_RESET_2 =>
                        i2c_data_wr <= "0011" & LCD_BL & '1' & '0' & '0';
                        i2c_addr <= ADDR_LCD;
                        i2c_rw <= '0';
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_RAW_2;

                    when LCD_WAIT_RAW_2 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            if i2c_data_wr(2) = '1' then 
                                i2c_data_wr(2) <= '0';
                                i2c_ena <= '1';
                            else 
                                timer <= 0;
                                state_LCD <= LCD_DELAY_2; 
                            end if;
                        end if;

                    when LCD_DELAY_2 => 
                         if timer < 20000 then 
                            timer <= timer + 1;
                        else
                            state_LCD <= LCD_SOFT_RESET_3;
                        end if;

                    when LCD_SOFT_RESET_3 =>
                        i2c_data_wr <= "0011" & LCD_BL & '1' & '0' & '0';
                        i2c_addr <= ADDR_LCD;
                        i2c_rw <= '0';
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_RAW_3;
                        
                    when LCD_WAIT_RAW_3 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            if i2c_data_wr(2) = '1' then 
                                i2c_data_wr(2) <= '0';
                                i2c_ena <= '1';
                            else 
                                state_LCD <= LCD_SET_4BIT; 
                            end if;
                        end if;

                    when LCD_SET_4BIT =>
                        i2c_data_wr <= "0010" & LCD_BL & '1' & '0' & '0';
                        i2c_addr <= ADDR_LCD;
                        i2c_rw <= '0';
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_RAW_4;

                    when LCD_WAIT_RAW_4 =>
                         if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            if i2c_data_wr(2) = '1' then 
                                i2c_data_wr(2) <= '0';
                                i2c_ena <= '1';
                            else 
                                state_LCD <= LCD_INIT_2; 
                            end if;
                        end if;

                    when LCD_INIT_2 =>
                        lcd_byte_to_send <= x"28";
                        lcd_rs_mode <= '0';
                        return_state <= LCD_INIT_3;
                        state_LCD <= LCD_SEND_NIBBLE_HI;
                        
                    when LCD_INIT_3 =>
                        lcd_byte_to_send <= x"0C";
                        lcd_rs_mode <= '0';
                        return_state <= LCD_INIT_4;
                        state_LCD <= LCD_SEND_NIBBLE_HI;
                        
                    when LCD_INIT_4 =>
                        lcd_byte_to_send <= x"01";
                        lcd_rs_mode <= '0';
                        return_state <= LCD_INIT_5;
                        state_LCD <= LCD_SEND_NIBBLE_HI;
                        
                    when LCD_INIT_5 =>
                        if timer < TIME_2MS then
                            timer <= timer + 1;
                        else
                            timer <= 0;
                            state_LCD <= LCD_HOME;
                        end if;

                    -- ---------------------------------------------------------
                    -- MAIN LOOP: Update LCD
                    -- ---------------------------------------------------------
                    
                    when LCD_HOME =>
                        lcd_byte_to_send <= x"80";
                        lcd_rs_mode <= '0';
                        return_state <= LCD_WRITE_L1;
                        state_LCD <= LCD_SEND_NIBBLE_HI;
                        lcd_char_index <= 0;
                        
                    when LCD_WRITE_L1 =>
                        if lcd_char_index < 16 then
                            lcd_byte_to_send <= line1_buffer(lcd_char_index);
                            lcd_rs_mode <= '1';
                            lcd_char_index <= lcd_char_index + 1;
                            return_state <= LCD_WRITE_L1;
                            state_LCD <= LCD_SEND_NIBBLE_HI;
                        else
                            state_LCD <= LCD_NEXT_LINE;
                        end if;
                        
                    when LCD_NEXT_LINE =>
                        lcd_byte_to_send <= x"C0";
                        lcd_rs_mode <= '0';
                        return_state <= LCD_WRITE_L2;
                        state_LCD <= LCD_SEND_NIBBLE_HI;
                        lcd_char_index <= 0;
                        
                    when LCD_WRITE_L2 =>
                         if lcd_char_index < 16 then
                            lcd_byte_to_send <= line2_buffer(lcd_char_index);
                            lcd_rs_mode <= '1';
                            lcd_char_index <= lcd_char_index + 1;
                            return_state <= LCD_WRITE_L2;
                            state_LCD <= LCD_SEND_NIBBLE_HI;
                        else
                            state_LCD <= LCD_HOME; -- Loop back to write control byte
                        end if;

                    -- ---------------------------------------------------------
                    -- LCD LOW LEVEL DRIVER 
                    -- ---------------------------------------------------------
                    
                    when LCD_SEND_NIBBLE_HI =>
                        upper_nib := lcd_byte_to_send(7 downto 4);
                        i2c_data_wr <= upper_nib & LCD_BL & '1' & '0' & lcd_rs_mode;
                        i2c_addr <= ADDR_LCD;
                        i2c_rw <= '0';
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_HI_1;
                        
                    when LCD_WAIT_HI_1 =>
                        if i2c_busy = '1' then i2c_ena <= '0'; 
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            i2c_data_wr(2) <= '0';
                            i2c_ena <= '1';
                            state_LCD <= LCD_WAIT_HI_2; 
                        end if;

                    when LCD_WAIT_HI_2 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            state_LCD <= LCD_SEND_NIBBLE_LO;
                        end if;

                    when LCD_SEND_NIBBLE_LO =>
                        lower_nib := lcd_byte_to_send(3 downto 0);
                        i2c_data_wr <= lower_nib & LCD_BL & '1' & '0' & lcd_rs_mode;
                        i2c_ena <= '1';
                        state_LCD <= LCD_WAIT_LO_1;

                    when LCD_WAIT_LO_1 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            i2c_data_wr(2) <= '0';
                            i2c_ena <= '1';
                            state_LCD <= LCD_WAIT_LO_2; 
                        end if;

                    when LCD_WAIT_LO_2 =>
                        if i2c_busy = '1' then i2c_ena <= '0';
                        elsif i2c_busy = '0' and i2c_ena = '0' then
                            state_LCD <= return_state; -- Done
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;