-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s):Jakub Kuzník xkuzni04 
-- Tento soubor je FSM kde ukladam a menim stavy 


--soubor konecného automatu

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port( --zde definujeme jaké má entinta porty 
   CLK         :  in std_logic;
   RST         :  in std_logic;
   DIN         :  in std_logic;                    -- 4 3 2 1 0 == 32 combination
   CNT_CLCK    :  in std_logic_vector(4 downto 0); -- pole bitu s indexy - - - - - 
   CNT_BIT     :  in std_logic_vector(3 downto 0);  
   STOPB_EN_IN :  in std_logic; --slouzi pro zmenu stavu z 4 -> 5
   
   RX_EN         : out std_logic;  -- read_data state
   SB_EN         : out std_logic;  -- stop bit state 
   CNT_CLCK_EN   : out std_logic;  -- enable cnt_clck
   CNT_BIT_EN    : out std_logic;  -- enable cnt_bti
   VALID         : out std_logic   -- data valid state 
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
  
-- IMPLEMENTACE STAVOVÉHO AUTOMATU 

type STATE_TYPE is (WAIT_START_BIT, COUNT_UNTIL_F_B, READ_DATA, WAIT_STOP_BIT, VALID_DATA )  ;
signal state : STATE_TYPE := WAIT_START_BIT;

begin
  --inicializace OUT SIGNALU/PORTU
  
  --READ_DATA
  RX_EN   <='1'   when state = READ_DATA else '0';
  SB_EN   <='1'   when state = WAIT_STOP_BIT else '0';
  
  CNT_CLCK_EN  <='1'   when state = COUNT_UNTIL_F_B or state = READ_DATA or state = WAIT_STOP_BIT else '0';
  CNT_BIT_EN <='1'  when state = READ_DATA else '0';
  VALID <='1'  when state = VALID_DATA else '0';
  
  process (CLK) begin -- proces se vyvola kdykoliv se zmeni clock 
   if rising_edge(CLK) then
      if RST = '1' then 
        state <= WAIT_START_BIT;
      else
           case state is
              -- 1. STATE WAIT FOR START  BIT 
              when WAIT_START_BIT   => if DIN = '1' then
                                            state <= WAIT_START_BIT;
                                        else 
                                          state <= COUNT_UNTIL_F_B;
                                        end if;
                                        
              -- 2. STATE COUNT CLCK UNTIL MEASURING FIRST INPUT BIT                           
              when COUNT_UNTIL_F_B  => if CNT_CLCK = "10111" then -- cekam do 24 abych se dostal do prostred signalu
                                             state <= READ_DATA;
                                        end if;
              -- 3. STATE READ 8 INPUT BITS                          
              when READ_DATA        => if CNT_BIT = "1000" then --when i have read 8 bits
                                            state <= WAIT_STOP_BIT;     
                                       end if;     
              -- 4. STATE WAIT UNTIL STOP BI                                             
              when WAIT_STOP_BIT    => if STOPB_EN_IN = '1' then
                                            state <= VALID_DATA; 
                                      end if;
              -- 5. STATE SET VALID BIT                         
              when VALID_DATA       => state <= WAIT_START_BIT;
                                      
             when others           => null;
            end case;         
      end if;
   end if;   
  end process; 
end behavioral;
