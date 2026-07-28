library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp_tx is
    Port (
        clk          : in  STD_LOGIC;                      -- Transmit Clock (125 MHz)
        rst_n        : in  STD_LOGIC;                      -- Active low reset
        tx_start     : in  STD_LOGIC;                      -- Trigger transmission
        tx_len       : in  STD_LOGIC_VECTOR(10 downto 0);   -- Payload byte count
        
        -- RAM Interface
        rd_data      : in  STD_LOGIC_VECTOR(7 downto 0);
        rd_addr      : out STD_LOGIC_VECTOR(10 downto 0);
        
        -- GMII TX Pins
        gmii_txen    : out STD_LOGIC;
        gmii_txd     : out STD_LOGIC_VECTOR(7 downto 0);
        tx_busy      : out STD_LOGIC
    );
end udp_tx;

architecture Behavioral of udp_tx is
    type state_type is (IDLE, PREAMBLE, ETH_HEADER, IP_HEADER, UDP_HEADER, PAYLOAD, CRC_STATE, IFG);
    signal state : state_type := IDLE;

    signal byte_cnt    : integer range 0 to 2047 := 0;
    signal payload_cnt : unsigned(10 downto 0) := (others => '0');
    signal crc_reg     : STD_LOGIC_VECTOR(31 downto 0) := x"FFFFFFFF";
    
    -- Network Parameters
    constant DST_MAC   : STD_LOGIC_VECTOR(47 downto 0) := x"FFFFFFFFFFFF"; -- Broadcast MAC
    constant SRC_MAC   : STD_LOGIC_VECTOR(47 downto 0) := x"000A3501FEC0"; -- Board MAC[cite: 1]
    constant SRC_IP    : STD_LOGIC_VECTOR(31 downto 0) := x"C0A80002";     -- 192.168.0.2[cite: 1]
    constant DST_IP    : STD_LOGIC_VECTOR(31 downto 0) := x"C0A80001";     -- Target PC IP[cite: 1]
    constant PORT_NUM  : STD_LOGIC_VECTOR(15 downto 0) := x"1F90";         -- Port 8080

    -- Combinational CRC32 Calculation
    function next_crc32(data : std_logic_vector(7 downto 0); crc : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable d       : std_logic_vector(7 downto 0);
        variable c       : std_logic_vector(31 downto 0);
        variable new_crc : std_logic_vector(31 downto 0);
    begin
        d := data;
        c := crc;
        new_crc(0)  := d(7) xor d(1) xor c(24) xor c(30);
        new_crc(1)  := d(6) xor d(0) xor c(25) xor c(31);
        new_crc(2)  := d(7) xor d(5) xor d(1) xor c(24) xor c(26) xor c(30);
        new_crc(3)  := d(6) xor d(4) xor d(0) xor c(25) xor c(27) xor c(31);
        new_crc(4)  := d(7) xor d(5) xor d(3) xor d(1) xor c(24) xor c(26) xor c(28) xor c(30);
        new_crc(5)  := d(6) xor d(4) xor d(2) xor d(0) xor c(25) xor c(27) xor c(29) xor c(31);
        new_crc(6)  := d(5) xor d(3) xor d(1) xor c(26) xor c(28) xor c(30);
        new_crc(7)  := d(4) xor d(2) xor d(0) xor c(27) xor c(29) xor c(31);
        new_crc(8)  := d(7) xor d(3) xor d(1) xor c(0) xor c(24) xor c(28) xor c(30);
        new_crc(9)  := d(6) xor d(2) xor d(0) xor c(1) xor c(25) xor c(29) xor c(31);
        new_crc(10) := d(7) xor d(5) xor d(1) xor c(2) xor c(24) xor c(26) xor c(30);
        new_crc(11) := d(6) xor d(4) xor d(0) xor c(3) xor c(25) xor c(27) xor c(31);
        new_crc(12) := d(7) xor d(5) xor d(3) xor d(1) xor c(4) xor c(24) xor c(26) xor c(28) xor c(30);
        new_crc(13) := d(6) xor d(4) xor d(2) xor d(0) xor c(5) xor c(25) xor c(27) xor c(29) xor c(31);
        new_crc(14) := d(5) xor d(3) xor d(1) xor c(6) xor c(26) xor c(28) xor c(30);
        new_crc(15) := d(4) xor d(2) xor d(0) xor c(7) xor c(27) xor c(29) xor c(31);
        new_crc(16) := d(7) xor d(3) xor d(1) xor c(8) xor c(24) xor c(28) xor c(30);
        new_crc(17) := d(6) xor d(2) xor d(0) xor c(9) xor c(25) xor c(29) xor c(31);
        new_crc(18) := d(5) xor d(1) xor c(10) xor c(26) xor c(30);
        new_crc(19) := d(4) xor d(0) xor c(11) xor c(27) xor c(31);
        new_crc(20) := d(3) xor c(12) xor c(28);
        new_crc(21) := d(2) xor c(13) xor c(29);
        new_crc(22) := d(7) xor c(14) xor c(24);
        new_crc(23) := d(7) xor d(6) xor d(1) xor c(15) xor c(24) xor c(25) xor c(30);
        new_crc(24) := d(6) xor d(5) xor d(0) xor c(16) xor c(25) xor c(26) xor c(31);
        new_crc(25) := d(5) xor d(4) xor c(17) xor c(26) xor c(27);
        new_crc(26) := d(7) xor d(4) xor d(3) xor d(1) xor c(18) xor c(24) xor c(27) xor c(28) xor c(30);
        new_crc(27) := d(6) xor d(3) xor d(2) xor d(0) xor c(19) xor c(25) xor c(28) xor c(29) xor c(31);
        new_crc(28) := d(5) xor d(2) xor d(1) xor c(20) xor c(26) xor c(29) xor c(30);
        new_crc(29) := d(4) xor d(1) xor d(0) xor c(21) xor c(27) xor c(30) xor c(31);
        new_crc(30) := d(3) xor d(0) xor c(22) xor c(28) xor c(31);
        new_crc(31) := d(2) xor c(23) xor c(29);
        return new_crc;
    end function;

begin

    process(clk, rst_n)
        variable current_byte : std_logic_vector(7 downto 0);
    begin
        if rst_n = '0' then
            state     <= IDLE;
            gmii_txen <= '0';
            gmii_txd  <= (others => '0');
            tx_busy   <= '0';
            rd_addr   <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    gmii_txen <= '0';
                    tx_busy   <= '0';
                    if tx_start = '1' then
                        state    <= PREAMBLE;
                        tx_busy  <= '1';
                        byte_cnt <= 0;
                        crc_reg  <= x"FFFFFFFF";
                    end if;

                when PREAMBLE =>
                    gmii_txen <= '1';
                    byte_cnt  <= byte_cnt + 1;
                    if byte_cnt < 7 then
                        gmii_txd <= x"55";
                    else
                        gmii_txd <= x"D5";
                        state    <= ETH_HEADER;
                        byte_cnt <= 0;
                    end if;

                when ETH_HEADER =>
                    gmii_txen <= '1';
                    byte_cnt  <= byte_cnt + 1;
                    case byte_cnt is
                        when 0 to 5   => current_byte := DST_MAC(47 - byte_cnt*8 downto 40 - byte_cnt*8);
                        when 6 to 11  => current_byte := SRC_MAC(47 - (byte_cnt-6)*8 downto 40 - (byte_cnt-6)*8);
                        when 12       => current_byte := x"08";
                        when 13       => current_byte := x"00";
                        when others   => current_byte := x"00";
                    end case;
                    gmii_txd <= current_byte;
                    crc_reg  <= next_crc32(current_byte, crc_reg);
                    if byte_cnt = 13 then
                        state    <= IP_HEADER;
                        byte_cnt <= 0;
                    end if;

                when IP_HEADER =>
                    gmii_txen <= '1';
                    byte_cnt  <= byte_cnt + 1;
                    case byte_cnt is
                        when 0  => current_byte := x"45";
                        when 1  => current_byte := x"00";
                        when 2  => current_byte := x"00";
                        when 3  => current_byte := std_logic_vector(unsigned(tx_len) + 28);
                        when 4  => current_byte := x"00";
                        when 5  => current_byte := x"01";
                        when 6  => current_byte := x"40";
                        when 7  => current_byte := x"00";
                        when 8  => current_byte := x"40";
                        when 9  => current_byte := x"11"; -- UDP
                        when 10 => current_byte := x"00"; -- Header Checksum Dummy
                        when 11 => current_byte := x"00";
                        when 12 to 15 => current_byte := SRC_IP(31 - (byte_cnt-12)*8 downto 24 - (byte_cnt-12)*8);
                        when 16 to 19 => current_byte := DST_IP(31 - (byte_cnt-16)*8 downto 24 - (byte_cnt-16)*8);
                        when others   => current_byte := x"00";
                    end case;
                    gmii_txd <= current_byte;
                    crc_reg  <= next_crc32(current_byte, crc_reg);
                    if byte_cnt = 19 then
                        state    <= UDP_HEADER;
                        byte_cnt <= 0;
                    end if;

                when UDP_HEADER =>
                    gmii_txen <= '1';
                    byte_cnt  <= byte_cnt + 1;
                    case byte_cnt is
                        when 0 to 1 => current_byte := PORT_NUM(15 - byte_cnt*8 downto 8 - byte_cnt*8);
                        when 2 to 3 => current_byte := PORT_NUM(15 - (byte_cnt-2)*8 downto 8 - (byte_cnt-2)*8);
                        when 4 to 5 => current_byte := std_logic_vector(unsigned(tx_len) + 8);
                        when 6 to 7 => current_byte := x"00"; -- Checksum Disabled
                        when others => current_byte := x"00";
                    end case;
                    gmii_txd <= current_byte;
                    crc_reg  <= next_crc32(current_byte, crc_reg);
                    if byte_cnt = 7 then
                        state       <= PAYLOAD;
                        payload_cnt <= (others => '0');
                        rd_addr     <= std_logic_vector(to_unsigned(0, 11));
                    end if;

                when PAYLOAD =>
                    gmii_txen <= '1';
                    current_byte := rd_data;
                    gmii_txd <= current_byte;
                    crc_reg  <= next_crc32(current_byte, crc_reg);
                    
                    if payload_cnt < unsigned(tx_len) then
                        payload_cnt <= payload_cnt + 1;
                        rd_addr     <= std_logic_vector(payload_cnt + 1);
                    else
                        state    <= CRC_STATE;
                        byte_cnt <= 0;
                    end if;

                when CRC_STATE =>
                    gmii_txen <= '1';
                    byte_cnt  <= byte_cnt + 1;
                    case byte_cnt is
                        when 0 => gmii_txd <= not (crc_reg(7 downto 0));
                        when 1 => gmii_txd <= not (crc_reg(15 downto 8));
                        when 2 => gmii_txd <= not (crc_reg(23 downto 16));
                        when 3 => gmii_txd <= not (crc_reg(31 downto 24));
                        when others => gmii_txd <= x"00";
                    end case;
                    
                    if byte_cnt = 3 then
                        state    <= IFG;
                        byte_cnt <= 0;
                    end if;

                when IFG =>
                    gmii_txen <= '0';
                    byte_cnt  <= byte_cnt + 1;
                    if byte_cnt = 12 then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;