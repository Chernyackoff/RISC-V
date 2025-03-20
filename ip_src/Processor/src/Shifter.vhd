LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Shifter IS
    GENERIC(SHIFTER_DATA_WIDHT : INTEGER := 32);
    PORT(
        rst : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
        clk : IN STD_LOGIC := '0';--! input clock signal
        SHIFTER_INPUT : IN UNSIGNED(SHIFTER_DATA_WIDHT - 1 DOWNTO 0) := (OTHERS => '0'); -- input (from sign-extend block)
        SHIFTER_OUTPUT : OUT UNSIGNED(SHIFTER_DATA_WIDHT - 1 DOWNTO 0) := (OTHERS => '0') -- output
    );
END ENTITY Shifter;

ARCHITECTURE RTL OF Shifter IS

BEGIN
shift_proc: PROCESS(clk)
BEGIN

if(rst = '0') then
    if(rising_edge(clk)) then
        SHIFTER_OUTPUT <= SHIFTER_INPUT SLL 2;
    end if;
end if;
END PROCESS shift_proc;
END ARCHITECTURE RTL;