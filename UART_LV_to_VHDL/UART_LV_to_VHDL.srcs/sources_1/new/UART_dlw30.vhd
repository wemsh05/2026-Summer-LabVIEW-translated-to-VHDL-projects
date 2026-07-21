
----------------------------------------------------------------------------------
--www.21eda.com
--深圳市21EDA电子

-- 本模块的功能是验证实趾蚉C?进行基本的串口通信的功能。需要??--PC机上安装一个串口调试工具来验证程序的功能。
-- 程序实现了一个收发一帧10个bit（即无奇偶校验位）的串口控
--制器，10个bit是1位起始位，8个数据位，1个结束
--位。串口的波特律由程序中定义的div_par参数决定，更改该参数可以实
--现相应的波特率。程序当前设定的div_par 的值是0x145，对应的波特率是
--9600。用一个8倍波特率的时钟将发送或接受每一位bit的周期时间
--划分为8个时隙以使通信同步.
--程序的工作过程是：串口处于全双工工作状态，按动key1，CPLD向PC发送"21EDA"
--按动RESET 就复位了。
--字符串（串口调试工具设成按ASCII码接受方式）；PC可随时向FPGA发送0-F的十六进制
--数据，FPGA接芎笙允驹?段数码管上。
--视频教程屎衔颐?1EDA电子的所有学习板
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART is
--像LabVIEW当中的FFT函数一样，采用"四线制"握手协议来改造RS232通信协议
 PORT (
      clk                     : IN std_logic;   --50M INPUT
      Reset                     : IN std_logic;   --高电平复位（与LabVIEW一致），也可以做成低电平，由程序控制动态控制
      rxd                     : IN std_logic;   --串行数据接收端（通过LabVIEW接入引脚：RX_232_P61）
	  txd                     : OUT std_logic;   --串行数据接收端（通过LabVIEW接出引脚：TX_232_P60）
	  output_valid 			  : OUT std_logic;   --串行数据接收完成标记位
	  output_data                : OUT std_logic_vector(7 DOWNTO 0); --接收到的数据
	  input_data				  : IN std_logic_vector(7 DOWNTO 0); --接收到的数据	  
	  input_valid             : IN std_logic;   --发送使能，高电平有效
	  input_ready				  : OUT std_logic;   --单个字节是否发送完毕
	  input_baud				: IN std_logic_vector(3 DOWNTO 0)--波特率输入（最多可以设置16个档位）
	  );   --发送使能，高电平有效		
end UART;

