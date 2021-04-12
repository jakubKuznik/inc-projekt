-- uart.vhd: UART controller - receiving part
-- Author(s): xkuzni04 Jakub Kuzník
--


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
  
signal cnt      : std_logic_vector(4 downto 0);
signal cnt_2    : std_logic_vector(3 downto 0);

signal stopb_en    : std_logic;
signal stopb_en_in : std_logic;

signal vd_ok    : std_logic;

signal cnt_en   : std_logic; -- Indikuje   ze mam inkrementovat cnt
signal cnt_2_en : std_logic; -- Indikator inkremetace cnt_2

signal rx_en    : std_logic; 
signal DVLD     : std_logic;


begin
    -- Design under test
    STATE_MACHINE: entity work.UART_FSM(behavioral)
    port map (
        CLK 	     => clk,
        RST 	     => rst,
        DIN 	     => din,
        CNT 	     => cnt,
        CNT_2 	   => cnt_2,
        RX_EN     => rx_en,
        CNT_EN    => cnt_en,
        CNT_2_EN  => cnt_2_en,
        DOUT_VLD  => DVLD,
        SB_EN     => stopb_en, --sb == stop bit 
        SB_EN_IN  => stopb_en_in,
        VD_OK     => vd_ok
    );


    --DOUT_VLD <= DVLD;
    process(CLK) begin
    
        if rising_edge(CLK) then
         
          if rx_en = '0' then
            cnt_2 <= "0000";
          end if; 
          
          if DVLD = '1' then
            DOUT_VLD <= '1';
            vd_ok <= '1';
          else
            DOUT_VLD <= '0';
            vd_ok <= '0';
          end if;
            
          if cnt_en = '1' then -- if we are in state where we count 
              cnt <= cnt + 1;  -- increment counter 
           else                -- if we are not at this state alway set it to 0
              cnt <= "00000";          
          end if;
          
          
          if stopb_en = '1' then
            report "hovno";
            if DIN = '1' then
              
              stopb_en_in <= '1'; -- FSM zmeni stav z 4 -> 5
            end if; 
           end if;  


           --READ_DATA_STATE
           if rx_en = '1' then
              if cnt_2 = "0000"  then
                cnt <= "00000";
                DOUT(to_integer(unsigned(cnt_2))) <= DIN;
                cnt_2 <= cnt_2 + 1;
              else if cnt = "01111" then
                cnt <= "00000";
                DOUT(to_integer(unsigned(cnt_2))) <= DIN;
                cnt_2 <= cnt_2 + 1;
              end if;     
          end if;                
                         
           
           
           
        end if;
      end if;
  end process;    
    
    
end behavioral;

