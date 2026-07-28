library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity udp_rx is
    Port (
        clk          : in  STD_LOGIC;                      -- E_RXC GMII Clock (125 MHz)
        rst_n        : in  STD_LOGIC;                      -- Active low reset
        gmii_rxdv    : in  STD_LOGIC;                      -- E_RXDV
        gmii_rxd     : in  STD_LOGIC_VECTOR(7 downto 0);   -- E_RXD
        
        -- Payload RAM Buffer Interface
        rx_data      : out STD_LOGIC_VECTOR(7 downto 0);
        rx_addr      : out STD_LOGIC_VECTOR(10 downto 0);
        rx_len       : out STD_LOGIC_VECTOR(10 downto 0);
        rx_valid     : out STD_LOGIC
    );
end udp_rx;

architecture Behavioral of udp_rx is
    type state_type is (IDLE, CHECK_PREAMBLE, ETH_HEADER, IP_HEADER, UDP_HEADER, PAYLOAD, WAIT_END);
    signal state : state_type := IDLE;

    signal byte_cnt   : integer range 0 to 2047 := 0;
    signal udp_len    : unsigned(15 downto 0) := (others => '0');
    signal payload_cnt: unsigned(10 downto 0) := (others => '0');
    
    constant FPGA_IP  : STD_LOGIC_VECTOR(31 downto 0) := x"C0A80002"; -- 192.168.0.2
    constant UDP_PORT : STD_LOGIC_VECTOR(15 downto 0) := x"1F90";     -- Port 8080
    
    signal dest_ip    : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal dest_port  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal ip_proto   : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state       <= IDLE;
            byte_cnt    <= 0;
            rx_valid    <= '0';
            rx_data     <= (others => '0');
            rx_addr     <= (others => '0');
            rx_len      <= (others => '0');
        elsif rising_edge(clk) then
            rx_valid <= '0';
            
            case state is
                when IDLE =>
                    byte_cnt <= 0;
                    if gmii_rxdv = '1' and gmii_rxd = x"55" then
                        state <= CHECK_PREAMBLE;
                    end if;

                when CHECK_PREAMBLE =>
                    if gmii_rxdv = '1' then
                        if gmii_rxd = x"D5" then
                            state    <= ETH_HEADER;
                            byte_cnt <= 0;
                        elsif gmii_rxd /= x"55" then
                            state <= IDLE;
                        end if;
                    else
                        state <= IDLE;
                    end if;

                when ETH_HEADER =>
                    if gmii_rxdv = '1' then
                        byte_cnt <= byte_cnt + 1;
                        if byte_cnt = 13 then
                            state    <= IP_HEADER;
                            byte_cnt <= 0;
                        end if;
                    else
                        state <= IDLE;
                    end if;

                when IP_HEADER =>
                    if gmii_rxdv = '1' then
                        byte_cnt <= byte_cnt + 1;
                        if byte_cnt = 9 then
                            ip_proto <= gmii_rxd;
                        elsif byte_cnt >= 16 and byte_cnt <= 19 then
                            dest_ip <= dest_ip(23 downto 0) & gmii_rxd;
                        end if;

                        if byte_cnt = 19 then
                            if ip_proto = x"11" then -- UDP Protocol
                                state    <= UDP_HEADER;
                                byte_cnt <= 0;
                            else
                                state <= IDLE;
                            end if;
                        end if;
                    else
                        state <= IDLE;
                    end if;

                when UDP_HEADER =>
                    if gmii_rxdv = '1' then
                        byte_cnt <= byte_cnt + 1;
                        if byte_cnt >= 2 and byte_cnt <= 3 then
                            dest_port <= dest_port(7 downto 0) & gmii_rxd;
                        elsif byte_cnt >= 4 and byte_cnt <= 5 then
                            udp_len <= udp_len(7 downto 0) & unsigned(gmii_rxd);
                        end if;

                        if byte_cnt = 7 then
                            if dest_ip = FPGA_IP and dest_port = UDP_PORT then
                                state       <= PAYLOAD;
                                payload_cnt <= (others => '0');
                            else
                                state <= IDLE;
                            end if;
                        end if;
                    else
                        state <= IDLE;
                    end if;

                when PAYLOAD =>
                    if gmii_rxdv = '1' then
                        rx_data  <= gmii_rxd;
                        rx_addr  <= std_logic_vector(payload_cnt);
                        
                        if payload_cnt < (udp_len - 8) then
                            payload_cnt <= payload_cnt + 1;
                        else
                            rx_len   <= std_logic_vector(payload_cnt);
                            rx_valid <= '1';
                            state    <= WAIT_END;
                        end if;
                    else
                        state <= IDLE;
                    end if;

                when WAIT_END =>
                    if gmii_rxdv = '0' then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;