library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity udp_echo_top is
    Port (
        -- Board 200 MHz Differential System Clock & Reset
        sys_clk_p : in  STD_LOGIC;
        sys_clk_n : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        
        -- AN8211 Ethernet PHY GMII Signals
        E_RXC     : in  STD_LOGIC;
        E_RXDV    : in  STD_LOGIC;
        E_RXD     : in  STD_LOGIC_VECTOR(7 downto 0);
        E_GTXC    : out STD_LOGIC;                      -- Transmit Clock Forwarding
        E_TXEN    : out STD_LOGIC;
        E_TXD     : out STD_LOGIC_VECTOR(7 downto 0);
        E_RESET   : out STD_LOGIC
    );
end udp_echo_top;

architecture Structural of udp_echo_top is

    -- Internal Clock Nets
    signal clk_50m     : STD_LOGIC;
    signal clk_125m    : STD_LOGIC;
    signal e_rxc_bufg  : STD_LOGIC;                     -- Buffered RX Clock Net
    signal mmcm_locked : STD_LOGIC;
    signal mmcm_rst    : STD_LOGIC;

    -- Power-on Reset Logic
    signal phy_rst_cnt : unsigned(19 downto 0) := (others => '0');
    signal phy_rst_n   : STD_LOGIC := '0';

    -- Dual-Port Payload RAM
    type ram_type is array (0 to 2047) of std_logic_vector(7 downto 0);
    signal payload_ram : ram_type;
    
    -- RX / TX Inter-module Connections
    signal rx_data    : STD_LOGIC_VECTOR(7 downto 0);
    signal rx_addr    : STD_LOGIC_VECTOR(10 downto 0);
    signal rx_len     : STD_LOGIC_VECTOR(10 downto 0);
    signal rx_valid   : STD_LOGIC;

    signal rd_addr    : STD_LOGIC_VECTOR(10 downto 0);
    signal rd_data    : STD_LOGIC_VECTOR(7 downto 0);
    signal tx_busy    : STD_LOGIC;

    -- Clocking Wizard Component Declaration
    component clk_wiz_0
        port (
            clk_in1_p : in  std_logic;
            clk_in1_n : in  std_logic;
            clk_out1  : out std_logic; -- 50 MHz Output
            clk_out2  : out std_logic; -- 125 MHz Output
            reset     : in  std_logic;
            locked    : out std_logic
        );
    end component;

begin

    mmcm_rst <= not rst_n;

    --------------------------------------------------------------------
    -- 1. Clocking Infrastructure
    --------------------------------------------------------------------
    -- MMCM for internal system logic
    u_clk_wiz : clk_wiz_0
        port map (
            clk_in1_p => sys_clk_p,
            clk_in1_n => sys_clk_n,
            clk_out1  => clk_50m,
            clk_out2  => clk_125m,
            reset     => mmcm_rst,
            locked    => mmcm_locked
        );

    -- Dedicated BUFG for incoming Ethernet Receive Clock (E_RXC)
    u_bufg_rxc : BUFG
        port map (
            I => E_RXC,
            O => e_rxc_bufg
        );

    --------------------------------------------------------------------
    -- 2. ODDR Clock Forwarding for GMII E_GTXC
    --------------------------------------------------------------------
    ODDR_gtxc : ODDR
        generic map(
            DDR_CLK_EDGE => "SAME_EDGE",
            INIT         => '0',
            SRTYPE       => "SYNC"
        )
        port map (
            Q  => E_GTXC,
            C  => clk_125m,
            CE => '1',
            D1 => '1',
            D2 => '0',
            R  => '0',
            S  => '0'
        );

    --------------------------------------------------------------------
    -- 3. Hardware PHY Power-On Reset Engine
    --------------------------------------------------------------------
    process(clk_50m, rst_n)
    begin
        if rst_n = '0' then
            phy_rst_cnt <= (others => '0');
            phy_rst_n   <= '0';
        elsif rising_edge(clk_50m) then
            if mmcm_locked = '1' then
                if phy_rst_cnt < x"FFFFF" then
                    phy_rst_cnt <= phy_rst_cnt + 1;
                    phy_rst_n   <= '0';
                else
                    phy_rst_n   <= '1';
                end if;
            else
                phy_rst_cnt <= (others => '0');
                phy_rst_n   <= '0';
            end if;
        end if;
    end process;

    E_RESET <= phy_rst_n;

    --------------------------------------------------------------------
    -- 4. Dual-Port Payload RAM Buffer
    --------------------------------------------------------------------
    process(e_rxc_bufg)
    begin
        if rising_edge(e_rxc_bufg) then
            if rx_valid = '1' or unsigned(rx_addr) > 0 then
                payload_ram(to_integer(unsigned(rx_addr))) <= rx_data;
            end if;
        end if;
    end process;

    process(clk_125m)
    begin
        if rising_edge(clk_125m) then
            rd_data <= payload_ram(to_integer(unsigned(rd_addr)));
        end if;
    end process;

    --------------------------------------------------------------------
    -- 5. Subsystem Instantiations
    --------------------------------------------------------------------
    u_rx : entity work.udp_rx
        port map (
            clk       => e_rxc_bufg,
            rst_n     => phy_rst_n,
            gmii_rxdv => E_RXDV,
            gmii_rxd  => E_RXD,
            rx_data   => rx_data,
            rx_addr   => rx_addr,
            rx_len    => rx_len,
            rx_valid  => rx_valid
        );

    u_tx : entity work.udp_tx
        port map (
            clk       => clk_125m,
            rst_n     => phy_rst_n,
            tx_start  => rx_valid,
            tx_len    => rx_len,
            rd_data   => rd_data,
            rd_addr   => rd_addr,
            gmii_txen => E_TXEN,
            gmii_txd  => E_TXD,
            tx_busy   => tx_busy
        );

end Structural;