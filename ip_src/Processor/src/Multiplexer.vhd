LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity Multiplexer is
GENERIC (
    MUL_DATA_WIDTH: INTEGER := 32; --! Data lines amount
    MUL_SEL_WIDTH: INTEGER := 1 --! select signal lines amount
);
PORT (
    rst    : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
    clk    : IN STD_LOGIC := '0';--! input clock signal
    mul_input_0 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! input 0 (from regfile)
    mul_input_1 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! input 1 (flom extender)
    mul_output : OUT unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! output
    mul_sel : IN unsigned(MUL_SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0')--! select signal, from control unit
);
END entity Multiplexer;


architecture rtl of Multiplexer is
    SIGNAL out_val : unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN
main_proc : PROCESS(clk) is
BEGIN
    if(rst = '0') then
        if(rising_edge(clk)) then
            if(mul_sel = "0") then
                out_val <= mul_input_0;
            else
                out_val <= mul_input_1;
            end if;
            mul_output <= out_val;
        end if;
    end if;
end process main_proc;
END architecture rtl;