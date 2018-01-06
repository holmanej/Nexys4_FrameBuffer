library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FrameBuffer is
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
end FrameBuffer;

architecture Behavioral of FrameBuffer is
	
	component output_Buffer is
		Port(
			wr_clk		: in  STD_LOGIC;
			rd_clk		: in  STD_LOGIC;
			din			: in  STD_LOGIC_VECTOR (15 downto 0);
			wr_en		: in  STD_LOGIC;
			rd_en		: in  STD_LOGIC;
			dout		: out STD_LOGIC_VECTOR (15 downto 0);
			full		: out STD_LOGIC;
			empty		: out STD_LOGIC;
			prog_empty	: out STD_LOGIC
		);
	end component;
	
	component input_Buffer is
		Port(
			wr_clk		: in  STD_LOGIC;
			rd_clk		: in  STD_LOGIC;
			din			: in  STD_LOGIC_VECTOR (30 downto 0);
			wr_en		: in  STD_LOGIC;
			rd_en		: in  STD_LOGIC;
			dout		: out STD_LOGIC_VECTOR (30 downto 0);
			full		: out STD_LOGIC;
			empty		: out STD_LOGIC
		);
	end component;
	
	component FrBuf_RamInterface is
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
	end component;
	
	component VGADriver is
		Port(
			clk			: in  STD_LOGIC;
			reset		: in  STD_LOGIC;
			active		: out STD_LOGIC;
			hsyncOut	: out STD_LOGIC;
			vsyncOut	: out STD_LOGIC 
		);
	end component;
		
	-- Output Buffer --
	signal outBuf_wrData:	STD_LOGIC_VECTOR (15 downto 0);
	signal outBuf_wrEn	:	STD_LOGIC;
	signal outBuf_rdEn	:	STD_LOGIC;
	signal outBuf_rdData:	STD_LOGIC_VECTOR (15 downto 0);
	signal outBuf_empty	:	STD_LOGIC;
	
	-- Input Buffer --
	signal inBuf_rdEn	:	STD_LOGIC;
	signal inBuf_entry	:	STD_LOGIC_VECTOR (30 downto 0);
	signal inBuf_empty	:	STD_LOGIC;

begin
	
	inBuf: input_Buffer port map (
		wr_clk		=> inputClk,
		rd_clk		=> memClk,
		din			=> inBuf_data,
		wr_en		=> inBuf_wrEn,
		rd_en		=> inBuf_rdEn,
		dout		=> inBuf_entry,
		full		=> inBuf_full,
		empty		=> inBuf_empty
	);
	
	FrBufDriver: FrBuf_RamInterface port map (
		clk			=> memClk,
		reset		=> reset,
		-- write ports --
		wrAddr		=> inBuf_entry(30 downto 12),
		wrData		=> inBuf_entry(11 downto 0),
		wrValid		=> not inBuf_empty,
		getEntry	=> inBuf_rdEn,
		-- read ports --
		bufEmpty	=> outBuf_empty,
		bufWrite	=> outBuf_wrEn,
		bufData		=> outBuf_wrData,
		-- cell ram --
		MemAdr		=> MemAdr,
		MemDB       => MemDB,
		RamWait		=> RamWait,
		RamCLK      => RamCLK,
		RamADVn     => RamADVn,
		RamCRE      => RamCRE,
		RamCEn      => RamCEn,
		RamOEn      => RamOEn,
		RamWEn      => RamWEn,
		RamLBn      => RamLBn,
		RamUBn      => RamUBn
	);
	
	outBuf: output_Buffer port map (
		wr_clk		=> memClk,
		rd_clk		=> pixClk,
		din			=> outBuf_wrData,
		wr_en		=> outBuf_wrEn,
		rd_en		=> outBuf_rdEn,
		dout		=> outBuf_rdData,
		full		=> open,
		empty		=> open,
		prog_empty	=> outBuf_empty
	);
	
	VGA: VGADriver port map (
		clk			=> pixClk,
		reset		=> reset,
		active		=> outBuf_rdEn,
		hsyncOut	=> HSYNC_OUT,
		vsyncOut	=> VSYNC_OUT
	);
	
	RGB_OUT <= outBuf_rdData(11 downto 0) when (outBuf_rdEn = '1') else x"000";

end Behavioral;
