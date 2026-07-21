library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity crc32 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        calc_en  : in  std_logic;
        crc_out  : out std_logic_vector(31 downto 0)
    );
end entity crc32;

architecture Behavioral of crc32 is
    signal crc_reg : std_logic_vector(31 downto 0) := (others => '1');
begin
    process(clk, rst)
        variable d   : std_logic_vector(7 downto 0);
        variable c   : std_logic_vector(31 downto 0);
        variable new_c : std_logic_vector(31 downto 0);
    begin
        if rst = '1' then
            crc_reg <= (others => '1');
        elsif rising_edge(clk) then
            if calc_en = '1' then
                d := data_in;
                c := crc_reg;
                
                new_c(0)  := c(24) xor c(30) xor d(1) xor d(7);
                new_c(1)  := c(25) xor c(31) xor d(0) xor d(6) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(2)  := c(26) xor d(5) xor c(25) xor c(31) xor d(0) xor d(6) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(3)  := c(27) xor d(4) xor c(26) xor d(5) xor c(25) xor c(31) xor d(0) xor d(6);
                new_c(4)  := c(28) xor d(3) xor c(27) xor d(4) xor c(26) xor d(5) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(5)  := c(29) xor d(2) xor c(28) xor d(3) xor c(27) xor d(4) xor c(25) xor c(31) xor d(0) xor d(6) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(6)  := c(30) xor d(1) xor c(29) xor d(2) xor c(28) xor d(3) xor c(26) xor d(5) xor c(25) xor c(31) xor d(0) xor d(6);
                new_c(7)  := c(31) xor d(0) xor c(29) xor d(2) xor c(27) xor d(4) xor c(26) xor d(5) xor c(24) xor d(7);
                new_c(8)  := c(0)  xor c(28) xor d(3) xor c(27) xor d(4) xor c(25) xor d(6) xor c(24) xor d(7);
                new_c(9)  := c(1)  xor c(29) xor d(2) xor c(28) xor d(3) xor c(26) xor d(5) xor c(25) xor d(6);
                new_c(10) := c(2)  xor c(29) xor d(2) xor c(27) xor d(4) xor c(26) xor d(5) xor c(24) xor d(7);
                new_c(11) := c(3)  xor c(28) xor d(3) xor c(27) xor d(4) xor c(25) xor d(6) xor c(24) xor d(7);
                new_c(12) := c(4)  xor c(29) xor d(2) xor c(28) xor d(3) xor c(26) xor d(5) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(13) := c(5)  xor c(30) xor d(1) xor c(29) xor d(2) xor c(27) xor d(4) xor c(25) xor c(31) xor d(0) xor d(6);
                new_c(14) := c(6)  xor c(31) xor d(0) xor c(30) xor d(1) xor c(28) xor d(3) xor c(26) xor d(5);
                new_c(15) := c(7)  xor c(31) xor d(0) xor c(29) xor d(2) xor c(27) xor d(4);
                new_c(16) := c(8)  xor c(28) xor d(3) xor c(24) xor d(7);
                new_c(17) := c(9)  xor c(29) xor d(2) xor c(25) xor d(6);
                new_c(18) := c(10) xor c(30) xor d(1) xor c(26) xor d(5);
                new_c(19) := c(11) xor c(31) xor d(0) xor c(27) xor d(4);
                new_c(20) := c(12) xor c(28) xor d(3);
                new_c(21) := c(21) xor c(29) xor d(2);
                new_c(22) := c(14) xor c(24) xor d(7);
                new_c(23) := c(15) xor c(25) xor d(6) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(24) := c(16) xor c(26) xor d(5) xor c(25) xor c(31) xor d(0) xor d(6);
                new_c(25) := c(17) xor c(27) xor d(4) xor c(26) xor d(5);
                new_c(26) := c(18) xor c(28) xor d(3) xor c(27) xor d(4) xor c(24) xor c(30) xor d(1) xor d(7);
                new_c(27) := c(19) xor c(29) xor d(2) xor c(28) xor d(3) xor c(25) xor c(31) xor d(0) xor d(6);
                new_c(28) := c(20) xor c(30) xor d(1) xor c(29) xor d(2) xor c(26) xor d(5);
                new_c(29) := c(21) xor c(31) xor d(0) xor c(30) xor d(1) xor c(27) xor d(4);
                new_c(30) := c(22) xor c(31) xor d(0) xor c(28) xor d(3);
                new_c(31) := c(23) xor c(29) xor d(2);

                crc_reg <= new_c;
            end if;
        end if;
    end process;

    crc_out <= not crc_reg;
end architecture Behavioral;