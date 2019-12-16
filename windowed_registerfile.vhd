library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity windowed_register_file is
	generic(
		M : integer := 5;		--# of Global registers 
		N : integer := 4;		--# of regs in IN, OUT and LOCAL
		F : integer := 3;		--# of windows
		nbit_addr: integer := 6;
		nbit_reg: integer := 8;
		nbit_addr_MMU: integer := 6;
		nbit_addr_MMU_enc: integer := 44
	);
	port (
		CLK: 		IN std_logic;
		RESET: 		IN std_logic;
		ENABLE: 	IN std_logic;
		RD1: 		IN std_logic;
		RD2: 		IN std_logic;
		WR: 		IN std_logic;
		ADD_WR: 	IN std_logic_vector(nbit_addr-1 downto 0);
		ADD_RD1: 	IN std_logic_vector(nbit_addr-1 downto 0);
		ADD_RD2: 	IN std_logic_vector(nbit_addr-1 downto 0);
		DATAIN: 	IN std_logic_vector(nbit_reg-1 downto 0);
		OUT1: 		OUT std_logic_vector(nbit_reg-1 downto 0);
		OUT2: 		OUT std_logic_vector(nbit_reg-1 downto 0);
		
		CALL:		IN std_logic;
		RET:		IN std_logic;
		BUSY:		OUT std_logic;
		
		MMU_EN:		OUT std_logic;
		MMU_W_R:	OUT std_logic;
		MMU_ADD:	OUT std_logic_vector(nbit_addr_MMU-1 downto 0);
		MMU_D_IN:	OUT std_logic_vector(nbit_reg-1 downto 0);
		MMU_D_OUT:	IN std_logic_vector(nbit_reg-1 downto 0)
	);
end windowed_register_file;

architecture BEHAVIOURAL of windowed_register_file is
	component register_file is
		generic(
			nbit_addr: integer := 32;
			nbit_reg: integer := 64;
			n_reg: integer := 32
		);
		port (
			CLK: 		IN std_logic;
			RESET:		IN std_logic;
			ENABLE: 	IN std_logic;
			RD1: 		IN std_logic;
			RD2: 		IN std_logic;
			WR: 		IN std_logic;
			ADD_WR: 	IN std_logic_vector(nbit_addr-1 downto 0);
			ADD_RD1: 	IN std_logic_vector(nbit_addr-1 downto 0);
			ADD_RD2: 	IN std_logic_vector(nbit_addr-1 downto 0);
			DATAIN: 	IN std_logic_vector(nbit_reg-1 downto 0);
			OUT1: 		OUT std_logic_vector(nbit_reg-1 downto 0);
			OUT2: 		OUT std_logic_vector(nbit_reg-1 downto 0)
		);
	end component;
	component priority_encoder is
		generic(
			nbit_addr_MMU: integer := 8;
			nbit_addr_MMU_enc: integer := 7
		);
		port (
			A: 	IN std_logic_vector(nbit_addr_MMU_enc-1 downto 0);
			B: 	OUT std_logic_vector(nbit_addr_MMU-1 downto 0)
		);
	end component;
	function shifter (
		A : std_logic_vector(nbit_addr-1 downto 0) := (others => '0');
		B : std_logic_vector((M+(((F-1)*(N*3))+N))-1 downto 0) := (others => '0'))
	return std_logic_vector is
	variable tmp : std_logic_vector((M+(((F-1)*(N*3))+N))-1 downto 0);
	variable I : integer;
	begin
		I := 0;
		tmp := B;
		while (I < to_integer(unsigned(A))) loop
			tmp := '0'&tmp((M+(((F-1)*(N*3))+N))-1 downto 1);
			I := I + 1;
		end loop;
		return tmp;
	end shifter;
	signal ADD_WRs, ADD_RD1s, ADD_RD2s : std_logic_vector((M+(((F-1)*(N*3))+N))-1 downto 0) := (others => '0');
	signal MMU_ADDs : std_logic_vector(nbit_addr_MMU_enc-1 downto 0) := (others => '0');
	signal DATAINs, OUT1s, OUT2s : std_logic_vector(nbit_reg-1 downto 0) := (others => '0');
	signal RD1s, RD2s, WRs : std_logic := '0';
