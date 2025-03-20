
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity Multiplexer_TB is
GENERIC (
    DATA_WIDTH : INTEGER := 32;--! Data lines amount
    SEL_WIDTH: INTEGER := 1--! select signal lines amount
);
end entity Multiplexer_TB;

architecture rtl of Multiplexer_TB is
    component Multiplexer is
    GENERIC (
        MUL_DATA_WIDTH: INTEGER := 32; --! Data lines amount
        MUL_SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
    PORT (
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC;--! input clock signal
        mul_input_0 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! input 0 (from regfile)
        mul_input_1 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! input 1 (flom extender)
        mul_output : OUT unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! output
        mul_sel : IN unsigned(SEL_WIDTH - 1 DOWNTO 0)--! select signal, from control unit
    );
    END component;
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
    SIGNAL a : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"000000AA";
    SIGNAL b : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"000000FF";
    SIGNAL c : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sel : unsigned(SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    signal test_completed: boolean := false;
begin

mul_inst: Multiplexer 
GENERIC MAP (
    MUL_DATA_WIDTH => DATA_WIDTH,
    MUL_SEL_WIDTH => SEL_WIDTH
)
PORT MAP (
    rst => rst,
    clk => clk,
    mul_input_0 => a,
    mul_input_1 => b,
    mul_output => c,
    mul_sel => sel
);

    clk_gen: process is
    begin
        loop
            clk <= not clk;
            wait for 5 us;
        end loop;
    end process clk_gen;

    main : process
    begin
        rst <= '0';
        wait for 15 us;
        sel <= "0";
        wait for 15 us;
        sel <= "1";
        test_completed <= true after 15 us;
        wait;
    end process main;


end architecture rtl;
