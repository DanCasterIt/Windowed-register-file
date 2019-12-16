library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_priority_encoder is
end tb_priority_encoder;

architecture TEST of tb_priority_encoder is
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
constant Period : time := 1 ns; -- Clock period (1 GHz)
constant nbit_addr_MMU: integer := 8;
constant nbit_addr_MMU_enc: integer := 7;
signal CLK : std_logic := '0';
signal As : std_logic_vector(nbit_addr_MMU_enc-1 downto 0) := (others => '0');
signal Bs : std_logic_vector(nbit_addr_MMU-1 downto 0) := (others => '0');
begin
	dut: priority_encoder generic map(nbit_addr_MMU, nbit_addr_MMU_enc) port map(As, Bs);
	CLK <= not CLK after Period/2;
	process(CLK)
	variable tmp : std_logic_vector(nbit_addr_MMU_enc-1 downto 0) := '1'&(nbit_addr_MMU_enc-1 downto 1 => '0');
	begin
		if(CLK'event and CLK = '1') then
			As <= tmp;
			tmp := '0'&tmp(nbit_addr_MMU_enc-1 downto 1);
			if(tmp = 0) then	tmp := (nbit_addr_MMU_enc-1 downto 6 => '0')&"1001"&(1 downto 0 => '0');
			end if;
		end if;
	end process;
end TEST;