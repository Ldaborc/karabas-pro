library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity bus_port is
	port (

	-- global clocks
	CLK 		: in std_logic;
	CLK2		: in std_logic;
	CLK_BUS 	: in std_logic;
	CLK_CPU 	: in std_logic;
	RESET 	: in std_logic;
	 
	-- physical interface with CPLD
	SD 			: inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	SA 			: out std_logic_vector(1 downto 0);
--	SDIR : out std_logic;
	CPLD_CLK 	: out std_logic;
	CPLD_CLK2	: out std_logic;
	NRESET 		: out std_logic;
	-- OCH: fix fdd swap 
	FDC_SWAP		: in std_logic;

	-- zx bus signals to rx/tx from/to the CPLD controller
	BUS_A 		: in std_logic_vector(4 downto 0);
	BUS_DI 		: in std_logic_vector(7 downto 0);
	BUS_DO 		: out std_logic_vector(7 downto 0);
	BUS_RD_N 	: in std_logic;
	BUS_WR_N 	: in std_logic;
	BUS_HDD_CS_N 		: in std_logic;
	BUS_WWC 		: in std_logic;
	BUS_WWE 		: in std_logic;
	BUS_RWW 		: in std_logic;
	BUS_RWE 		: in std_logic;
	BUS_CS3FX 	: in std_logic;
	BUS_FDC_STEP: in std_logic;
	BUS_CSFF 	: in std_logic;
	BUS_FDC_NCS : in std_logic;	
	
	-- zx bus signals for Nemo HDD 
	BUS_A7				: in std_logic;
	BUS_nemo_ebl_n		: in std_logic;
	BUS_IOW				: in std_logic;
	BUS_WRH 				: in std_logic;
	BUS_IOR 				: in std_logic;
	BUS_RDH 				: in std_logic;
	BUS_nemo_cs0		: in std_logic;
	BUS_nemo_cs1		: in std_logic
	);
    end bus_port;
architecture RTL of bus_port is

signal cnt			: std_logic_vector(1 downto 0) := "00";
signal prev_clk_cpu : std_logic := '0';
signal bus_a_reg	: std_logic_vector(15 downto 0);
signal bus_d_reg	: std_logic_vector(7 downto 0);
signal fdd_id : std_logic_vector(1 downto 0);
begin
	
	CPLD_CLK <= CLK;
	CPLD_CLK2 <= CLK2;
	NRESET <= not reset;
	SA <= cnt;	
	BUS_DO <= SD(15 downto 8);
	-- OCH: fix fdd swap 
	fdd_id <= "00" when bus_di(1 downto 0) = "01" else
				 "01" when bus_di(1 downto 0) = "00" else
				  bus_di(1 downto 0);
	process (CLK, BUS_HDD_CS_N, BUS_FDC_NCS, BUS_CSFF, BUS_CS3FX, BUS_RWE, BUS_RWW, BUS_WWE, BUS_WWC, BUS_FDC_STEP, BUS_RD_N, BUS_WR_N, bus_a, bus_di)
	begin 
		if CLK'event and CLK = '1' then
			if cnt = "10" and BUS_nemo_ebl_n ='0' then
					bus_a_reg <= BUS_nemo_ebl_n & BUS_FDC_NCS & BUS_CSFF & BUS_nemo_cs1 & BUS_RDH & BUS_IOR & 
									 BUS_IOW & BUS_WRH & BUS_FDC_STEP & BUS_RD_N & BUS_WR_N & BUS_A7 & BUS_A(1 downto 0) & BUS_nemo_cs1 & BUS_nemo_cs0;
			elsif cnt = "10" then 
					bus_a_reg <= BUS_HDD_CS_N & BUS_FDC_NCS & BUS_CSFF & BUS_CS3FX & BUS_RWE & BUS_RWW & 
									 BUS_WWE & BUS_WWC & BUS_FDC_STEP & BUS_RD_N & BUS_WR_N & bus_a;
			end if;
			-- OCH: fix fdd swap 
			if BUS_CSFF = '0' and FDC_SWAP = '1' then
				bus_d_reg <= bus_di(7 downto 2) & fdd_id;
			else
				bus_d_reg <= bus_di;
			end if;
		end if;
	end process;

	process (RESET, CLK, cnt, prev_clk_cpu)
	begin 
		if RESET = '1' then 
			cnt <= "11";
		elsif CLK'event and CLK = '1' then
			if (cnt < 2) then 
				cnt <= cnt + 1;
			else 
				cnt <= "00";
			end if;
		end if;
	end process;

	UMUX: entity work.bus_mux
	port map(
		data0x => bus_a_reg(15 downto 8),
		data1x => bus_a_reg(7 downto 0),
		data2x => bus_d_reg,
		data3x => "11111111",
		sel => cnt,
		result => SD(7 downto 0)
	);

end RTL;

