library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ram_addr_test is
	port(
		clk_i       : in  std_logic;

    BRAM_FILL   : in std_logic;
    BRAM_DBG    : out std_logic;
    
		BRAM_CLK    : out std_logic;   -- memory clock
		BRAM_A      : out std_logic_vector(15 downto 0); -- memory address
		BRAM_DO     : out std_logic_vector(15 downto 0); -- memory data in
		BRAM_DI     : in  std_logic_vector(15 downto 0); -- memory data out
		BRAM_EN     : out std_logic;   -- memory enable
		BRAM_WE     : out std_logic_vector(0 downto 0)    -- memory write enable
  );
end entity ram_addr_test;


architecture rtl of ram_addr_test is
  signal addr_cnt : std_logic_vector (15 downto 0);
begin
	BRAM_CLK <= clk_i;
  BRAM_EN  <= '1';
  
  --
  process(clk_i) is
	begin
    if rising_edge(clk_i) then
      if (BRAM_FILL = '0') then
        addr_cnt <= (others => '0');
      else
        addr_cnt <= addr_cnt + 1;
      end if;
    end if;
	end process;
  
  --
	process(clk_i) is
	begin
    if rising_edge(clk_i) then
      if (BRAM_FILL = '0') then
        BRAM_WE <= "0";
        BRAM_A  <= (others => '0');
        if (BRAM_DI = x"55AA") then
          BRAM_DBG <= '1';
        else
          BRAM_DBG <= '0';
        end if;
      else
        BRAM_WE <= "1";
        BRAM_A  <= addr_cnt;
        BRAM_DO <= addr_cnt;
      end if;
    end if;
	end process;
  
end architecture rtl;


