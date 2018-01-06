library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Nexys4_FrameBuffer is
	Port(
		CLK			: in  STD_LOGIC;
		SWITCHES	: in  STD_LOGIC_VECTOR (11 downto 0);
		-- vga --
		VSYNC_OUT	: out STD_LOGIC;
		HSYNC_OUT	: out STD_LOGIC;
		RGB_OUT		: out STD_LOGIC_VECTOR (11 downto 0);
		-- cell ram --
		MemAdr      : out STD_LOGIC_VECTOR (22 downto 0);
		MemDB       : inout STD_LOGIC_VECTOR (15 downto 0) := (others => 'Z');
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
end Nexys4_FrameBuffer;

architecture Behavioral of Nexys4_FrameBuffer is

	component FrameBufferClock is
		Port(
			clk_in1		: in  STD_LOGIC;
			reset		: in  STD_LOGIC;
			locked		: out STD_LOGIC;
			gpuClk		: out STD_LOGIC;
			memClk		: out STD_LOGIC;
			pixClk		: out STD_LOGIC
		);
	end component;
	
	component FrameBuffer is
		Port(
			-- data in --
			inputClk	: in  STD_LOGIC;
			reset		: in  STD_LOGIC;
			inBuf_wrEn	: in  STD_LOGIC;
			inBuf_full	: out STD_LOGIC;
			inBuf_data	: in  STD_LOGIC_VECTOR (30 downto 0);
			-- vga port --
			pixClk		: in  STD_LOGIC;
			RGB_OUT		: out STD_LOGIC_VECTOR (11 downto 0);
			HSYNC_OUT	: out STD_LOGIC;
			VSYNC_OUT	: out STD_LOGIC;
			-- cell ram --
			memClk		: in  STD_LOGIC;
			MemAdr      : out STD_LOGIC_VECTOR (22 downto 0);
			MemDB       : inout STD_LOGIC_VECTOR (15 downto 0) := (others => 'Z');
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
	end component;
	
	signal addrCnt		:	UNSIGNED (18 downto 0);
	signal bufFull		:	STD_LOGIC;

	signal gpuClk		:	STD_LOGIC;
	signal pixClk		:	STD_LOGIC;
	signal memClk		:	STD_LOGIC;
	
begin

	clockWiz: FrameBufferClock port map (
		clk_in1		=> CLK,
		reset		=> '0',
		locked		=> open,
		gpuClk		=> gpuClk,
		memClk		=> memClk,
		pixClk		=> pixClk
	);

	process(CLK)
	begin
		if (rising_edge(CLK)) then
			if (addrCnt = 480000) then
				addrCnt <= (others => '0');
			elsif (bufFull = '0') then
				addrCnt <= addrCnt + 1;
			end if;
		end if;
	end process;
	
	FrBuf: FrameBuffer port map (
		-- data in --
		inputClk	=> CLK,
		reset		=> '0',
		inBuf_wrEn	=> not bufFull,
		inBuf_full	=> bufFull,
		inBuf_data	=> std_logic_vector(addrCnt) & SWITCHES,
		-- vga port --
		pixClk		=> pixClk,
		RGB_OUT		=> RGB_OUT,
		HSYNC_OUT	=> HSYNC_OUT,
		VSYNC_OUT	=> VSYNC_OUT,
		-- cell ram --
		memClk		=> CLK,
		MemAdr      => MemAdr,
		MemDB       => MemDB,
		RamWait		=> RamWait,
		RamCLK      => RamCLK,
		RamADVn     => RamADVn,
		RamCRE      => RamCRE,
		RamCEn      => RamCEn,
		RamOEn      => RamOEn,
		RamWEn      => RamWEn,
		RamLBn      => RaMLBn,
		RamUBn      => RamUBn
	);

end Behavioral;
