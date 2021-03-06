LIBRARY IEEE;
LIBRARY ALTERA_MF;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;
USE LPM.LPM_COMPONENTS.ALL;


ENTITY SCOMPSRAM IS
	PORT(
		IO_WRITE    	: IN    STD_LOGIC;
		SRAM_ADHI_EN    : IN    STD_LOGIC;
		SRAM_ADLOW_EN   : IN    STD_LOGIC;
		SRAM_DATA_EN    : IN 	STD_LOGIC;
		SRAM_CTRL_EN	: IN 	STD_LOGIC;
		IO_DATA			: INOUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_ADDR		: OUT	STD_LOGIC_VECTOR(17 DOWNTO 0);
		SRAM_DQ			: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		SRAM_CTRL   	: INOUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
		SRAM_OE_N		: OUT	STD_LOGIC;
		SRAM_WE_N		: OUT	STD_LOGIC;
		SRAM_UB_N		: OUT 	STD_LOGIC;
		SRAM_LB_N		: OUT	STD_LOGIC;
		SRAM_CE_N		: OUT	STD_LOGIC;
		SWITCH_EN		: IN	STD_LOGIC;
		LED_EN			: IN	STD_LOGIC;
		LED2_EN			: IN	STD_LOGIC
	);
END SCOMPSRAM;


ARCHITECTURE a OF SCOMPSRAM IS
	
	TYPE STATE_TYPE IS (
		NOTHING, READCYCLE, ADHI, ADLOW, DATA, CTRL, WRITECYCLE
	);
	
	SIGNAL STATE		: STATE_TYPE;
 


BEGIN
	PROCESS (IO_WRITE, SWITCH_EN, SRAM_ADHI_EN, SRAM_ADLOW_EN, SRAM_DATA_EN, SRAM_CTRL_EN, LED_EN, LED2_EN)
	BEGIN
		IF (SWITCH_EN = '1') THEN  --IF SWITCH IS ASSERTED, RESET 
			STATE <= NOTHING;
		ELSIF (IO_WRITE = '1' AND SRAM_ADHI_EN = '1') THEN
			CASE STATE IS
				WHEN WRITECYCLE =>
					STATE<=ADHI; --WHEN SRAM_WE_N IS ASSERTED, CAN WRITE IO_DATA
				WHEN OTHERS =>
					STATE<=NOTHING;     
			END CASE;
		ELSIF (IO_WRITE = '1' AND SRAM_ADLOW_EN = '1') THEN
			CASE STATE IS	
				WHEN WRITECYCLE =>
					STATE<=ADLOW; --WHEN SRAM_WE_N IS ASSERTED, CAN WRITE IO_DATA
				WHEN OTHERS =>
					STATE<=NOTHING;
			END CASE;
		ELSIF (IO_WRITE = '1' AND SRAM_DATA_EN = '1') THEN
			CASE STATE IS	
				WHEN WRITECYCLE =>
					STATE<=DATA; --WHEN SRAM_WE_N IS ASSERTED, CAN WRITE IO_DATA
				WHEN OTHERS =>
					STATE<=NOTHING;
			END case;
		ELSIF (IO_WRITE = '1' AND SRAM_CTRL_EN = '1') THEN
			STATE <= CTRL; 
		ELSIF (LED_EN = '1') THEN
			CASE STATE IS
				WHEN DATA =>
					STATE <= WRITEDONE;
				WHEN ADHI =>
					STATE <= WRITEDONE;
				WHEN ADLOW =>
					STATE <= WRITEDONE;
			END CASE;
		ELSIF (LED2_EN = '1') THEN
			CASE STATE IS
				WHEN READCYCLE =>
					STATE <= READDONE;
			END CASE; 
		END IF;
			

			
CASE STATE IS 					
	WHEN CTRL=>
		SRAM_CTRL(2 DOWNTO 0) <= IO_DATA(2 DOWNTO 0);
		CASE SRAM_CTRL(2 DOWNTO 0) IS 
			WHEN "101" =>	--101 = drive, write, no OE(no read) -> SRAM WRITE
             SRAM_WE_N<='0';
             SRAM_OE_N<='1';
			 STATE <= WRITECYCLE;
		    WHEN "010" =>  --010 = no drive, no write, read -> SRAM READ
			 SRAM_WE_N<='1';
			 SRAM_OE_N<='0';
			 STATE <= READCYCLE;
		    WHEN "111"=>  --111 = drive, no write, no read -> driving new data during a write
			 STATE <= CTRL;
			WHEN OTHERS =>
				STATE <= NOTHING;
		END CASE;
		
	WHEN READCYCLE=>
        IO_DATA(15 DOWNTO 0) <= SRAM_DQ(15 DOWNTO 0);	
        
    WHEN ADHI=>
		SRAM_ADDR(17 DOWNTO 16) <= IO_DATA(1 DOWNTO 0);
	
	WHEN ADLOW=>
		SRAM_ADDR(15 DOWNTO 0) <= IO_DATA(15 DOWNTO 0);
		
	WHEN DATA=>
		SRAM_DQ(15 DOWNTO 0) <= IO_DATA(15 DOWNTO 0);
		
	WHEN NOTHING=>
		SRAM_WE_N<='1';
		SRAM_OE_N<='1';
	END CASE;
  END PROCESS;
END a;