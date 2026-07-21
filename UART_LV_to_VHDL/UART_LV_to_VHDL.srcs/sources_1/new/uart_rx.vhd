library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    rxd      : in  std_logic;
    rx_data  : out std_logic_vector(7 downto 0);
    rx_valid : out std_logic
);
end entity uart_rx;

architecture rtl of uart_rx is

    -- 50 MHz / 9600 baud = 5208 cycles per bit
    constant CLKS_PER_BIT : integer := 5208;

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;

    -- Synchronizer registers for rxd to prevent metastability
    signal rxd_sync_1 : std_logic := '1';
    signal rxd_sync_2 : std_logic := '1';

    signal clk_cnt   : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_idx   : integer range 0 to 7 := 0;
    signal rx_shift  : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Synchronize incoming RXD line to local 50MHz clk
    proc_sync : process(clk, rst_n)
    begin
        if rst_n = '0' then
            rxd_sync_1 <= '1';
            rxd_sync_2 <= '1';
        elsif rising_edge(clk) then
            rxd_sync_1 <= rxd;
            rxd_sync_2 <= rxd_sync_1;
        end if;
    end process proc_sync;

    -- UART RX State Machine
    proc_rx : process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= IDLE;
            clk_cnt  <= 0;
            bit_idx  <= 0;
            rx_shift <= (others => '0');
            rx_data  <= (others => '0');
            rx_valid <= '0';
        elsif rising_edge(clk) then
            rx_valid <= '0'; -- Default single-pulse signal

            case state is
                when IDLE =>
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    -- Detect falling edge (start bit start)
                    if rxd_sync_2 = '0' then
                        state <= START_BIT;
                    end if;

                when START_BIT =>
                    -- Sample in the middle of start bit to verify stability
                    if clk_cnt = (CLKS_PER_BIT / 2) - 1 then
                        if rxd_sync_2 = '0' then
                            clk_cnt <= 0;
                            state   <= DATA_BITS;
                        else
                            state   <= IDLE; -- False start bit
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA_BITS =>
                    if clk_cnt = CLKS_PER_BIT - 1 then
                        clk_cnt <= 0;
                        rx_shift(bit_idx) <= rxd_sync_2;
                        if bit_idx = 7 then
                            bit_idx <= 0;
                            state   <= STOP_BIT;
                        else
                            bit_idx <= bit_idx + 1;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when STOP_BIT =>
                    if clk_cnt = CLKS_PER_BIT - 1 then
                        rx_data  <= rx_shift;
                        rx_valid <= '1'; -- Signal 1-cycle valid flag
                        clk_cnt  <= 0;
                        state    <= IDLE;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process proc_rx;

end architecture rtl;