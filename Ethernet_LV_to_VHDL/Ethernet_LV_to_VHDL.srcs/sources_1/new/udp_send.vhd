library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp_send is
    port (
        clk_125m    : in  std_logic;                    -- GMII GTXC Clock
        rst         : in  std_logic;
        send_en     : in  std_logic;                    -- Start Sending Packet Trigger
        data_len    : in  std_logic_vector(15 downto 0);-- Payload Length in Bytes
        ram_data    : in  std_logic_vector(7 downto 0); -- Read from Dual-Port RAM
        ram_addr    : out std_logic_vector(10 downto 0);
        e_txen      : out std_logic;                    -- GMII TX Enable
        e_txd       : out std_logic_vector(7 downto 0); -- GMII TX Data
        tx_busy     : out std_logic
    );
end entity udp_send;

architecture Behavioral of udp_send is

    component crc32 is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            calc_en  : in  std_logic;
            crc_out  : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Addressing and Constants
    constant DEST_MAC : std_logic_vector(47 downto 0) := x"FFFFFFFFFFFF"; -- Broadcast
    constant SRC_MAC  : std_logic_vector(47 downto 0) := x"000A3501FEC0"; -- Board MAC[cite: 1]
    constant SRC_IP   : std_logic_vector(31 downto 0) := x"C0A80002";     -- 192.168.0.2[cite: 1]
    constant DEST_IP  : std_logic_vector(31 downto 0) := x"C0A80003";     -- 192.168.0.3[cite: 1]
    constant SRC_PORT : std_logic_vector(15 downto 0) := x"1F90";         -- Port 8080
    constant DST_PORT : std_logic_vector(15 downto 0) := x"1F90";         -- Port 8080

    type state_type is (IDLE, PREAMBLE, ETH_HDR, IP_HDR, UDP_HDR, PAYLOAD, CRC_STATE);
    signal state     : state_type := IDLE;
    signal byte_cnt  : integer range 0 to 2047 := 0;
    
    signal crc_rst   : std_logic := '1';
    signal crc_en    : std_logic := '0';
    signal crc_out   : std_logic_vector(31 downto 0);
    signal tx_data   : std_logic_vector(7 downto 0) := x"00";

begin

    crc_inst : crc32
        port map (
            clk     => clk_125m,
            rst     => crc_rst,
            data_in => tx_data,
            calc_en => crc_en,
            crc_out => crc_out
        );

    e_txd <= tx_data;

    process(clk_125m, rst)
        variable ip_tot_len : unsigned(15 downto 0);
        variable udp_len    : unsigned(15 downto 0);
    begin
        if rst = '1' then
            state    <= IDLE;
            e_txen   <= '0';
            tx_busy  <= '0';
            crc_en   <= '0';
            crc_rst  <= '1';
            byte_cnt <= 0;
        elsif rising_edge(clk_125m) then
            case state is
                when IDLE =>
                    e_txen  <= '0';
                    tx_busy <= '0';
                    crc_en  <= '0';
                    crc_rst <= '1';
                    if send_en = '1' then
                        state   <= PREAMBLE;
                        tx_busy <= '1';
                        byte_cnt<= 0;
                    end if;

                when PREAMBLE =>
                    e_txen  <= '1';
                    crc_rst <= '0';
                    if byte_cnt < 7 then
                        tx_data <= x"55";
                    else
                        tx_data <= x"D5";
                        state   <= ETH_HDR;
                        byte_cnt<= 0;
                    end if;
                    if byte_cnt < 7 then
                        byte_cnt <= byte_cnt + 1;
                    end if;

                when ETH_HDR =>
                    crc_en <= '1';
                    byte_cnt <= byte_cnt + 1;
                    case byte_cnt is
                        when 0 to 5   => tx_data <= DEST_MAC(47 - byte_cnt*8 downto 40 - byte_cnt*8);
                        when 6 to 11  => tx_data <= SRC_MAC(47 - (byte_cnt-6)*8 downto 40 - (byte_cnt-6)*8);
                        when 12       => tx_data <= x"08"; -- IPv4 Type
                        when 13       => tx_data <= x"00";
                                         state   <= IP_HDR;
                                         byte_cnt<= 0;
                        when others   => null;
                    end case;

                when IP_HDR =>
                    byte_cnt <= byte_cnt + 1;
                    ip_tot_len := unsigned(data_len) + 28;
                    case byte_cnt is
                        when 0  => tx_data <= x"45"; -- IPv4, Length 20 Bytes
                        when 1  => tx_data <= x"00";
                        when 2  => tx_data <= std_logic_vector(ip_tot_len(15 downto 8));
                        when 3  => tx_data <= std_logic_vector(ip_tot_len(7 downto 0));
                        when 4  => tx_data <= x"00"; -- Packet ID
                        when 5  => tx_data <= x"00";
                        when 6  => tx_data <= x"40"; -- Flags / Fragment
                        when 7  => tx_data <= x"00";
                        when 8  => tx_data <= x"40"; -- TTL = 64
                        when 9  => tx_data <= x"11"; -- Protocol = UDP (17)
                        when 10 => tx_data <= x"00"; -- Simple IP Checksum Bypass
                        when 11 => tx_data <= x"00";
                        when 12 to 15 => tx_data <= SRC_IP(31 - (byte_cnt-12)*8 downto 24 - (byte_cnt-12)*8);
                        when 16 to 19 => tx_data <= DEST_IP(31 - (byte_cnt-16)*8 downto 24 - (byte_cnt-16)*8);
                                         if byte_cnt = 19 then
                                             state    <= UDP_HDR;
                                             byte_cnt <= 0;
                                         end if;
                        when others => null;
                    end case;

                when UDP_HDR =>
                    byte_cnt <= byte_cnt + 1;
                    udp_len := unsigned(data_len) + 8;
                    case byte_cnt is
                        when 0 to 1 => tx_data <= SRC_PORT(15 - byte_cnt*8 downto 8 - byte_cnt*8);
                        when 2 to 3 => tx_data <= DST_PORT(15 - (byte_cnt-2)*8 downto 8 - (byte_cnt-2)*8);
                        when 4      => tx_data <= std_logic_vector(udp_len(15 downto 8));
                        when 5      => tx_data <= std_logic_vector(udp_len(7 downto 0));
                        when 6 to 7 => tx_data <= x"00"; -- Checksum Disabled (0x0000)
                                       if byte_cnt = 7 then
                                           state    <= PAYLOAD;
                                           byte_cnt <= 0;
                                           ram_addr <= (others => '0');
                                       end if;
                        when others => null;
                    end case;

                when PAYLOAD =>
                    tx_data  <= ram_data;
                    ram_addr <= std_logic_vector(to_unsigned(byte_cnt + 1, 11));
                    if byte_cnt = to_integer(unsigned(data_len)) - 1 then
                        state    <= CRC_STATE;
                        crc_en   <= '0';
                        byte_cnt <= 0;
                    else
                        byte_cnt <= byte_cnt + 1;
                    end if;

                when CRC_STATE =>
                    byte_cnt <= byte_cnt + 1;
                    case byte_cnt is
                        when 0 => tx_data <= crc_out(7 downto 0);
                        when 1 => tx_data <= crc_out(15 downto 8);
                        when 2 => tx_data <= crc_out(23 downto 16);
                        when 3 => tx_data <= crc_out(31 downto 24);
                                  state   <= IDLE;
                                  e_txen  <= '0';
                        when others => null;
                    end case;

            end case;
        end if;
    end process;

end architecture Behavioral;