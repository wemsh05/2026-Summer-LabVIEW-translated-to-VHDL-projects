------------------------------------------------------------------------------------
---- Company: 
---- Engineer: 
---- 
---- Create Date: 2026/07/17 12:05:44
---- Design Name: 
---- Module Name: uart_top - Behavioral
---- Project Name: 
---- Target Devices: 
---- Tool Versions: 
---- Description: 
---- 
---- Dependencies: 
---- 
---- Revision:
---- Revision 0.01 - File Created
---- Additional Comments:
---- 
------------------------------------------------------------------------------------


--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--entity uart_top is
--port(
--    -- 板上原始200M晶振输入引脚
--    sys_clk_p         : in  std_logic;
--    sys_clk_n         : in  std_logic;
--    rst_n             : in  std_logic;  -- 板载复位按键

--    -- 物理接口输出（方便示波器观察，保留原Ports）
--    read_d            : out std_logic_vector(7 downto 0);
--    read_valid        : out std_logic;

--    -- 物理串口引脚
--    uart_rxd          : in  std_logic;
--    uart_txd          : out std_logic
--);
--end entity uart_top;

--architecture arch of uart_top is

---- PLL输出时钟信号
--signal clk_50m      : std_logic;
--signal clk_32m      : std_logic;
--signal pll_locked   : std_logic;

---- 各时钟域同步复位
--signal rst_50m_n    : std_logic;
--signal rst_32m_n    : std_logic;

---- 全局复位信号
--signal global_rst   : std_logic;
--signal pll_reset    : std_logic; -- 用于PLL复位的静态中间信号

----=============================
---- VIO 控制中间信号（代替外部输入脚）
----=============================
--signal vio_running    : std_logic;
--signal vio_send_wr_en : std_logic;
--signal vio_send_data  : std_logic_vector(7 downto 0);

---- 内部读数据线（同时驱动输出端口和VIO监听）
--signal read_d_int     : std_logic_vector(7 downto 0);
--signal read_valid_int : std_logic;

----=============================
---- 1. FIFO_UART_Send 信号定义（32M写 /50M读）
----=============================
--signal fifo_tx_wr_en     : std_logic;
--signal fifo_tx_wr_data   : std_logic_vector(7 downto 0);
--signal fifo_tx_full      : std_logic;

--signal fifo_tx_rd_en     : std_logic;
--signal fifo_tx_rd_data   : std_logic_vector(7 downto 0);
--signal fifo_tx_empty     : std_logic;

---- adjustable input baudrate in the og vhdl file
--signal input_baud : std_logic_vector(3 downto 0);

----=============================
---- 2. FIFO_UART_Receive 信号定义（50M写 /32M读）
----=============================
--signal fifo_rx_wr_en     : std_logic;
--signal fifo_rx_wr_data   : std_logic_vector(7 downto 0);
--signal fifo_rx_full      : std_logic;

--signal fifo_rx_rd_en     : std_logic;
--signal fifo_rx_rd_data   : std_logic_vector(7 downto 0);
--signal fifo_rx_empty     : std_logic;



----=============================
---- UART模块内部信号
----=============================
--signal uart_rx_data      : std_logic_vector(7 downto 0);
--signal uart_rx_valid     : std_logic;

--signal uart_tx_data      : std_logic_vector(7 downto 0);
--signal uart_tx_valid     : std_logic;
--signal uart_tx_ready     : std_logic;

----====================================================================
---- COMPONENT DECLARATIONS
----====================================================================
--component clk_wiz_0
--port (
--    clk_in1_p : in std_logic;
--    clk_in1_n : in std_logic;
--    clk_50M   : out std_logic;
--    clk_32M   : out std_logic;
--    reset     : in std_logic;
--    locked    : out std_logic
--);
--end component;

--component fifo_async_8x1024
--port (
--    rst    : in std_logic;
--    wr_clk : in std_logic;
--    rd_clk : in std_logic;
--    din    : in std_logic_vector(7 downto 0);
--    wr_en  : in std_logic;
--    rd_en  : in std_logic;
--    dout   : out std_logic_vector(7 downto 0);
--    full   : out std_logic;
--    empty  : out std_logic
--);
--end component;

