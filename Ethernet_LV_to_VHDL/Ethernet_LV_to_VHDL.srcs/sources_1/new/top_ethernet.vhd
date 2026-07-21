library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity top_ethernet is
    port (
        -- System Differential Clock & Reset
        sys_clk_p    : in  std_logic;                    -- Board 200 MHz Clock (p)
        sys_clk_n    : in  std_logic;                    -- Board 200 MHz Clock (n)
        rst_n        : in  std_logic;

        -- 40-Pin Header GMII Physical Interface
        E_GTXC       : out std_logic;                    -- GMII Transmit Clock
        E_TXEN       : out std_logic;                    -- GMII Transmit Enable
        E_TXD        : out std_logic_vector(7 downto 0); -- GMII Transmit Data
        E_RXC        : in  std_logic;                    -- GMII Receive Clock
        E_RXDV       : in  std_logic;                    -- GMII Receive Data Valid
        E_RXD        : inout std_logic_vector(7 downto 0);-- Tristate data line for RXD7 workaround
        E_RXER       : inout std_logic;                  -- Tristate pin for RXER workaround
        E_RESET      : out std_logic                     -- PHY Reset Pin
    );
end entity top_ethernet;

architecture Structural of top_ethernet is

    -- Internal Clock Signal
    signal sys_clk     : std_logic;

    -- Hardware Signals
    signal io_dir_trig : std_logic;
    signal rxd7_out    : std_logic;
    signal rxer_out    : std_logic;
    
    signal send_trigger: std_logic := '0';
    signal ram_addr    : std_logic_vector(10 downto 0);
    signal ram_data    : std_logic_vector(7 downto 0);
    
    type rom_type is array (0 to 17) of std_logic_vector(7 downto 0);
    constant C_MSG : rom_type := (
        x"48", x"45", x"4C", x"4C", x"4F", x"20", x"41", x"4C", 
        x"49", x"4E", x"58", x"20", x"41", x"58", x"33", x"30", x"31", x"0A"
    );

begin

    --------------------------------------------------------------------
    -- Differential Clock Input Buffer
    --------------------------------------------------------------------
    IBUFGDS_inst : IBUFGDS
        port map (
            O  => sys_clk,
            I  => sys_clk_p,
            IB => sys_clk_n
        );

    --------------------------------------------------------------------
    -- ODDR Clock Forwarding for E_GTXC
    --------------------------------------------------------------------
    ODDR_gtxc : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE",
            INIT         => '0',
            SRTYPE       => "SYNC"
        )
        port map (
            Q  => E_GTXC,
            C  => sys_clk,
            CE => '1',
            D1 => '1',
            D2 => '0',
            R  => '0',
            S  => '0'
        );

    --------------------------------------------------------------------
    -- 1. AN8211 Hardware Initialization Control Block
    --------------------------------------------------------------------
    u_phy_init : entity work.phy_init
        port map (
            clk_50m     => sys_clk,
            rst_n       => rst_n,
            e_reset     => E_RESET,
            rxd7_out    => rxd7_out,
            rxer_out    => rxer_out,
            io_dir_trig => io_dir_trig
        );

    -- Bidirectional pin assignments for RXD7 and RXER startup sequence
    E_RXD(7) <= rxd7_out when io_dir_trig = '1' else 'Z';
    E_RXER   <= rxer_out when io_dir_trig = '1' else 'Z';

    --------------------------------------------------------------------
    -- 2. ROM Read Mechanism
    --------------------------------------------------------------------
    process(sys_clk)
        variable idx : integer;
    begin
        if rising_edge(sys_clk) then
            idx := to_integer(unsigned(ram_addr));
            if idx < 18 then
                ram_data <= C_MSG(idx);
            else
                ram_data <= x"20";
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 3. UDP Send Subsystem
    --------------------------------------------------------------------
    u_udp_send : entity work.udp_send
        port map (
            clk_125m => sys_clk,
            rst      => not rst_n,
            send_en  => '1',
            data_len => std_logic_vector(to_unsigned(18, 16)),
            ram_data => ram_data,
            ram_addr => ram_addr,
            e_txen   => E_TXEN,
            e_txd    => E_TXD,
            tx_busy  => open
        );

end architecture Structural;