----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:35:50 09/09/2015 
-- Design Name: 
-- Module Name:    root - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Non standard library from synopsis (for dev_null functions)
use ieee.std_logic_misc.all;


entity root is
  generic (
    FSMC_A_WIDTH : positive := 23;
    FSMC_D_WIDTH : positive := 16;
    FSMC_A_USED  : positive := 16
  );
  port ( 
    CLK_IN_27MHZ : in std_logic;

    FSMC_A : in std_logic_vector ((FSMC_A_WIDTH - 1) downto 0);
    FSMC_D : inout std_logic_vector ((FSMC_D_WIDTH - 1) downto 0);
    FSMC_NBL : in std_logic_vector (1 downto 0);
    FSMC_NOE : in std_logic;
    FSMC_NWE : in std_logic;
    FSMC_NCE : in std_logic;
    FSMC_CLK : in std_logic;
    
    STM_IO_MUL_RDY : out std_logic;
    STM_IO_MUL_DV  : in std_logic;
    STM_IO_MMU_INT : out std_logic;
    STM_IO_FPGA_READY : out std_logic;
    STM_IO_OLD_FSMC_CLK : in std_logic;
    
    DEV_NULL_BANK1 : out std_logic; -- warning suppressor
    DEV_NULL_BANK0 : out std_logic -- warning suppressor
	);
end root;


architecture Behavioral of root is

signal clk_90mhz  : std_logic;
signal clk_180mhz : std_logic;
signal clk_360mhz : std_logic;
signal clk_locked : std_logic;

-- wires for memspace to fsmc
signal wire_bram_a   : std_logic_vector (FSMC_A_USED-1  downto 0); 
signal wire_bram_di  : std_logic_vector (FSMC_D_WIDTH-1 downto 0); 
signal wire_bram_do  : std_logic_vector (FSMC_D_WIDTH-1 downto 0); 
signal wire_bram_ce  : std_logic; 
signal wire_bram_we  : std_logic_vector (0 downto 0);  
signal wire_bram_clk : std_logic; 
signal wire_bram_asample : std_logic; 

-- wires for memory filler
signal wire_memtest_a    : std_logic_vector (FSMC_A_USED-1 downto 0); 
signal wire_memtest_di   : std_logic_vector (15 downto 0); 
signal wire_memtest_do   : std_logic_vector (15 downto 0); 
signal wire_memtest_ce   : std_logic;
signal wire_memtest_we   : std_logic_vector (0 downto 0);  
signal wire_memtest_clk  : std_logic;


begin

  -- clocking sources
	clk_src : entity work.clk_src port map (
		CLK_IN1  => CLK_IN_27MHZ,
    
  	CLK_OUT1 => clk_90mhz,
		CLK_OUT2 => clk_180mhz,
		CLK_OUT3 => clk_360mhz,
    
		LOCKED   => clk_locked
	);


  ram_addr_test : entity work.ram_addr_test
  generic map (
    AW => FSMC_A_USED
  )
  port map (
    clk_i    => clk_90mhz,

    BRAM_FILL => STM_IO_MUL_DV,
    BRAM_DBG  => STM_IO_MUL_RDY,
    
    BRAM_CLK => wire_memtest_clk, -- memory clock
    BRAM_A   => wire_memtest_a,   -- memory address
    BRAM_DI  => wire_memtest_di,  -- memory data in
    BRAM_DO  => wire_memtest_do,  -- memory data out
    BRAM_EN  => wire_memtest_ce,  -- memory enable
    BRAM_WE  => wire_memtest_we   -- memory write enable
  );

  fsmc2bram : entity work.fsmc2bram 
    generic map (
      AW => FSMC_A_WIDTH,
      DW => FSMC_D_WIDTH,
      USENBL => '0',
      AWUSED => FSMC_A_USED
    )
    port map (
      fsmc_clk => FSMC_CLK,
      mmu_int => STM_IO_MMU_INT,
      
      A   => FSMC_A,
      D   => FSMC_D,
      NCE => FSMC_NCE,
      NOE => FSMC_NOE,
      NWE => FSMC_NWE,
      NBL => FSMC_NBL,

      bram_a   => wire_bram_a,
      bram_di  => wire_bram_do,
      bram_do  => wire_bram_di,
      bram_ce  => wire_bram_ce,
      bram_we  => wire_bram_we,
      bram_clk => wire_bram_clk
    );
    
  bram_test : entity work.bram
    PORT MAP (
      -- port A connected to FSMC adapter
      addra => wire_bram_a,
      dina  => wire_bram_di,
      douta => wire_bram_do,
      wea   => wire_bram_we,
      ena   => wire_bram_ce,
      clka  => wire_bram_clk,

      -- port B connected to PWM      
      addrb => wire_memtest_a,
      dinb  => wire_memtest_do,
      doutb => wire_memtest_di,
      enb   => wire_memtest_ce,
      web   => wire_memtest_we,
      clkb  => wire_memtest_clk
    );
    
  DEV_NULL_BANK0 <= STM_IO_OLD_FSMC_CLK;
  DEV_NULL_BANK1 <= '1';

	-- raize ready flag
	STM_IO_FPGA_READY <= not clk_locked;

end Behavioral;

