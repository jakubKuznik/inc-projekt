-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s):Jakub Kuzník xkuzni04 
--


--soubor konecného automatu

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port( --zde definujeme jaké má entinta porty 
   CLK     :    in std_logic;
   RST     :    in std_logic;
   DIN     :    in std_logic;                    -- 4 3 2 1 0 == 32 combination
   CNT     :    in std_logic_vector(4 downto 0); -- pole bitu s indexy - - - - - 
   CNT_2   :    in std_logic_vector(3 downto 0);  
   SB_EN_IN :   in std_logic; --slouzi pro zmenu stavu z 4 -> 5
   VD_OK   :   in std_logic; -- zmena stavu z 5 -> 1 
   
   RX_EN    : out std_logic;  -- read_data state
   SB_EN    : out std_logic;  -- stop bit state 
   --VD_EN    : out std_logic;  -- valid data state 
   CNT_EN   : out std_logic;
   CNT_2_EN : out std_logic;
   DOUT_VLD : out std_logic   -- data valid state 
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
  
  CNT_EN  <='1'   when state = COUNT_UNTIL_F_B or state = READ_DATA or state = WAIT_STOP_BIT else '0';
  CNT_2_EN <='1'  when state = READ_DATA else '0';
  DOUT_VLD <='1'  when state = VALID_DATA else '0';
  
  process (CLK) begin -- proces se vyvola kdykoliv se zmeni clock 
   if rising_edge(CLK) then
      if RST = '1' then 
        state <= WAIT_START_BIT;
        else
           case state is
              when WAIT_START_BIT   => if DIN = '1' then
                                            state <= WAIT_START_BIT;
                                        else 
                                          state <= COUNT_UNTIL_F_B;
                                          
                                        end if;
              when COUNT_UNTIL_F_B  => if CNT = "10111" then
                  -- cekam do 24 abych se dostal do prostred signalu
                                             state <= READ_DATA;
                                        end if;
              when READ_DATA        => if CNT_2 = "1000" then --when i have read 8 bits
                                            state <= WAIT_STOP_BIT;
                                            
                                       end if;     
                                       
              when WAIT_STOP_BIT    => if SB_EN_IN = '1' then
                                            state <= VALID_DATA; 
                                      end if;
                                      
             when VALID_DATA       => if VD_OK = '1' then
                                        state <= WAIT_START_BIT;
                                      end if;
                                      
                                      
              when others           => null;
            end case;         
      end if;
   end if;   
  end process; 
end behavioral;