--component uart_rx
--port (
--    clk      : in std_logic;
--    rst_n    : in std_logic;
--    rxd      : in std_logic;
--    rx_data  : out std_logic_vector(7 downto 0);
--    rx_valid : out std_logic
--);
--end component;

--component uart_tx
--port (
--    clk      : in std_logic;
--    rst_n    : in std_logic;
--    tx_data  : in std_logic_vector(7 downto 0);
--    tx_valid : in std_logic;
--    tx_ready : out std_logic;
--    txd      : out std_logic
--);
--end component;

---- VIO Core Component
--component vio_0
--port (
--    clk        : in std_logic;
--    probe_in0  : in std_logic_vector(7 downto 0);
--    probe_in1  : in std_logic_vector(0 downto 0);
--    probe_out0 : out std_logic_vector(0 downto 0);
--    probe_out1 : out std_logic_vector(0 downto 0);
--    probe_out2 : out std_logic_vector(7 downto 0)
--);
--end component;

--begin

---- 将内部信号连接到顶层输出端口
--read_d     <= read_d_int;
--read_valid <= read_valid_int;

----全局复位赋值
--global_rst <= not (rst_n and pll_locked);
--pll_reset  <= not rst_n;

----####################################################################
---- IP：时钟PLL，200M -> 50M + 32M
----####################################################################
--i_pll : clk_wiz_0
--port map(
--    clk_in1_p => sys_clk_p,
--    clk_in1_n => sys_clk_n,
--    reset     => pll_reset,
--    clk_50M   => clk_50m,
--    clk_32M   => clk_32m,
--    locked    => pll_locked
--);

----####################################################################
---- 跨时钟域同步复位生成
----####################################################################
--proc_rst_sync_50m: process(clk_50m)
--    variable rst_buf : std_logic_vector(1 downto 0);
--begin
--    if rising_edge(clk_50m) then
--        rst_buf := rst_buf(0) & (pll_locked and rst_n);
--        rst_50m_n <= rst_buf(1);
--    end if;
--end process;

--proc_rst_sync_32m: process(clk_32m)
--    variable rst_buf : std_logic_vector(1 downto 0);
--begin
--    if rising_edge(clk_32m) then
--        rst_buf := rst_buf(0) & (pll_locked and rst_n);
--        rst_32m_n <= rst_buf(1);
--    end if;
--end process;

----####################################################################
---- IP：VIO 虚拟 I/O 实例化 (运行在 32MHz 时钟域)
----####################################################################
--i_vio : vio_0
--port map (
--    clk           => clk_32m,
    
--    -- 监听输入
--    probe_in0     => read_d_int,
--    probe_in1(0)  => read_valid_int,
    
--    -- 虚拟输出控制
--    probe_out0(0) => vio_running,
--    probe_out1(0) => vio_send_wr_en,
--    probe_out2    => vio_send_data
--);

----####################################################################
----【模块例化1】异步FIFO_UART_Send IP
----####################################################################
--i_fifo_uart_send : fifo_async_8x1024
--port map(
--    wr_clk     => clk_32m,
--    wr_en      => fifo_tx_wr_en,
--    din        => fifo_tx_wr_data,
--    full       => fifo_tx_full,

--    rd_clk     => clk_50m,
--    rd_en      => fifo_tx_rd_en,
--    dout       => fifo_tx_rd_data,
--    empty      => fifo_tx_empty,
--    rst        => global_rst
--);

----####################################################################
----【模块例化2】异步FIFO_UART_Receive IP
----####################################################################
--i_fifo_uart_recv : fifo_async_8x1024
--port map(
--    wr_clk     => clk_50m,
--    wr_en      => fifo_rx_wr_en,
--    din        => fifo_rx_wr_data,
--    full       => fifo_rx_full,

--    rd_clk     => clk_32m,
--    rd_en      => fifo_rx_rd_en,
--    dout       => fifo_rx_rd_data,
--    empty      => fifo_rx_empty,
--    rst        => global_rst
--);

----####################################################################
---- 第一部分：用户线程（32MHz域） - 由 VIO 驱动
----####################################################################
--proc_user_thread: process(clk_32m, rst_32m_n)
--begin
--    if rst_32m_n = '0' then
--        fifo_tx_wr_en   <= '0';
--        fifo_tx_wr_data <= (others=>'0');
--        fifo_rx_rd_en   <= '0';
--        read_d_int      <= (others=>'0');
--        read_valid_int  <= '0';
--    elsif rising_edge(clk_32m) then
--        fifo_tx_wr_en <= '0';
--        fifo_rx_rd_en <= '0';
--        read_valid_int <= '0';

