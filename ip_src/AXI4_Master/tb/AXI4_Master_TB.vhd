
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity AXI4_Master_TB is
  GENERIC (
    EDGE_CLK : TIME := 2 ns
  );
end entity AXI4_Master_TB;
architecture rtl of AXI4_Master_TB is
  SIGNAL rst   : STD_LOGIC := '1';
  SIGNAL refclk : STD_LOGIC := '0';
  SIGNAL test_completed : BOOLEAN := false;
    COMPONENT AXI4_Master_TOP IS
      PORT (
        refclk : IN  STD_LOGIC;--! reference clock expect 250Mhz
        rst    : IN  STD_LOGIC--! sync active high reset. sync -> refclk
      );
    END COMPONENT;
  component design_1 is
  port (
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    addr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    req : in STD_LOGIC;
    ready : in STD_LOGIC;
    data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    valid : out STD_LOGIC
  );
  end component design_1;
  signal data_out : std_logic_vector(31 downto 0);
  signal valid_in  : std_logic;
begin
design_1_i: component design_1
     port map (
      addr(31 downto 0) => (others => '0'),
      clk => refclk,
      data(31 downto 0) => data_out,
      ready => '1',
      req => '1',
      rst => '1',
      valid => valid_in
    );

 

  test_clk_generator : PROCESS
  BEGIN
    IF NOT test_completed THEN
      refclk <= NOT refclk;
      WAIT for EDGE_CLK;
    ELSE
      WAIT;
    END IF;
  END PROCESS test_clk_generator;

  test_bench_main : PROCESS
  BEGIN
    test_completed <= true AFTER 100 ns;
    WAIT;
  END PROCESS test_bench_main;
end architecture rtl;
