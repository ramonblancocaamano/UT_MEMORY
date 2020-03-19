----------------------------------------------------------------------------------
-- @FILE : sd_control.vhd 
-- @AUTHOR: BLANCO CAAMANO, RAMON. <ramonblancocaamano@gmail.com> 
-- 
-- @ABOUT: .
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY sd_control IS
    GENERIC( 
        DATA : INTEGER;
        PACKETS : INTEGER
    );
    PORT( 
        rst: IN STD_LOGIC;
        clk_50 : IN STD_LOGIC;            
        rd_trigger: IN STD_LOGIC;
        rd_trigger_ok: OUT STD_LOGIC;
        rd_continue: OUT STD_LOGIC;
        rd_continue_ok: IN STD_LOGIC;                        
        wr_trigger: OUT STD_LOGIC;
        wr_trigger_ok: IN STD_LOGIC;
        wr_continue : IN STD_LOGIC;
        wr_continue_ok : OUT STD_LOGIC;
        i_buff_rd_en: OUT STD_LOGIC;        
        o_buff_wr_en: OUT STD_LOGIC;  
        sd_rst : OUT STD_LOGIC ;
        sd_addr: OUT STD_LOGIC_VECTOR(31 downto 0);
        sd_rd_en: OUT STD_LOGIC;        
        sd_wr_en: OUT STD_LOGIC;
        sd_hsk_wr_i: OUT STD_LOGIC;
        sd_hsk_rd_i: OUT STD_LOGIC;  
        sd_hsk_rd_o: IN STD_LOGIC;
        sd_hsk_wr_o: IN STD_LOGIC;
        sd_busy : IN STD_LOGIC 		
    );
END sd_control;

ARCHITECTURE behavioral OF sd_control IS
    
    TYPE ST_SD is (IDLE, W1, W2, W3, R1, R2, R3, WAIT_FOR);
    SIGNAL state : ST_SD := IDLE;
    SIGNAL sd_fsm : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL sc_rd_trigger_ok: STD_LOGIC := '0';
    SIGNAL sc_rd_continue: STD_LOGIC := '0';
    SIGNAL sc_wr_trigger: STD_LOGIC := '0'; 
    SIGNAL sc_wr_continue_ok : STD_LOGIC := '0'; 
    SIGNAL sc_i_buff_rd_en: STD_LOGIC := '0';             
    SIGNAL sc_o_buff_wr_en: STD_LOGIC := '0';
    SIGNAL sc_sd_rst : STD_LOGIC := '0';
    SIGNAL sc_sd_addr : STD_LOGIC_VECTOR(31  DOWNTO 0):= (OTHERS => '0');
    SIGNAL sc_sd_rd_en : STD_LOGIC := '0';
    SIGNAL sc_sd_wr_en : STD_LOGIC := '0';
    SIGNAL sc_sd_hsk_wr_i : STD_LOGIC := '0';
    SIGNAL sc_sd_hsk_rd_i : STD_LOGIC := '0';   
    