--        if vio_running = '1' then
--            -- 写发送FIFO (使用 VIO 的输入控制与数据)
--            if vio_send_wr_en = '1' and fifo_tx_full = '0' then
--                fifo_tx_wr_en   <= '1';
--                fifo_tx_wr_data <= vio_send_data;
--            end if;

--            -- 读接收FIFO
--            if fifo_rx_empty = '0' and fifo_rx_rd_en = '0' then
--                fifo_rx_rd_en  <= '1';
--                read_valid_int <= '1';
--                read_d_int     <= fifo_rx_rd_data;
--            else
--                fifo_rx_rd_en  <= '0';
--            end if;
--        end if;
--    end if;
--end process proc_user_thread;

----####################################################################
---- 第二部分：串口通信线程（50MHz域）
----####################################################################
--proc_uart_thread: process(clk_50m, rst_50m_n)
--begin
--    if rst_50m_n = '0' then
--        fifo_tx_rd_en   <= '0';
--        uart_tx_valid   <= '0';
--        uart_tx_data    <= (others=>'0');
--        fifo_rx_wr_en   <= '0';
--        fifo_rx_wr_data <= (others=>'0');
--    elsif rising_edge(clk_50m) then
--        fifo_tx_rd_en <= '0';
--        uart_tx_valid <= '0';
--        fifo_rx_wr_en <= '0';

--        -- 从发送FIFO取数据发送UART
--        if fifo_tx_empty = '0' and uart_tx_ready = '1' then
--            fifo_tx_rd_en <= '1';
--            uart_tx_data  <= fifo_tx_rd_data;
--            uart_tx_valid <= '1';
--        end if;

--        -- UART收到数据写入接收FIFO
--        if uart_rx_valid = '1' and fifo_rx_full = '0' then
--            fifo_rx_wr_en   <= '1';
--            fifo_rx_wr_data <= uart_rx_data;
--        end if;
--    end if;
--end process proc_uart_thread;

----####################################################################
---- UART 收发模块
----####################################################################
----i_uart_rx: uart_rx
----port map(
----    clk        => clk_50m,
----    rst_n      => rst_50m_n,
----    rxd        => uart_rxd,
----    rx_data    => uart_rx_data,
----    rx_valid   => uart_rx_valid
----);

----i_uart_tx: uart_tx
----port map(
----    clk        => clk_50m,
----    rst_n      => rst_50m_n,
----    tx_data    => uart_tx_data,
----    tx_valid   => uart_tx_valid,
----    tx_ready   => uart_tx_ready,
----    txd        => uart_txd
----);

--i_UART: UART
--port map(
--     clk    =>  clk_50m,--50M INPUT
--     Reset  =>    rst_50m_n, --高电平复位（与LabVIEW一致），也可以做成低电平，由程序控制动态控制
--   rxd    =>   uart_rxd,--串行数据接收端（通过LabVIEW接入引脚：RX_232_P61）
--   txd   =>    uart_txd,--串行数据接收端（通过LabVIEW接出引脚：TX_232_P60）
--     output_valid  =>  rx_valid,--串行数据接收完成标记位
--     output_data  => rx_data, --接收到的数据
--     input_data  => tx_data, --接收到的数据      
--     input_valid  =>  tx_valid,  --发送使能，高电平有效
--     input_ready  => tx_ready,    --单个字节是否发送完毕
--     input_baud => input_baud

--);

--end arch;




library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_top is
port(
    -- 板上原始200M晶振输入引脚
    sys_clk_p         : in  std_logic;
    sys_clk_n         : in  std_logic;
    rst_n             : in  std_logic;  -- 板载复位按键

    -- -- 物理接口输出
    -- read_d            : out std_logic_vector(7 downto 0);
    -- read_valid        : out std_logic;

    -- 物理串口引脚
    uart_rxd          : in  std_logic;
    uart_txd          : out std_logic
);
end entity uart_top;

architecture arch of uart_top is

-- PLL输出时钟信号
signal clk_50m      : std_logic;
signal clk_32m      : std_logic;
signal pll_locked   : std_logic;