architecture Behavioral of UART is

   --//////////////////inner reg////////////////////
   SIGNAL div_reg                  :  std_logic_vector(15 DOWNTO 0);--分频计数器，分频值由波特率决定。分频后得到频率8倍波特率的时钟   
   SIGNAL div8_tras_reg            :  std_logic_vector(2 DOWNTO 0);--该寄存器的计数值对Ψ⑺褪钡鼻拔挥诘氖倍?  
   SIGNAL div8_rec_reg             :  std_logic_vector(2 DOWNTO 0);  --寄存器的计数值对应接收时当前位于的时隙数 
   SIGNAL state_tras               :  std_logic_vector(3 DOWNTO 0);  -- 发送状态寄存器
   SIGNAL state_rec                :  std_logic_vector(3 DOWNTO 0); -- 接受状态寄存器 
   SIGNAL clkbaud_tras             :  std_logic; --以波特率为频率的发送使能信号  
   SIGNAL clkbaud_rec              :  std_logic; --以波特率为频率的接受使能信号  
   SIGNAL clkbaud8x                :  std_logic; --以8倍波特率为频率的时钟，它的作用是将发送或接受一个bit的时钟芷诜治?个时隙  
   SIGNAL recstart                 :  std_logic; -- 开始发送标志 
   SIGNAL recstart_tmp             :  std_logic; --开始接受标志  
   SIGNAL trasstart                :  std_logic;   
   SIGNAL rxd_reg1                 :  std_logic; --接收寄存器1  
   SIGNAL rxd_reg2                 :  std_logic; --接收寄存器2，因为接收数据为异步信号，故用两级缓存  
   SIGNAL txd_reg                  :  std_logic; --发送寄存器  
   SIGNAL rxd_buf                  :  std_logic_vector(7 DOWNTO 0);--接受数据缓存   
   SIGNAL txd_buf                  :  std_logic_vector(7 DOWNTO 0);--发送数据缓存   
   SIGNAL send_state               :  std_logic_vector(2 DOWNTO 0);--每伟醇?给PC发送"Welcome"字?串，这是发送状态寄存??  
   SIGNAL cnt_delay                :  std_logic_vector(19 DOWNTO 0);--延时去抖计数器   
   SIGNAL start_delaycnt           :  std_logic;  --开始延时计数标志 
   --//////////////////////////////////////////////
 --  CONSTANT  div_par               :  std_logic_vector(15 DOWNTO 0) := "0000000101000101"; 
   SIGNAL  div_par               :  std_logic_vector(15 DOWNTO 0);
   
   
   --分频参数，其值由杂Φ牟ㄌ芈始扑愣?得，按此参数分频的时钟频率是波倍特率??倍，此处值对应9600的波特率，即制党龅氖敝悠率是9600*8	    
   SIGNAL txd_xhdl3                :  std_logic;  
   SIGNAL txd_flag                 :  std_logic;  --完成标记位 
   SIGNAL txd_flag_old                 :  std_logic;  --完成标记位 
   SIGNAL txd_flag_new                 :  std_logic;  --完成标记位
 
   SIGNAL input_valid_reg          :  std_logic;  --输入有效标记位
   SIGNAL input_data_reg           :  std_logic_vector(7 DOWNTO 0); --接收到的数据缓冲寄存器 
   SIGNAL output_valid_reg         :  std_logic;  --输出完成标记位 
   SIGNAL output_valid_reg_old     :  std_logic;  --输出完成标记位 
   SIGNAL output_valid_reg_new     :  std_logic;  --输出完成标记位   
   
begin

-- 变量初始化
   txd <= txd_xhdl3;
   txd_xhdl3 <= txd_reg;
   
--   input_ready <= txd_flag;--赋值操作！   
   
--   txd_flag <= '1';--初始化状态为"完成"，这句话不能加，否则无法编译通过。