BEGIN
    
    rd_trigger_ok <= sc_rd_trigger_ok;
    rd_continue <= sc_rd_continue;           
    wr_trigger <= sc_wr_trigger;    
    wr_continue_ok <= sc_wr_continue_ok;
    i_buff_rd_en <= sc_i_buff_rd_en;
    o_buff_wr_en <= sc_o_buff_wr_en;     
    sd_rst <= sc_sd_rst;
    sd_addr <= sc_sd_addr;
    sd_rd_en <= sc_sd_rd_en;
    sd_wr_en <= sc_sd_wr_en;
    sd_hsk_wr_i <= sc_sd_hsk_wr_i;
    sd_hsk_rd_i <= sc_sd_hsk_rd_i;
    

    PROCESS(rst, clk_50, rd_trigger, rd_continue_ok, wr_trigger_ok, wr_continue, sd_hsk_rd_o, sd_hsk_wr_o, sd_busy,
        state, sc_rd_trigger_ok, sc_rd_continue, sc_wr_trigger, sc_wr_continue_ok, sc_i_buff_rd_en, 
        sc_o_buff_wr_en , sc_sd_rst, sc_sd_addr, sc_sd_rd_en, sc_sd_wr_en, sc_sd_hsk_wr_i, sc_sd_hsk_rd_i)
    
        VARIABLE counter_data : INTEGER := 0;
        VARIABLE counter_packets : INTEGER := 0;    
        VARIABLE addr: INTEGER := 0;
        VARIABLE addr_packets: INTEGER := 0;
        
    BEGIN
        IF rst = '1' THEN
                state <= IDLE;
                counter_data := 0;
                counter_packets := 0;
                addr := 0;
                addr_packets := 0;               
                sc_rd_trigger_ok <= '0';
                sc_rd_continue <= '0';
                sc_wr_trigger <= '0';
                sc_wr_continue_ok <= '0';
                sc_i_buff_rd_en <= '0';
                sc_o_buff_wr_en <= '0';
                sc_sd_rst <= '1';
                sc_sd_addr <= (OTHERS => '0');    
                sc_sd_wr_en <= '0';
                sc_sd_rd_en <= '0';         
                sc_sd_hsk_wr_i <= '0';
                sc_sd_hsk_rd_i <= '0';                               
        ELSIF RISING_EDGE(clk_50) THEN                
            IF wr_trigger_ok = '1' THEN
                sc_wr_trigger <= '0';
            END IF;        
            IF wr_continue = '1' THEN
                sc_wr_continue_ok <= '1';
            ELSE 
                sc_wr_continue_ok <= '0';
            END IF;        
            IF rd_continue_ok = '1' THEN
                sc_rd_continue <= '0';
            END IF;        
            CASE (state) IS
            
                WHEN IDLE =>
                
                    counter_data := 0;
                    addr_packets := 0;
                    sc_o_buff_wr_en <= '0';
                    sc_sd_rst <= '0';
                    sc_sd_wr_en <= '0';
                    sc_sd_rd_en <= '0'; 
                    sc_sd_hsk_wr_i <= '0';
                    sc_sd_hsk_rd_i <= '0';                                        
                    IF rd_trigger = '1' AND sd_busy = '0' THEN
                        state <= W1;                        
                        sc_rd_trigger_ok <= '1';
                        sc_i_buff_rd_en <= '1';                       
                    ELSE
                        sc_rd_trigger_ok <= '0'; 
                        sc_i_buff_rd_en <= '0';                        
                    END IF;                      
                
                WHEN W1 =>
                
                    sc_i_buff_rd_en <= '0';                    
                    IF rd_trigger = '0' THEN
                        sc_rd_trigger_ok <= '0';
                    END IF;                    
                    IF sd_busy = '0' AND addr_packets < 16 THEN  
                        state <= W2;
                        addr := addr + 1;
                        addr_packets := addr_packets + 1;                                                                      
                        sc_o_buff_wr_en <= '1';
                        sc_sd_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(addr,32));
                        sc_sd_wr_en <= '1';
                        sc_sd_hsk_wr_i <= '1';                        
                    ELSIF addr_packets >= 16 AND counter_packets < PACKETS-1 THEN
                        state <= IDLE;                                              
                        counter_data := 0;
                        counter_packets := counter_packets + 1;
                        addr_packets := 0;
                        sc_i_buff_rd_en <= '0';                     
                    ELSIF addr_packets >= 16 AND counter_packets = PACKETS-1 THEN
                        state <= R1;
                        counter_data := 0;
                        counter_packets := 0;                        
                        addr := 0;
                        addr_packets := 0;                       
                        sc_i_buff_rd_en <= '0';                                               
                    END IF;
                
                WHEN W2 =>
                
                    IF sd_hsk_wr_o = '1' THEN
                        state <= W3;
                        sc_i_buff_rd_en <= '1';
                        sc_sd_hsk_wr_i <= '0';                                                       
                    END IF;
                
                WHEN W3 =>
                
                    sc_i_buff_rd_en <= '0';
                    IF sd_hsk_wr_o = '0' THEN
                        IF counter_data < (512-1) THEN
                            state <= W2;
                            counter_data := counter_data + 1;
                            sc_sd_hsk_wr_i <= '1';                            
                        ELSE
                            state <= W1;
                            counter_data := 0;
                            sc_sd_wr_en <= '0';
                        END IF;
                    END IF;
                
                WHEN R1 =>
                
                    IF sd_busy = '0' AND addr_packets < 16 THEN
                        state <= R2; 
                        addr := addr + 1;
                        addr_packets := addr_packets + 1;                          
                        sc_sd_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(counter_data,32));    
                        sc_sd_rd_en <= '1';                                                                
                    ELSIF addr_packets >= 16 THEN
                        state <= WAIT_FOR;
                        counter_packets := counter_packets + 1;
                        addr_packets := 0;
                        sc_wr_trigger <= '1';                                                
                    END IF;
                
                WHEN R2 =>
                
                    IF sd_hsk_rd_o = '1' THEN 
                        state <= R3;
                        sc_o_buff_wr_en <= '1';                       
                        sc_sd_hsk_rd_i <= '1';
                    END IF;
                
                WHEN R3 =>
                
                    sc_o_buff_wr_en <= '0';
                    IF sd_hsk_rd_o = '0' THEN
                        sc_sd_hsk_rd_i <= '0';
                        IF counter_data < (512-1) THEN
                            state <= R2;
                            counter_data := counter_data + 1;
                        ELSE
                            state <= R1;
                            counter_data := 0;
                            sc_sd_rd_en <= '0';
                        END IF;
                    END IF;
                
                WHEN WAIT_FOR =>
                
                    IF counter_packets = PACKETS THEN                              
                        state <= IDLE;
                        counter_packets := 0;
                        addr_packets := 0;
                        addr := 0;    
                    ELSIF wr_continue = '1' AND sd_busy = '0' THEN
                        state <= R1;
                    END IF;
            
            END CASE;
        END IF;
    END PROCESS;
    
    STATE_SD: BLOCK
    BEGIN
        WITH state SELECT sd_fsm <=
            x"00" WHEN IDLE,
            x"01" WHEN W1,
            x"02" WHEN W2,
            x"03" WHEN W3,
            x"04" WHEN R1,
            x"05" WHEN R2,
            x"06" WHEN R3,
            x"07" WHEN WAIT_FOR,			
            x"FF" WHEN OTHERS
         ;
    END BLOCK STATE_SD;

END behavioral;