-- 各时钟域同步复位
signal rst_50m_n    : std_logic;
signal rst_32m_n    : std_logic;
signal uart_rst     : std_logic; -- 高电平复位 (用于UART IP)

-- 全局复位信号
signal global_rst   : std_logic;
signal pll_reset    : std_logic;

--=============================
-- VIO 控制中间信号
--=============================
signal vio_running    : std_logic;
signal vio_send_wr_en : std_logic;
signal vio_send_data  : std_logic_vector(7 downto 0);

-- 内部读数据线
signal read_d_int     : std_logic_vector(7 downto 0);
signal read_valid_int : std_logic;

--=============================
-- 1. FIFO_UART_Send 信号定义 (32M写 / 50M读)
--=============================
signal fifo_tx_wr_en     : std_logic;
signal fifo_tx_wr_data   : std_logic_vector(7 downto 0);
signal fifo_tx_full      : std_logic;

signal fifo_tx_rd_en     : std_logic;
signal fifo_tx_rd_data   : std_logic_vector(7 downto 0);
signal fifo_tx_empty     : std_logic;

--=============================
-- 2. FIFO_UART_Receive 信号定义 (50M写 / 32M读)
--=============================
signal fifo_rx_wr_en     : std_logic;
signal fifo_rx_wr_data   : std_logic_vector(7 downto 0);
signal fifo_rx_full      : std_logic;

signal fifo_rx_rd_en     : std_logic;
signal fifo_rx_rd_data   : std_logic_vector(7 downto 0);
signal fifo_rx_empty     : std_logic;

--=============================
-- UART 模块接口信号
--=============================
signal uart_input_data   : std_logic_vector(7 downto 0);
signal uart_input_valid  : std_logic;
signal uart_input_ready  : std_logic;

signal uart_output_data  : std_logic_vector(7 downto 0);
signal uart_output_valid : std_logic;

-- 上升沿检测寄存器 (针对 output_valid)
signal output_valid_d0   : std_logic := '0';
signal output_valid_d1   : std_logic := '0';
signal output_valid_pos  : std_logic;

-- 波特率选择: "0010" = 9600
signal input_baud        : std_logic_vector(3 downto 0) := "0010";

--=============================
-- FSM 状态与格式化输出定义 (32MHz 域)
--=============================
type state_type is (ST_IDLE, ST_SEND_HEADER, ST_SEND_DATA, ST_SEND_CR, ST_SEND_LF);
signal state        : state_type := ST_IDLE;
signal header_idx   : integer range 0 to 8 := 0;
signal rx_byte_reg  : std_logic_vector(7 downto 0) := (others => '0');

-- 定义常量字符串 "[RX->TX]: "
type header_array is array (0 to 8) of std_logic_vector(7 downto 0);
constant HEADER_STR : header_array := (
    x"5B", -- '['
    x"52", -- 'R'
    x"58", -- 'X'
    x"2D", -- '-'
    x"3E", -- '>'
    x"54", -- 'T'
    x"58", -- 'X'
    x"5D", -- ']'
    x"3A"  -- ':'
);

--=============================
-- COMPONENT DECLARATIONS
--=============================
component clk_wiz_0
port (
    clk_in1_p : in std_logic;
    clk_in1_n : in std_logic;
    clk_50M   : out std_logic;
    clk_32M   : out std_logic;
    reset     : in std_logic;
    locked    : out std_logic
);
end component;

component fifo_async_8x1024
port (
    rst    : in std_logic;
    wr_clk : in std_logic;
    rd_clk : in std_logic;
    din    : in std_logic_vector(7 downto 0);
    wr_en  : in std_logic;
    rd_en  : in std_logic;
    dout   : out std_logic_vector(7 downto 0);
    full   : out std_logic;
    empty  : out std_logic
);
end component;

component UART
port (
    clk          : in  std_logic;
    Reset        : in  std_logic;
    rxd          : in  std_logic;
    txd          : out std_logic;
    output_valid : out std_logic;
    output_data  : out std_logic_vector(7 downto 0);
    input_data   : in  std_logic_vector(7 downto 0);
    input_valid  : in  std_logic;
    input_ready  : out std_logic;
    input_baud   : in  std_logic_vector(3 downto 0)
);
end component;