begin
	rfp : register_file generic map(nbit_addr => (M+(((F-1)*(N*3))+N)), nbit_reg => nbit_reg, n_reg => (M+(((F-1)*(N*3))+N))) port map(CLK, RESET, ENABLE, RD1s, RD2s, WRs, ADD_WRs, ADD_RD1s, ADD_RD2s, DATAINs, OUT1s, OUT2s);
	pe : priority_encoder generic map(nbit_addr_MMU, nbit_addr_MMU_enc) port map(MMU_ADDs, MMU_ADD);
	process(CLK, RESET, RD1, RD2, WR, ADD_WR, ADD_RD1, ADD_RD2, DATAIN, OUT1s, OUT2s, MMU_D_OUT)
	variable CWP, CWP_tmp : std_logic_vector((((F-1)*(N*3))+N)-1 downto 0):= '1'&((((F-1)*(N*3))+N)-2 downto 0 => '0');	--CWP has as many bits as RS minus the global registers (M)
	variable SWP, SWP_tmp : std_logic_vector(nbit_addr_MMU_enc-1 downto 0):= '1'&(nbit_addr_MMU_enc-2 downto 0 => '0');
	variable CANSAVE, hold_tx, hold_rx : std_logic := '0';	--flags. I don't use CANRESTORE.
	variable cnt : std_logic_vector((2*N) downto 0) := (others => '0');	--clock cycles for transferring from RF's IN and LOCAL blocks
	variable temp : std_logic_vector((M+(((F-1)*(N*3))+N))-1 downto 0) := (others => '0');
	begin
		if (CLK'event and CLK = '1') then
			if (RESET = '1') then
				CWP := '1'&((((F-1)*(N*3))+N)-2 downto 0 => '0');
				SWP := '1'&(nbit_addr_MMU_enc-2 downto 0 => '0');
				CANSAVE := '0';
				hold_tx := '0';
				hold_rx := '0';
				cnt := (others => '0');
				MMU_EN <= '0';
				MMU_W_R <= '0';
				MMU_ADDs <= (others => '0');
				MMU_D_IN <= (others => '0');
				BUSY <= '0';
				RD1s <= '0';
				RD2s <= '0';
				WRs <= '0';
				ADD_WRs <= (others => '0');
				ADD_RD1s <= (others => '0');
				ADD_RD2s <= (others => '0');
				DATAINs <= (others => '0');
			else
				if (ENABLE = '1') then
					if ((CALL = '1' and RET = '0') and (hold_tx = '0' and hold_rx = '0')) then
						CWP := ((2*N)-1 downto 0 => '0')&CWP((((F-1)*(N*3))+N)-1 downto (2*N));	--CWP >> (2*N)
						if (CWP(N-1) = '1') then
							CWP := '1'&((((F-1)*(N*3))+N)-2 downto 0 => '0');					--CWP = 1
							CANSAVE := '1';
						end if;
					end if;
					if ((CANSAVE = '1' and (CALL = '1' and RET = '0')) and (hold_tx = '0' and hold_rx = '0')) then
						BUSY <= '1';
						hold_tx := '1';
						cnt := (others => '0');
						CWP_tmp := CWP;
						SWP_tmp := SWP;
					end if;
					if ((CANSAVE = '1' and (RET = '1' and CALL = '0')) and (hold_tx = '0' and hold_rx = '0')) then
						BUSY <= '1';
						hold_rx := '1';
						cnt := (others => '0');
						if (SWP /= ('1'&(nbit_addr_MMU_enc-2 downto 0 => '0'))) then SWP := SWP(nbit_addr_MMU_enc-1-(2*N) downto 0)&((2*N)-1 downto 0 => '0');	--SWP << (2*N) (decremento all'area di memoria non vuota)
						end if;
						if (SWP = ('1'&(nbit_addr_MMU_enc-2 downto 0 => '0'))) then CANSAVE := '0';
						end if;
						CWP_tmp := CWP;
						SWP_tmp := SWP;
					elsif ((RET = '1' and CALL = '0') and (hold_tx = '0' and hold_rx = '0')) then
						if (CWP /= ('1'&((((F-1)*(N*3))+N)-2 downto 0 => '0'))) then CWP := CWP((((F-1)*(N*3))+N)-1-(2*N) downto 0)&((2*N)-1 downto 0 => '0');	--CWP << (2*N)
						end if;
					end if;
					if (hold_tx = '1') then
						if (cnt(1 downto 0) = "00") then
							MMU_EN <= '1';
							MMU_W_R <= '0';		--write command
							RD1s <= '1';
							MMU_ADDs <= SWP_tmp;						--I send the address window size * 3 TIMES to the MMU
							ADD_RD1s <= CWP_tmp&(M-1 downto 0 => '0');	--I send the address window size * 3 TIMES to the RF
							SWP_tmp := '0'&SWP_tmp(nbit_addr_MMU_enc-1 downto 1);	--SWP >> 1
							CWP_tmp := '0'&CWP_tmp((((F-1)*(N*3))+N)-1 downto 1); 		--CWP >> 1
						else
							if (cnt(1) = '1') then
								SWP := ((2*N)-1 downto 0 => '0')&SWP(nbit_addr_MMU_enc-1 downto (2*N));	--SWP >> (2*N) (incremento ad una area libera dello stack)
								if (SWP = 0) then SWP := (nbit_addr_MMU_enc-1 downto (2*N) => '0')&'1'&((2*N)-1 downto 1 => '0');	--stay in the last position
								end if;
								MMU_EN <= '0';
								RD1s <= '0';
								MMU_ADDs <= (others => '0');
								ADD_RD1s <= (others => '0');
							else
								BUSY <= '0';
								hold_tx := '0';
								MMU_D_IN <= (others => '0');
							end if;
						end if;
						if (cnt /= 0) then cnt := '0'&cnt((2*N) downto 1);	--cnt >> 1
						else cnt := '1'&((2*N) downto 1 => '0');			--cnt >> 1
						end if;
					end if;
					if (hold_rx = '1') then
						if (cnt(1 downto 0) = "00") then
							MMU_EN <= '1';
							MMU_W_R <= '1';		--read command
							WRs <= '1';
							MMU_ADDs <= SWP_tmp;						--I send window size * 3 TIMES the address to the MMU
							ADD_WRs <= CWP_tmp&(M-1 downto 0 => '0');	--I send the address window size * 3 TIMES to the RF
							SWP_tmp := '0'&SWP_tmp(nbit_addr_MMU_enc-1 downto 1);
							CWP_tmp := '0'&CWP_tmp((((F-1)*(N*3))+N)-1 downto 1);
						else
							if (cnt(1) = '1') then
								if (CWP /= ('1'&((((F-1)*(N*3))+N)-2 downto 0 => '0'))) then CWP := CWP((((F-1)*(N*3))+N)-1-(2*N) downto 0)&((2*N)-1 downto 0 => '0');	--CWP << (2*N) (after replaced all flies I decrement to the previous window)
								end if;
								MMU_EN <= '0';
								WRs <= '0';
								MMU_ADDs <= (others => '0');
								ADD_WRs <= (others => '0');
							else
								BUSY <= '0';
								hold_rx := '0';
								DATAINs <= (others => '0');
							end if;
						end if;
						if (cnt /= 0) then cnt := '0'&cnt((2*N) downto 1);	--cnt >> 1
						else cnt := '1'&((2*N) downto 1 => '0');			--cnt >> 1
						end if;
					end if;
				end if;
			end if;
		end if;
		if ((hold_tx = '0' and hold_rx = '0') and (CALL = '0' and RET = '0') and (ENABLE = '1' and RESET = '0')) then
			RD1s <= RD1;
			OUT1 <= OUT1s;
			RD2s <= RD2;
			OUT2 <= OUT2s;
			WRs <= WR;
			DATAINs <= DATAIN;
			if (RD1 = '1' and WR = '0') then
				if (ADD_RD1 < (3*N)) then
					ADD_RD1s <= shifter(ADD_RD1, (CWP((((F-1)*(N*3))+N)-1 downto 0)&(M-1 downto 0 => '0')));
				else
					temp := (others => '0');
					temp((M+(3*N))-1) := '1';
					ADD_RD1s <= shifter(ADD_RD1, temp((M+(((F-1)*(N*3))+N))-1 downto 0));
				end if;
			end if;
			if (RD2 = '1' and WR = '0') then
				if (ADD_RD2 < (3*N)) then
					ADD_RD2s <= shifter(ADD_RD2, (CWP((((F-1)*(N*3))+N)-1 downto 0)&(M-1 downto 0 => '0')));
				else
					temp := (others => '0');
					temp((M+(3*N))-1) := '1';
					ADD_RD2s <= shifter(ADD_RD2, temp((M+(((F-1)*(N*3))+N))-1 downto 0));
				end if;
			end if;
			if (WR = '1' and (RD1 = '0' and RD2 = '0')) then
				if (ADD_WR < (3*N)) then
					ADD_WRs <= shifter(ADD_WR, (CWP((((F-1)*(N*3))+N)-1 downto 0)&(M-1 downto 0 => '0')));
				else
					temp := (others => '0');
					temp((M+(3*N))-1) := '1';
					ADD_WRs <= shifter(ADD_WR, temp((M+(((F-1)*(N*3))+N))-1 downto 0));
				end if;
			end if;
		end if;
		if ((hold_tx = '1' or hold_rx = '1') and (ENABLE = '1' and RESET = '0')) then
			if (hold_tx = '1') then
				if (cnt /= 0 and cnt(0) /= '1') then MMU_D_IN <= OUT1s;		--I send data window size * 3 TIMES
				end if;
			else
				if (cnt /= 0 and cnt(0) /= '1') then DATAINs <= MMU_D_OUT;	--I retrieve data window size * 3 TIMES
				end if;
			end if;
		end if;
	end process;
end BEHAVIOURAL;