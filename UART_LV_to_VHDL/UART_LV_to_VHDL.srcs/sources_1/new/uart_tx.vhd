library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    tx_data  : in  std_logic_vector(7 downto 0);
    tx_valid : in  std_logic;
    tx_ready : out std_logic;
    txd      : out std_logic
);
end entity uart_tx;

architecture rtl of uart_tx is

    -- 50 MHz / 115200 baud = 434 cycles per bit
    constant CLKS_PER_BIT : integer := 5208;

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;

    signal clk_cnt  : integer range 0 to CLKS_PER_BIT - 1 := 0;
    signal bit_idx  : integer range 0 to 7 := 0;
    signal tx_shift : std_logic_vector(7 downto 0) := (others => '0');

begin

    proc_tx : process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= IDLE;
            clk_cnt  <= 0;
            bit_idx  <= 0;
            tx_shift <= (others => '0');
            txd      <= '1';
            tx_ready <= '1';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    txd      <= '1';
                    tx_ready <= '1';
                    clk_cnt  <= 0;
                    bit_idx  <= 0;

                    if tx_valid = '1' then
                        tx_shift <= tx_data;
                        tx_ready <= '0';
                        state    <= START_BIT;
                    end if;

                when START_BIT =>
                    txd <= '0'; -- Start bit (logic 0)
                    if clk_cnt = CLKS_PER_BIT - 1 then
                        clk_cnt <= 0;
                        state   <= DATA_BITS;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA_BITS =>
                    txd <= tx_shift(bit_idx); -- LSB first
                    if clk_cnt = CLKS_PER_BIT - 1 then
                        clk_cnt <= 0;
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
                    txd <= '1'; -- Stop bit (logic 1)
                    if clk_cnt = CLKS_PER_BIT - 1 then
                        clk_cnt  <= 0;
                        tx_ready <= '1';
                        state    <= IDLE;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process proc_tx;

end architecture rtl;