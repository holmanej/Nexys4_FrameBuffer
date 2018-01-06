library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FrBuf_RamInterface is
	Port(
		clk			: in  STD_LOGIC;
		reset		: in  STD_LOGIC;
		-- write ports --
		wrAddr		: in  STD_LOGIC_VECTOR (18 downto 0);
		wrData		: in  STD_LOGIC_VECTOR (11 downto 0);
		wrValid		: in  STD_LOGIC;
		getEntry	: out STD_LOGIC;
		-- read ports --
		bufEmpty	: in  STD_LOGIC;
		bufWrite	: out STD_LOGIC;
		bufData		: out STD_LOGIC_VECTOR (15 downto 0);
		-- cell ram --
		MemAdr      : out STD_LOGIC_VECTOR (22 downto 0);
		MemDB       : inout STD_LOGIC_VECTOR (15 downto 0);
		RamWait		: in  STD_LOGIC;
		RamCLK      : out STD_LOGIC;
		RamADVn     : out STD_LOGIC;
		RamCRE      : out STD_LOGIC;
		RamCEn      : out STD_LOGIC;
		RamOEn      : out STD_LOGIC;
		RamWEn      : out STD_LOGIC;
		RamLBn      : out STD_LOGIC;
		RamUBn      : out STD_LOGIC
	);
end FrBuf_RamInterface;

architecture Behavioral of FrBuf_RamInterface is

	constant initWord	:	STD_LOGIC_VECTOR (22 downto 0) := "00010000001110000011111";
	
	constant width		:	INTEGER := 640;
	constant height		:	INTEGER := 480;
	constant addrSize	:	INTEGER := (width * height) / 128; -- burst size is 128

	type ramRW_state is (
		INIT_MODE_1,
		INIT_MODE_2,
		INIT_MODE_3,
		INIT_MODE_4,
		IDLE,
		SET_READADDR,
		SET_READCLK,
		WAIT_READDATA,
		SET_WRITEADDR,
		SET_WRITECLK,
		WAIT_WRITEDATA,
		READ_DATA,
		WRITE_DATA
	);
	
	signal presentState	:	ramRW_state;
	signal nextState	:	ramRW_state := INIT_MODE_1;
	
	signal initWord_sel	:	STD_LOGIC;
	signal wrAddr_sel	:	STD_LOGIC;
	signal initCnt_clr	:	STD_LOGIC;
	signal initCnt_en	:	STD_LOGIC;
	signal readAddr_en	:	STD_LOGIC;
	signal MemAdr_en	:	STD_LOGIC;
	signal MemDB_load	:	STD_LOGIC;
	signal clkEn		:	STD_LOGIC := '0';
	
	signal initCnt		:	UNSIGNED (3 downto 0) := (others => '0');	
	signal readAddr		:	UNSIGNED (11 downto 0) := (others => '0');

begin

	process(clk) is
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				presentState <= INIT_MODE_1;
			else
				presentState <= nextState;
			end if;		
		end if;		
	end process;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				initCnt <= (others => '0');
			elsif (initCnt_en = '1') then
				initCnt <= initCnt + 1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if (reset = '1' or readAddr = 3750) then
				readAddr <= (others => '0');
			elsif (readAddr_en = '1') then
				readAddr <= readAddr + 1;
			end if;
		end if;
	end process;
	
	RamCLK	<= clk when (clkEn = '1') else '0';
	
	MemAdr	<= initWord when (initWord_sel = '1') else
			   "0000" & wrAddr when (wrAddr_sel = '1') else 
			   "0000" & std_logic_vector(readAddr) & "0000000";
			   
	MemDB	<= (x"0" & wrData) when (MemDB_load = '1') else (others => 'Z');
	bufData	<= MemDB;
	
	process(presentState, initCnt, bufEmpty, RamWait, readAddr, wrValid, wrData) is
	begin
		case presentState is
		
			when INIT_MODE_1 =>
				initWord_sel<= '1';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '1';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= INIT_MODE_2;
				
			when INIT_MODE_2 =>
				initWord_sel<= '1';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '0';
				RamCRE      <= '1';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= INIT_MODE_3;
			
			when INIT_MODE_3 =>
				initWord_sel<= '1';
				wrAddr_sel	<= '0';
				initCnt_en	<= '1';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				if (initCnt = 3) then
					nextState <= INIT_MODE_4;
				else
					nextState <= presentState;
				end if;
				
			when INIT_MODE_4 =>
				initWord_sel<= '1';
				wrAddr_sel	<= '0';
				initCnt_en	<= '1';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn      <= '0';
				RamUBn      <= '0';
				if (initCnt = 10) then
					nextState <= IDLE;
				else
					nextState <= presentState;
				end if;
		
			when IDLE =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '1';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '1';
				RamUBn      <= '1';
				if (bufEmpty = '1') then
					nextState <= SET_READADDR;
				elsif (wrValid = '1') then
					nextState <= SET_WRITEADDR;
				else
					nextState <= presentState;
				end if;
				
			when SET_READADDR =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '1';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '0';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= SET_READCLK;
				
			when SET_READCLK =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '1';
				RamADVn     <= '0';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= WAIT_READDATA;
				
			when WAIT_READDATA =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '1';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				if (RamWait = '0') then
					nextState <= READ_DATA;
				else
					nextState <= presentState;
				end if;
				
			when SET_WRITEADDR =>
				initWord_sel<= '0';
				wrAddr_sel	<= '1';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '0';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= SET_WRITECLK;
				
			when SET_WRITECLK =>
				initWord_sel<= '0';
				wrAddr_sel	<= '1';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '1';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn      <= '1';
				RamUBn      <= '1';
				nextState	<= WAIT_WRITEDATA;
				
			when WAIT_WRITEDATA =>
				initWord_sel<= '0';
				wrAddr_sel	<= '1';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '1';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn      <= '0';
				RamUBn      <= '0';
				if (RamWait = '0') then
					nextState <= WRITE_DATA;
				else
					nextState <= presentState;
				end if;
				
			when READ_DATA =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '1';
				clkEn		<= '1';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '1';
				RamLBn      <= '0';
				RamUBn      <= '0';
				if (RamWait = '1') then
					nextState <= IDLE;
				else
					nextState <= presentState;
				end if;
				
			when WRITE_DATA =>
				initWord_sel<= '0';
				wrAddr_sel	<= '1';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '1';
				getEntry	<= '1';
				bufWrite	<= '0';
				clkEn		<= '1';
				RamADVn     <= '1';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn		<= '0';
				RamUBn		<= '0';
				nextState	<= IDLE;
			
			when others =>
				initWord_sel<= '0';
				wrAddr_sel	<= '0';
				initCnt_en	<= '0';
				readAddr_en	<= '0';
				MemDB_load	<= '0';
				getEntry	<= '0';
				bufWrite	<= '0';
				clkEn		<= '0';
				RamADVn     <= '0';
				RamCRE      <= '0';
				RamCEn      <= '0';
				RamOEn      <= '0';
				RamWEn      <= '0';
				RamLBn      <= '0';
				RamUBn      <= '0';
				nextState	<= IDLE;
				
		end case;
	end process;


end Behavioral;