component vio_0
port (
    clk        : in std_logic;
    probe_in0  : in std_logic_vector(7 downto 0);
    probe_in1  : in std_logic_vector(0 downto 0);
    probe_out0 : out std_logic_vector(0 downto 0);
    probe_out1 : out std_logic_vector(0 downto 0);
    probe_out2 : out std_logic_vector(7 downto 0)
);
end component;

begin

-- -- 顶层输出端口
-- read_d     <= read_d_int;
-- read_valid <= read_valid_int;

-- 复位信号转换
global_rst <= not (rst_n and pll_locked);
pll_reset  <= not rst_n;
uart_rst   <= not rst_50m_n; -- 高电平复位

--####################################################################
-- IP：时钟PLL (200M -> 50M + 32M)
--####################################################################
i_pll : clk_wiz_0
port map(
    clk_in1_p => sys_clk_p,
    clk_in1_n => sys_clk_n,
    reset     => pll_reset,
    clk_50M   => clk_50m,
    clk_32M   => clk_32m,
    locked    => pll_locked
);

--####################################################################
-- 跨时钟域同步复位生成
--####################################################################
proc_rst_sync_50m: process(clk_50m)
    variable rst_buf : std_logic_vector(1 downto 0);
begin
    if rising_edge(clk_50m) then
        rst_buf := rst_buf(0) & (pll_locked and rst_n);
        rst_50m_n <= rst_buf(1);
    end if;
end process;

proc_rst_sync_32m: process(clk_32m)
    variable rst_buf : std_logic_vector(1 downto 0);
begin
    if rising_edge(clk_32m) then
        rst_buf := rst_buf(0) & (pll_locked and rst_n);
        rst_32m_n <= rst_buf(1);
    end if;
end process;

--####################################################################
-- IP：VIO 虚拟 I/O 实例化 (32MHz 域)
--####################################################################
i_vio : vio_0
port map (
    clk           => clk_32m,
    probe_in0     => read_d_int,
    probe_in1(0)  => read_valid_int,
    probe_out0(0) => vio_running,
    probe_out1(0) => vio_send_wr_en,
    probe_out2    => vio_send_data
);

--####################################################################
-- IP：FIFO_UART_Send (32M 写 / 50M 读)
--####################################################################
i_fifo_uart_send : fifo_async_8x1024
port map(
    wr_clk => clk_32m,
    wr_en  => fifo_tx_wr_en,
    din    => fifo_tx_wr_data,
    full   => fifo_tx_full,

    rd_clk => clk_50m,
    rd_en  => fifo_tx_rd_en,
    dout   => fifo_tx_rd_data,
    empty  => fifo_tx_empty,
    rst    => global_rst
);

--####################################################################
-- IP：FIFO_UART_Receive (50M 写 / 32M 读)
--####################################################################
i_fifo_uart_recv : fifo_async_8x1024
port map(
    wr_clk => clk_50m,
    wr_en  => fifo_rx_wr_en,
    din    => fifo_rx_wr_data,
    full   => fifo_rx_full,

    rd_clk => clk_32m,
    rd_en  => fifo_rx_rd_en,
    dout   => fifo_rx_rd_data,
    empty  => fifo_rx_empty,
    rst    => global_rst
);

