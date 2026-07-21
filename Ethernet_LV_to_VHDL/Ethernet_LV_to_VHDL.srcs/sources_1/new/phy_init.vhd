library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity phy_init is
    port (
        clk_50m     : in  std_logic;                    -- System Clock (50 MHz)
        rst_n       : in  std_logic;                    -- System Reset Active Low
        e_reset     : out std_logic;                    -- Active Low PHY Reset
        rxd7_out    : out std_logic;                    -- Pin drive override during boot
        rxer_out    : out std_logic;
        io_dir_trig : out std_logic                     -- '1' = drive output high, '0' = input mode
    );
end entity phy_init;

architecture Behavioral of phy_init is
    -- 50 MHz clock ticks: 10ms = 500,000 cycles; 30ms = 1,500,000 cycles
    constant C_RESET_10MS : unsigned(23 downto 0) := x"07A120"; 
    constant C_WAIT_30MS  : unsigned(23 downto 0) := x"16E360";

    type state_type is (ST_RESET_DRIVE, ST_WAIT_SETTLE, ST_DONE);
    signal state : state_type := ST_RESET_DRIVE;
    signal timer : unsigned(23 downto 0) := (others => '0');
begin
    process(clk_50m, rst_n)
    begin
        if rst_n = '0' then
            state       <= ST_RESET_DRIVE;
            timer       <= (others => '0');
            e_reset     <= '0';
            rxd7_out    <= '1';
            rxer_out    <= '1';
            io_dir_trig <= '1';
        elsif rising_edge(clk_50m) then
            case state is
                when ST_RESET_DRIVE =>
                    e_reset     <= '0';                 -- Assert Hardware Reset low
                    rxd7_out    <= '1';                 -- Pull HIGH during reset
                    rxer_out    <= '1';
                    io_dir_trig <= '1';
                    if timer >= C_RESET_10MS then
                        timer <= (others => '0');
                        state <= ST_WAIT_SETTLE;
                    else
                        timer <= timer + 1;
                    end if;

                when ST_WAIT_SETTLE =>
                    e_reset     <= '1';                 -- De-assert Hardware Reset
                    rxd7_out    <= '1';
                    rxer_out    <= '1';
                    io_dir_trig <= '1';
                    if timer >= C_WAIT_30MS then
                        state <= ST_DONE;
                    else
                        timer <= timer + 1;
                    end if;

                when ST_DONE =>
                    e_reset     <= '1';
                    rxd7_out    <= 'Z';                 -- Release to tri-state/input mode
                    rxer_out    <= 'Z';
                    io_dir_trig <= '0';                 -- Switch I/O tristate buffer control

            end case;
        end if;
    end process;
end architecture Behavioral;