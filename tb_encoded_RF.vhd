library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity TBREGISTERFILE is
end TBREGISTERFILE;

architecture TESTA of TBREGISTERFILE is
component register_file is
	generic(
		nbit_addr: integer := 32;
		nbit_reg: integer := 64;
		n_reg: integer := 32
	);
	port (
		CLK: 		IN std_logic;
		RESET: 	IN std_logic;
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
constant M : integer := 5;		--# of Global registers 
constant N : integer := 4;		--# of regs in IN, OUT and LOCAL
constant F : integer := 3;		--# of windows

constant S1 : integer := ((3*N)+(M-1));
constant S2 : integer := S1;

constant nbit_addr: integer := (M+((F-1)*(N*3)));
constant nbit_reg: integer := 8;
constant n_reg: integer := (M+((F-1)*(N*3)));
constant T : integer := 20;
signal CLK: std_logic := '0';
signal RESET: std_logic := '1';
signal ENABLE: std_logic := '0';
signal RD1: std_logic := '0';
signal RD2: std_logic := '0';
signal WR: std_logic := '0';
signal ADD_WR: std_logic_vector(nbit_addr-1 downto 0) := '1'&(nbit_addr-2 downto 0 => '0');
signal ADD_RD1: std_logic_vector(nbit_addr-1 downto 0) := '1'&(nbit_addr-2 downto 0 => '0');
signal ADD_RD2: std_logic_vector(nbit_addr-1 downto 0) := (others => '0');
signal DATAIN: std_logic_vector(nbit_reg-1 downto 0) := (others => '0');
signal OUT1: std_logic_vector(nbit_reg-1 downto 0) := (others => '0');
signal OUT2: std_logic_vector(nbit_reg-1 downto 0) := (others => '0');
begin 
	RG:register_file generic map(nbit_addr, nbit_reg, n_reg)
	PORT MAP (CLK,RESET,ENABLE,RD1,RD2,WR,ADD_WR,ADD_RD1,ADD_RD2,DATAIN,OUT1,OUT2);
	process(CLK)
	variable tmp : std_logic_vector(T-1 downto 0) := '1'&(T-1 downto 1 => '0');
	variable buffA, buffB, buffC : std_logic_vector(nbit_addr-1 downto 0) := '1'&(nbit_addr-1 downto 1 => '0');
	variable zero : std_logic_vector(nbit_addr-1 downto 0) := (others => '0');
	begin
		if(CLK'event and CLK = '1') then
			RESET <= '0';
			--write something
			if (tmp(T-2 downto T-5) /= 0) then
				ENABLE <= '1';
				WR <= '1';
				if (tmp(T-3) /= '1') then
					buffA := buffA(0)&buffA(nbit_addr-1 downto 1);
					ADD_WR <= buffA;																		--M range
				else
					buffC := (others => '0');
					buffC((M+(3*N))-1) := '1';
					ADD_WR <= zero(S1-1 downto 0)&buffC((M+((F-1)*(N*3)))-1 downto S1);																		--M range
				end if;
			end if;
			if (tmp(T-3 downto T-6) /= 0) then
				DATAIN <= DATAIN + 3;
				if (tmp(T-6) = '1') then WR <= '0';
				end if;
				---ADD_RD1 <= std_logic_vector(to_unsigned(2, ADD_RD1'length));
			end if;
			--read something
			if (tmp(T-8 downto T-13) /= 0) then
				if (tmp(T-13) = '1') then RD1 <= '0';
				else RD1 <= '1';
				end if;
				if (tmp(T-11) /= '1') then
					buffB := buffB(0)&buffB(nbit_addr-1 downto 1);
					ADD_RD1 <= buffB;																			--M range
				else
					buffC := (others => '0');
					buffC((M+(3*N))-1) := '1';
					ADD_RD1 <= zero(S2-1 downto 0)&buffC((M+((F-1)*(N*3)))-1 downto S2);																			--M range
				end if;
			end if;
			--increment time
			tmp := '0'&tmp(T-1 downto 1);	--tmp >> 1
		end if;
	end process;
	PCLOCK : process(CLK)
	begin
		CLK <= not(CLK) after 0.5 ns;	
	end process;
end TESTA;