--####################################################################
-- 第一部分：用户线程 (32MHz 域) - FSM 带前缀格式化输出
--####################################################################
proc_user_thread: process(clk_32m, rst_32m_n)
begin
    if rst_32m_n = '0' then
        fifo_tx_wr_en   <= '0';
        fifo_tx_wr_data <= (others => '0');
        fifo_rx_rd_en   <= '0';
        read_d_int      <= (others => '0');
        read_valid_int  <= '0';
        rx_byte_reg     <= (others => '0');
        header_idx      <= 0;
        state           <= ST_IDLE;

    elsif rising_edge(clk_32m) then
        -- 默认清零单脉冲使能信号
        fifo_tx_wr_en  <= '0';
        fifo_rx_rd_en  <= '0';
        read_valid_int <= '0';

        case state is

            -- 1. 等待接收 FIFO 出现新数据
            when ST_IDLE =>
                header_idx <= 0;
                if fifo_rx_empty = '0' then
                    fifo_rx_rd_en   <= '1';              -- 从 RX FIFO 弹出 1 字节
                    rx_byte_reg     <= fifo_rx_rd_data;  -- 锁存接收到的字符
                    read_d_int      <= fifo_rx_rd_data;  -- 供物理端口/VIO 观察
                    read_valid_int  <= '1';
                    state           <= ST_SEND_HEADER;
                end if;

            -- 2. 依次写入前缀字符 "[RX->TX]:"
            when ST_SEND_HEADER =>
                if fifo_tx_full = '0' then
                    fifo_tx_wr_en   <= '1';
                    fifo_tx_wr_data <= HEADER_STR(header_idx);
                    
                    if header_idx = 8 then
                        state <= ST_SEND_DATA;
                    else
                        header_idx <= header_idx + 1;
                    end if;
                end if;

            -- 3. 写入接收到的原始字符
            when ST_SEND_DATA =>
                if fifo_tx_full = '0' then
                    fifo_tx_wr_en   <= '1';
                    fifo_tx_wr_data <= rx_byte_reg;
                    state           <= ST_SEND_CR;
                end if;

            -- 4. 写入换行符 '\r' (Carriage Return - 0x0D)
            when ST_SEND_CR =>
                if fifo_tx_full = '0' then
                    fifo_tx_wr_en   <= '1';
                    fifo_tx_wr_data <= x"0D";
                    state           <= ST_SEND_LF;
                end if;

            -- 5. 写入换行符 '\n' (Line Feed - 0x0A)
            when ST_SEND_LF =>
                if fifo_tx_full = '0' then
                    fifo_tx_wr_en   <= '1';
                    fifo_tx_wr_data <= x"0A";
                    state           <= ST_IDLE; -- 完成本次解包与回环，返回 IDLE
                end if;

            when others =>
                state <= ST_IDLE;

        end case;
    end if;
end process proc_user_thread;

--####################################################################
-- 第二部分：串口通信线程组合与时钟控制 (50MHz 域)
-- 对应框图中的握手控制逻辑 (FIFO_Read, AND gate, Rising-Edge)
--####################################################################

-- 1. 对应框图：output_valid 信号检测上升沿 (检测上升沿模块)
proc_edge_det: process(clk_50m, rst_50m_n)
begin
    if rst_50m_n = '0' then
        output_valid_d0 <= '0';
        output_valid_d1 <= '0';
    elsif rising_edge(clk_50m) then
        output_valid_d0 <= uart_output_valid;
        output_valid_d1 <= output_valid_d0;
    end if;
end process;

output_valid_pos <= output_valid_d0 and (not output_valid_d1);

-- 2. 串口控制逻辑
proc_uart_thread: process(clk_50m, rst_50m_n)
begin
    if rst_50m_n = '0' then
        fifo_tx_rd_en    <= '0';
        uart_input_valid <= '0';
        uart_input_data  <= (others=>'0');
        fifo_rx_wr_en    <= '0';
        fifo_rx_wr_data  <= (others=>'0');
    elsif rising_edge(clk_50m) then
        fifo_tx_rd_en    <= '0';
        uart_input_valid <= '0';
        fifo_rx_wr_en    <= '0';

        -- 发送控制：当 FIFO 不为空且 UART 处于 input_ready 状态时读取并驱动 input_valid (对应框图中的与门)
        if fifo_tx_empty = '0' and uart_input_ready = '1' then
            fifo_tx_rd_en    <= '1';
            uart_input_data  <= fifo_tx_rd_data;
            uart_input_valid <= '1';
        end if;

        -- 接收控制：检测到 output_valid 上升沿且接收 FIFO 未满时，将接收数据写入 FIFO
        if output_valid_pos = '1' and fifo_rx_full = '0' then
            fifo_rx_wr_en   <= '1';
            fifo_rx_wr_data <= uart_output_data;
        end if;
    end if;
end process proc_uart_thread;

--####################################################################
-- UART 收发 IP 实例化
--####################################################################
i_UART: UART
port map(
    clk          => clk_50m,
    Reset        => uart_rst,         -- 高电平复位
    rxd          => uart_rxd,
    txd          => uart_txd,
    output_valid => uart_output_valid,
    output_data  => uart_output_data,
    input_data   => uart_input_data,
    input_valid  => uart_input_valid,
    input_ready  => uart_input_ready,
    input_baud   => input_baud
);

end arch;