-- uart.vhd: UART controller - receiving part
-- Author(s): xkuzni04 Jakub Kuzník
-- Soubor funguje UART a jeho stavy uklada do uart.fsm.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-------------------------------------------------
entity UART_RX is
port(	
  CLK       :  in std_logic;
	RST       : 	in std_logic;
	DIN       : 	in std_logic;
	DOUT      :  out std_logic_vector(7 downto 0);  --1SLOVO VYSTUP
	DOUT_VLD  : 	out std_logic -- URCUJE JESTLI JE DOUT VALIDNI
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
  
signal cnt_clck      : std_logic_vector(4 downto 0); -- v cnt_clck vzdy pocitam 16 clck signalu
signal cnt_bit    : std_logic_vector(3 downto 0); -- v cnt_bit pocitam bity

signal stopb_en    : std_logic; 
signal stopb_en_in : std_logic; -- stop bit state enabl e

signal vd_ok    : std_logic; -- Valid data state enable 

signal cnt_en   : std_logic; -- Indikuje   ze mam inkrementovat cnt
signal cnt_2_en : std_logic; -- Indikator inkremetace cnt_2

signal rx_en    : std_logic; 
signal DVLD     : std_logic;


begin
    -- Design under test
    STATE_MACHINE: entity work.UART_FSM(behavioral)
    port map (
        CLK 	         => clk,
        RST 	         => rst,
        DIN 	         => din,
        CNT_CLCK      => cnt_clck,
        CNT_BIT 	     => cnt_bit,
        RX_EN         => rx_en,
        CNT_CLCK_EN   => cnt_en,
        CNT_BIT_EN    => cnt_2_en,
        VALID         => DVLD,
        SB_EN         => stopb_en, --sb == stop bit 
        STOPB_EN_IN   => stopb_en_in
    );


    --DOUT_VLD <= DVLD;
    process(CLK) begin
    
        if rising_edge(CLK) then
         
         
          --COUNTER SET TO 0 WHEN STATE IS NOT RECEIVE ENABLE 
          if rx_en = '0' then
            cnt_bit <= "0000";
          end if; 
          ------------------
        
          ---COUNTER INCEMENT 
          if cnt_en = '1' then -- if we are in state where we count 
              cnt_clck <= cnt_clck + 1;  -- increment counter 
           else                -- if we are not at this state alway set it to 0
              cnt_clck <= "00000";          
          end if;
          -----------------
                
          --SENDING VALID BIT 
          if DVLD = '1' then
            DOUT_VLD <= '1';
          else
            DOUT_VLD <= '0';
          end if;
          -----------------
               
         --WAIT FOR STOP BIT
          if stopb_en = '1' then
            if DIN = '1' then 
              stopb_en_in <= '1'; -- FSM zmeni stav z 4 -> 5
            end if; 
           end if; 
           
           --READ_DATA_STATE
           if rx_en = '1' then
              if cnt_bit = "0000"  then
                cnt_clck <= "00000";
                DOUT(to_integer(unsigned(cnt_bit))) <= DIN;
                cnt_bit <= cnt_bit + 1;
              else if cnt_clck = "01111" then
                cnt_clck <= "00000";
                DOUT(to_integer(unsigned(cnt_bit))) <= DIN;
                cnt_bit <= cnt_bit + 1;
              end if;     
          end if;        
          
                             
        end if;
      end if;
  end process;    
    
    
end behavioral;

