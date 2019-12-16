library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--use WORK.constants.all;
--use WORK.all;

entity register_file is
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
end register_file;

architecture A of register_file is
    -- suggested structures
    subtype REG_ADDR is natural range 0 to n_reg-1; -- using natural type
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(nbit_reg-1 downto 0); 
	signal REGISTERS : REG_ARRAY := ((others=> (others=>'0')));
	signal ADD_RD1s, ADD_rd2s, ADD_WRs : std_logic_vector(nbit_addr-1 downto 0) := (others=>'0');
	
begin 
-- write your RF code 
reg: process(CLK)
	begin
	--
	--
	
	
	if(CLK'event and CLK = '1') then
	---- RESET SYNCHRONOUS ----
	if(RESET = '1') then
		REGISTERS <= (others => (others => '0'));
			else
			if(ENABLE = '1') then
				if(WR = '1')  then
					--REGISTERS(to_integer(unsigned(ADD_WR))) <= DATAIN;
					ADD_WRs <= ADD_WR;
					for i in 0 to nbit_addr-1 loop
						if(ADD_WRs(i) = '1')then
						   REGISTERS(nbit_addr-1-i) <= DATAIN;
						end if;
					end loop;
				end if;
				---
				if (WR = '0' and to_integer(unsigned(ADD_WRs)) /= 0)then
						for i in 0 to nbit_addr-1 loop
						if(ADD_WRs(i) = '1')then
						   REGISTERS(nbit_addr-1-i) <= DATAIN;
						end if;
					end loop;
				ADD_WRs <= (others => '0');
				end if;
				---
				if(RD1 = '1')then
					--OUT1 <= REGISTERS(to_integer(unsigned(ADD_RD1)));
						ADD_RD1s <= ADD_RD1;
			    		for j in 0 to nbit_addr-1 loop
						if(ADD_RD1(j) = '1') then
						   OUT1 <= REGISTERS(nbit_addr-j-1);
						end if;
					end loop;
				end if;
				---
				if (RD1 = '0' and to_integer(unsigned(ADD_RD1s)) /= 0)then
						for j in 0 to nbit_addr-1 loop
						if(ADD_RD1s(j) = '1')then
						   OUT1 <= REGISTERS(nbit_addr-j-1);
						end if;
					end loop;
				ADD_RD1s <= (others => '0');
				end if;
				---
				if(RD2 = '1')then
					--OUT2 <= REGISTERS(to_integer(unsigned(ADD_RD2)));
					ADD_RD2s <= ADD_RD2;
					for k in 0 to nbit_addr-1 loop
						if(ADD_RD2(k) = '1') then
						   OUT2 <= REGISTERS(nbit_addr-1-k);
						end if;
					end loop;
				end if;
				---
				if (RD2 = '0' and to_integer(unsigned(ADD_RD2s)) /= 0)then
						for k in 0 to nbit_addr-1 loop
						if(ADD_RD2s(k) = '1')then
						   OUT1 <= REGISTERS(nbit_addr-k-1);
						end if;
					end loop;
				ADD_RD2s <= (others => '0');
				end if;
				---
			end if;
	  end if;
	end if;
end process reg;
end A;

configuration CFG_RF_BEH of register_file is
  for A
  end for;
end configuration;
