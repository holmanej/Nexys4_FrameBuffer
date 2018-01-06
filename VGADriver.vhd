library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGADriver is
	Port(
		clk			: in  STD_LOGIC;
		reset		: in  STD_LOGIC;
		active		: out STD_LOGIC;
		vsyncOut	: out STD_LOGIC;
		hsyncOut	: out STD_LOGIC 
	);
end VGADriver;

architecture Behavioral of VGADriver is

	constant horizontal_width	:	INTEGER := 1056;
	constant horizontal_sync	:	INTEGER := 128;
	constant horizontal_front	:	INTEGER := 40;
	constant horizontal_back	:	INTEGER := 88;
	
	constant vertical_width		:	INTEGER := 628;
	constant vertical_sync		:	INTEGER := 4;
	constant vertical_front		:	INTEGER := 1;
	constant vertical_back		:	INTEGER := 23;
	
	constant vertical_polarity	:	STD_LOGIC := '1';
	constant horizontal_polarity:	STD_LOGIC := '1';
	
	constant left_edge			:	INTEGER := horizontal_front + horizontal_sync;
	constant right_edge			:	INTEGER := horizontal_width - horizontal_back;
	constant top_edge			:	INTEGER := vertical_front + vertical_sync;
	constant bottom_edge		:	INTEGER := vertical_width - vertical_back;

	signal horizontal_count		:	UNSIGNED (11 downto 0) := (others => '0');
	signal vertical_count		:	UNSIGNED (10 downto 0) := (others => '0');
	
begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			if (reset = '1') then
				vertical_count <= (others => '0');
				horizontal_count <= (others => '0');
			else
				if (vertical_count = vertical_width) then
					vertical_count <= (others => '0');
				end if;
				
				if (horizontal_count = horizontal_width) then
					vertical_count <= vertical_count + 1;
					horizontal_count <= (others => '0');
				else
					horizontal_count <= horizontal_count + 1;
				end if;
				
				if (horizontal_count > left_edge and horizontal_count <= right_edge and vertical_count > top_edge and vertical_count <= bottom_edge) then
					active <= '1';
				else
					active <= '0';
				end if;
				
				if (horizontal_count < horizontal_sync) then
					hsyncOut <= horizontal_polarity;
				else
					hsyncOut <= not horizontal_polarity;
				end if;
				
				if (vertical_count < vertical_sync) then
					vsyncOut <= vertical_polarity;
				else
					vsyncOut <= not vertical_polarity;
				end if;
			end if;
		end if;
	end process;

end Behavioral;