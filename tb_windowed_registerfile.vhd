library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_windowed_register_file is
end tb_windowed_register_file;

architecture TEST of tb_windowed_register_file is
component windowed_register_file is
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
end component;
constant M : integer := 5;		--# of Global registers 
constant N : integer := 4;		--# of regs in IN, OUT and LOCAL
constant F : integer := 3;		--# of windows
constant nbit_addr : integer := 6;
constant nbit_reg : integer := 8;
constant nbit_addr_MMU : integer := 6;
constant nbit_addr_MMU_enc: integer := 44;
constant T : integer := 100;
constant Period : time := 1 ns; -- Clock period (1 GHz)
signal RESET : std_logic := '1';
signal CLK, ENABLE, RD1, RD2, WR, CALL, RET, BUSY, MMU_EN, MMU_W_R : std_logic := '0';
signal ADD_WR, ADD_RD1, ADD_RD2 : std_logic_vector(nbit_addr-1 downto 0) := (others => '0');
signal DATAIN, OUT1, OUT2, MMU_D_IN, MMU_D_OUT: std_logic_vector(nbit_reg-1 downto 0) := (others => '0');
signal MMU_ADD: std_logic_vector(nbit_addr_MMU-1 downto 0) := (others => '0');
begin
	dut : windowed_register_file
		generic map(M, N, F, nbit_addr, nbit_reg, nbit_addr_MMU, nbit_addr_MMU_enc)
		port map(CLK, RESET, ENABLE, RD1, RD2, WR, ADD_WR, ADD_RD1, ADD_RD2, DATAIN, OUT1, OUT2, CALL, RET, BUSY, MMU_EN, MMU_W_R, MMU_ADD, MMU_D_IN, MMU_D_OUT);
	CLK <= not CLK after Period/2;
	process(CLK)
	variable tmp : std_logic_vector(T-1 downto 0) := '1'&(T-1 downto 1 => '0');
	variable buffA, buffB : std_logic_vector(nbit_addr-1 downto 0) := (others => '0');
	begin
		if(CLK'event and CLK = '1') then
			RESET <= '0';
			--write something
			if (tmp(T-2 downto T-5) /= 0) then
				ENABLE <= '1';
				WR <= '1';
				if (tmp(T-3) /= '1') then
					buffA := buffA + 1;
					ADD_WR <= buffA;																				--M range
				else  ADD_WR <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_WR'length));	--M range
				end if;
			end if;
			if (tmp(T-3 downto T-6) /= 0) then
				DATAIN <= DATAIN + 3;
				if (tmp(T-6) = '1') then WR <= '0';
				end if;
			end if;
			--read something
			if (tmp(T-8 downto T-13) /= 0) then
				if (tmp(T-13) = '1') then RD1 <= '0';
				else RD1 <= '1';
				end if;
				if (tmp(T-11) /= '1') then
					buffB := buffB + 1;
					ADD_RD1 <= buffB;																					--M range
				else  ADD_RD1 <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_RD1'length));	--M range
				end if;
			end if;
			--CALL #1
			if (tmp(T-14 downto T-15) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-14) = '1') then CALL <= '1';
				else CALL <= '0';
				end if;
			end if;
			--read something
			if (tmp(T-16 downto T-21) /= 0) then
				if (tmp(T-21) = '1') then RD1 <= '0';
				else RD1 <= '1';
				end if;
				if (tmp(T-19) /= '1') then
					buffB := buffB + 1;
					ADD_RD1 <= buffB;																					--M range
				else  ADD_RD1 <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_RD1'length));	--M range
				end if;
			end if;
			--write something
			if (tmp(T-22 downto T-27) /= 0) then
				buffB := (others => '0');
				ENABLE <= '1';
				WR <= '1';
				if (tmp(T-27) /= '1') then
					buffA := buffA + 1;
					ADD_WR <= buffA;																				--M range
				else  ADD_WR <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_WR'length));	--M range
				end if;
			end if;
			if (tmp(T-23 downto T-28) /= 0) then
				DATAIN <= DATAIN + 3;
				if (tmp(T-28) = '1') then WR <= '0';
				end if;
			end if;
			--read something
			if (tmp(T-29 downto T-34) /= 0) then
				if (tmp(T-34) = '1') then RD1 <= '0';
				else RD1 <= '1';
				end if;
				if (tmp(T-32) /= '1') then
					buffB := buffB + 1;
					ADD_RD1 <= buffB;																					--M range
				else  ADD_RD1 <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_RD1'length));	--M range
				end if;
			end if;
			--RET #1
			if (tmp(T-35 downto T-36) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-35) = '1') then RET <= '1';
				else RET <= '0';
				end if;
			end if;
			--read something
			if (tmp(T-37 downto T-42) /= 0) then
				if (tmp(T-42) = '1') then RD1 <= '0';
				else RD1 <= '1';
				end if;
				if (tmp(T-38) /= '1') then
					buffB := buffB + 1;
					ADD_RD1 <= buffB;																					--M range
				else  ADD_RD1 <= std_logic_vector(to_unsigned(((3*N)+(M-1)), ADD_RD1'length));	--M range
				end if;
			end if;
			--CALL #1#2#3
			if (tmp(T-43 downto T-46) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-46) = '1') then CALL <= '0';
				else CALL <= '1';
				end if;
			end if;
			--CALL #4
			if (tmp(T-55 downto T-56) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-55) = '1') then CALL <= '1';
				else CALL <= '0';
				end if;
			end if;
			--RET #4
			if (tmp(T-65 downto T-66) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-66) = '1') then RET <= '0';
				else RET <= '1';
				end if;
			end if;
			--RET #3
			if (tmp(T-75 downto T-76) /= 0) then
				buffA := (others => '0');
				buffB := (others => '0');
				if (tmp(T-76) = '1') then RET <= '0';
				else RET <= '1';
				end if;
			end if;
			--increment time
			tmp := '0'&tmp(T-1 downto 1);	--tmp >> 1
		end if;
	end process;
end TEST;