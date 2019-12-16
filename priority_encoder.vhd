library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity priority_encoder is
	generic(
		nbit_addr_MMU: integer := 8;
		nbit_addr_MMU_enc: integer := 7
	);
	port (
		A: 	IN std_logic_vector(nbit_addr_MMU_enc-1 downto 0);
		B: 	OUT std_logic_vector(nbit_addr_MMU-1 downto 0)
	);
end priority_encoder;

architecture BEHAVIOURAL of priority_encoder is
begin
	process(A)
	variable I : integer;
	begin
		if (A /=  (nbit_addr_MMU_enc-1 downto 0 => '0')) then
			I := 0;
			while (A(I) = '0' and I < nbit_addr_MMU_enc-1) loop
				I := I + 1;
			end loop;
			I := I + 1;
			B <= std_logic_vector(to_unsigned(nbit_addr_MMU_enc-I, B'length));
		else
			B <= (others => '0');
		end if;
	end process;
end BEHAVIOURAL;