--	div_par <= input_baud;

   PROCESS(clk,Reset)
   BEGIN
      
      IF (Reset = '1') THEN
         cnt_delay <= "00000000000000000000";    
         start_delaycnt <= '0';
		 div_par <= "0000000101000110";--复位之后默认的波特率为9600（0x146）
		 
     ELSIF(input_baud = "0000") THEN div_par <= "0000010100010111";--2400（0x517）
	  ELSIF(input_baud = "0001") THEN div_par <= "0000001010001100";--4800（0x28C）
	  ELSIF(input_baud = "0010") THEN div_par <= "0000000101000110";--9600（0x146）
	  ELSIF(input_baud = "0011") THEN div_par <= "0000000010100011";--19200（0xA3）
	  ELSIF(input_baud = "0100") THEN div_par <= "0000000001010010";--38400（0x52）	  
	  ELSIF(input_baud = "0101") THEN div_par <= "0000000000101001";--76800（0x29）
	  ELSIF(input_baud = "0110") THEN div_par <= "0000000000011100";--115200（0x1C）
	  ELSIF(input_baud = "0111") THEN div_par <= "0000000000001110";--230400（0x0E）
	  
	  END IF;
	  

	  
   END PROCESS;

   PROCESS(clk,Reset)
   BEGIN
      
      IF (Reset = '1') THEN
         cnt_delay <= "00000000000000000000";    
         start_delaycnt <= '0';
      ELSIF(clk'EVENT AND clk='1')THEN	  
         IF (start_delaycnt = '1') THEN
            IF (cnt_delay /= "11000011010100000000") THEN
               cnt_delay <= cnt_delay + "00000000000000000001";    
            ELSE
               cnt_delay <= "00000000000000000000";    
               start_delaycnt <= '0';    
            END IF;
         ELSE
            IF (cnt_delay = "00000000000000000000") THEN
               start_delaycnt <= '1';    
            END IF;
         END IF;
      END IF;
   END PROCESS;
   
   PROCESS(clk,Reset)
   BEGIN
      IF (Reset = '1') THEN
		input_valid_reg <= '0';  
		input_ready <= '1';--复位情况下，输入是有效的！
		
      ELSIF(clk'EVENT AND clk='1')THEN
	  
		IF(input_valid = '1') THEN --如果捕捉到高电平，表示输入的数据是有效的！
		input_valid_reg <= '1';      --不同时钟域下的数据锁存起来
		input_data_reg <= input_data;--不同时钟域下的数据锁存起来
		input_ready <= '0';--接收到一个新的数据，此时设置为无效！
		END IF;

		txd_flag_new <= txd_flag;
		txd_flag_old <= txd_flag_new;
		
		IF(txd_flag_new>txd_flag_old) THEN  --捕捉上升沿,说明发送完一帧数据！
		input_valid_reg <= '0';	
		input_ready <= '1';--发送结束后，输入是有效的！
		END IF;
		
		output_valid_reg_new <= output_valid_reg;
		output_valid_reg_old <= output_valid_reg_new;
		
		IF(output_valid_reg_new > output_valid_reg_old) THEN
		output_valid <= '1';--捕捉上升沿
		ELSE 
		output_valid <= '0';
		END IF;		
		
		
      END IF;
   END PROCESS;   
   

   PROCESS(clk,Reset)
   BEGIN
      
      IF (Reset = '1') THEN
         div_reg <= "0000000000000000";    
      ELSIF(clk'EVENT AND clk='1')THEN
         IF (div_reg = div_par - "0000000000000001") THEN
            div_reg <= "0000000000000000";    
         ELSE
            div_reg <= div_reg + "0000000000000001";    
         END IF;
      END IF;
   END PROCESS;

   PROCESS(clk,Reset)  --分频得到8倍波特率的时钟
   BEGIN
      
      IF (Reset = '1') THEN
         clkbaud8x <= '0';    
      ELSIF(clk'EVENT AND clk='1')THEN
         IF (div_reg = div_par - "0000000000000001") THEN
            clkbaud8x <= NOT clkbaud8x;    
         END IF;
      END IF;
   END PROCESS;

   PROCESS(clkbaud8x,Reset)
   BEGIN
      IF (Reset = '1') THEN
         div8_rec_reg <= "000";    
      ELSE IF(clkbaud8x'EVENT AND clkbaud8x = '1') THEN
         IF (recstart = '1') THEN  --接收开始标志
            div8_rec_reg <= div8_rec_reg + "001";--接收开始后，时隙数在8倍波特率的时钟下加1循环    
         END IF;
	   END IF;
      END IF;
   END PROCESS;

   PROCESS(clkbaud8x,Reset)
   BEGIN
      IF (Reset = '1') THEN
         div8_tras_reg <= "000";    
      ELSE IF(clkbaud8x'EVENT AND clkbaud8x = '1') THEN
         IF (trasstart = '1') THEN
            div8_tras_reg <= div8_tras_reg + "001";--发送开始后，时隙数在8倍波特率的时钟下加1循环    
         END IF;
	   END IF;
      END IF;
   END PROCESS;

   PROCESS(div8_rec_reg)
   BEGIN
      IF (div8_rec_reg = "111") THEN
         clkbaud_rec <= '1'; ---在第7个时隙，接收使能信号有效，将数据打入   
      ELSE
         clkbaud_rec <= '0';    
      END IF;
   END PROCESS;

   PROCESS(div8_tras_reg)
   BEGIN
      IF (div8_tras_reg = "111") THEN
         clkbaud_tras <= '1';  --诘?个时隙，发送使能信号有效，将数据发出  
      ELSE
         clkbaud_tras <= '0';    
      END IF;
   END PROCESS;

   PROCESS(clkbaud8x,Reset)
   BEGIN
      IF (Reset = '1') THEN
         txd_reg <= '1';    
         trasstart <= '0';    
         txd_buf <= "00000000";    
         state_tras <= "1111";  --Idle状态   
         send_state <= "000";    
		 txd_flag <= '1';  --完成标记位  
      ELSE IF(clkbaud8x'EVENT AND clkbaud8x = '1') THEN
			IF (input_valid_reg = '1' AND txd_flag = '1') THEN --更新FPGA中需要发送的数值,一旦发送完毕就会更新上位机传递过来的新数值。
			   txd_buf <= input_data_reg; --需要发送的数据信息
			   txd_flag <= '0';  --完成标记位，置"假"表示正在发送  
			   state_tras <= "0000";--初始化发送状态

			ELSE
            CASE state_tras IS
               WHEN "0000" =>  --发送起始位
                        IF ((NOT trasstart='1') AND (send_state < "111") ) THEN
                           trasstart <= '1';    
                        ELSE
                           IF (send_state < "111") THEN
                              IF (clkbaud_tras = '1') THEN
                                 txd_reg <= '0';    
                                 state_tras <= state_tras + "0001";    
                              END IF;
                           ELSE 
                              state_tras <= "0000";    
                           END IF;
                        END IF;
               WHEN "0001" => --发送第1位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0010" =>  --发送第2位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0011" =>  --发送第3位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0100" => --发送第4位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0101" => --发送第5位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0110" => --发送第6位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "0111" => --发送第7位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "1000" =>  --发送第8位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= txd_buf(0);    
                           txd_buf(6 DOWNTO 0) <= txd_buf(7 DOWNTO 1);    
                           state_tras <= state_tras + "0001";    
                        END IF;
               WHEN "1001" =>  --发送停止位
                        IF (clkbaud_tras = '1') THEN
                           txd_reg <= '1';    
                           txd_buf <= "01010101";    
                           state_tras <= state_tras + "0001"; 
                        END IF;
               WHEN OTHERS  =>
                        IF (clkbaud_tras = '1') THEN
						   txd_flag <= '1';  --完成标注位，置"真"，表示完成了一个字节的传输						
                           state_tras <= "1111";  --已经完成一次传输，重复在这个ideal状态执行，相当于空循环  
                           trasstart <= '1';    
                        END IF;
               
            END CASE;
         END IF;
		END IF;
	END IF;
   END PROCESS;

   PROCESS(clkbaud8x,Reset)  --接受PC机的数据
   BEGIN
      IF (Reset = '1') THEN
         rxd_reg1 <= '0';    
         rxd_reg2 <= '0';    
         rxd_buf <= "00000000";    
         state_rec <= "0000";    
         recstart <= '0';    
         recstart_tmp <= '0'; 
		 output_valid_reg <= '0';--初始化接收完成标记位
      ELSE IF(clkbaud8x'EVENT AND clkbaud8x = '1') THEN
         rxd_reg1 <= rxd;    
         rxd_reg2 <= rxd_reg1; 
		 output_valid_reg <= '0';--清除完成标志位！
		 
         IF (state_rec = "0000") THEN
            IF (recstart_tmp = '1') THEN
               recstart <= '1';    
               recstart_tmp <= '0';    
               state_rec <= state_rec + "0001";    
            ELSE
               IF ((NOT rxd_reg1 AND rxd_reg2) = '1') THEN --检测到起始位的下降沿，进入接受状态
                  recstart_tmp <= '1';    
               END IF;
            END IF;
         ELSE
            IF (state_rec >= "0001" AND state_rec<="1000") THEN
               IF (clkbaud_rec = '1') THEN
                  rxd_buf(7) <= rxd_reg2;    
                  rxd_buf(6 DOWNTO 0) <= rxd_buf(7 DOWNTO 1);    
                  state_rec <= state_rec + "0001";    
               END IF;
            ELSE
               IF (state_rec = "1001") THEN
                  IF (clkbaud_rec = '1') THEN
                     state_rec <= "0000";    
                     recstart <= '0';
					 output_valid_reg <= '1';--表示某一次接收数据完成
					 output_data <= rxd_buf;
					 				 
                  END IF;
               END IF;
            END IF;
         END IF;
      END IF;
	END IF;
   END PROCESS;

end Behavioral;

