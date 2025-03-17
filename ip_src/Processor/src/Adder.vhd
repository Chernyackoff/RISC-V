LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Adder IS
    GENERIC(ADDER_DATA_WIDHT : INTEGER := 32);
    PORT(
        rst : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
        clk : IN STD_LOGIC := '0';--! input clock signal
        ADDER_INPUT_A : IN UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0) := (OTHERS => '0'); -- input A (from fetch adder)
        ADDER_INPUT_B : IN UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0) := (OTHERS => '0'); -- input B (from shifter)
        ADDER_OUTPUT : OUT UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0) := (OTHERS => '0') -- output
    );
END ENTITY Adder;

ARCHITECTURE RTL OF Adder IS

BEGIN
add_proc: PROCESS(clk)
BEGIN

if(rst = '0') then
    if(rising_edge(clk)) then
        ADDER_OUTPUT <= ADDER_INPUT_A + ADDER_INPUT_B;
    end if;
end if;
END PROCESS add_proc;
END ARCHITECTURE RTL;