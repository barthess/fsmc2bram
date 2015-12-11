----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:43:03 07/21/2015 
-- Design Name: 
-- Module Name:    fsmc_glue - A_fsmc_glue 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsmc2bram_async is
  Generic (
    AW : positive; -- total FSMC address width
    DW : positive; -- data witdth
    USENBL : std_logic; -- set to '1' if you want NBL (byte select) pin support
    AWUSED : positive -- actually used address lines
  );
	Port (
    clk : in std_logic; -- high speed internal FPGA clock
    mmu_int : out std_logic;
    
    A : in STD_LOGIC_VECTOR (AW-1 downto 0);
    D : inout STD_LOGIC_VECTOR (DW-1 downto 0);
    NWE : in STD_LOGIC;
    NOE : in STD_LOGIC;
    NCE : in STD_LOGIC;
    NBL : in std_logic_vector (1 downto 0);
    
    bram_a   : out STD_LOGIC_VECTOR (AWUSED-1 downto 0);
    bram_di  : in  STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_do  : out STD_LOGIC_VECTOR (DW-1 downto 0);
    bram_ce  : out STD_LOGIC;
    bram_we  : out STD_LOGIC_VECTOR (0 downto 0);
    bram_clk : out std_logic
  );
  

  -- just cut out unused lines from address bus
  function address2cnt(A : in std_logic_vector(AW-1 downto 0)) return std_logic_vector is
  begin
    return A(AWUSED-1 downto 0);
  end address2cnt;

  -- MMU check routine. Must be called when addres sampled
  function mmu_check(A   : in std_logic_vector(AW-1 downto 0);
                     NBL : in std_logic_vector(1 downto 0)) 
                     return std_logic is
  begin
    if (A(AW-1 downto AWUSED) /= 0) or ((NBL(0) /= NBL(1) and USENBL = '0')) then
      return '1';
    else
      return '0';
    end if;
  end mmu_check;

  -- Return actual address bits
  function get_addr(A : in std_logic_vector(AW-1 downto 0)) 
                     return std_logic_vector is
  begin
    return A(AWUSED-1 downto 0);
  end get_addr;
  
end fsmc2bram_async;



-----------------------------------------------------------------------------

architecture beh of fsmc2bram_async is

type state_t is (IDLE, ADSET, FLUSH);

  signal state : state_t := IDLE;
  signal a_reg : STD_LOGIC_VECTOR (AWUSED-1 downto 0);
  signal d_reg : STD_LOGIC_VECTOR (DW-1 downto 0); 
  signal nbl_reg : STD_LOGIC_VECTOR (1 downto 0); 
  signal nce_reg : STD_LOGIC:= '1';
  signal noe_reg : STD_LOGIC:= '1';
  -- shiftregister for low-to-high detection
  signal nwe_reg : STD_LOGIC_VECTOR (1 downto 0) := "11";

begin

  -- connect permanent signals
  bram_clk <= clk;

  -- coonect 3-state data bus
  D <= bram_di when (NCE = '0' and NOE = '0') else (others => 'Z');
  
  -- bus sampling process
  process(clk) begin
    if rising_edge(clk) then
      noe_reg <= NOE;
      nce_reg <= NCE;
      nbl_reg <= NBL;
      nwe_reg <= nwe_reg(0) & NWE;
    end if;
  end process;
  
  -- main process
  process(clk) begin
    if rising_edge(clk) then
      if (NCE = '1') then
        state <= IDLE;
        bram_we <= "0";
        bram_ce <= '0';
      else
        case state is
        when IDLE =>
          if (NOE = '0') then
            state <= ADSET;
          elsif (nwe_reg = "01") then
            bram_ce <= '1';
            bram_we <= "1";
            bram_a  <= get_addr(A);
            bram_do <= D;
            mmu_int <= mmu_check(A, NBL);
            state <= FLUSH;
          end if;
          
        when FLUSH =>
          bram_we <= "0";
          
        when ADSET =>
          mmu_int <= mmu_check(A, NBL);
          bram_ce <= '1';
          bram_a  <= get_addr(A);
        end case;
        
      end if;
    end if; -- clk
  end process;
end beh;




