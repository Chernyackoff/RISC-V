LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Writeback_stage is
    GENERIC(
        DATA_WIDTH: INTEGER := 32;-- Data lines amount
        SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
    PORT(
        rst    : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC := '0';--! input clock signal
        IN_ALU : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal from ALU
        IN_MEM : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal from memory
        RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU out
        ALU_MEM_SEL : IN UNSIGNED(SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operand B multiplexer selection signal
    );
END ENTITY Writeback_stage;

ARCHITECTURE RTL OF Writeback_stage is

    COMPONENT Multiplexer IS
    GENERIC (
        MUL_DATA_WIDTH: INTEGER; --! Data lines amount
        MUL_SEL_WIDTH: INTEGER --! select signal lines amount
    );
    PORT (
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC;--! input clock signal
        mul_input_0 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! input 0 (from regfile)
        mul_input_1 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! input 1 (flom extender)
        mul_output : OUT unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);--! output
        mul_sel : IN unsigned(MUL_SEL_WIDTH - 1 DOWNTO 0)--! select signal, from control unit
    );
    END COMPONENT;

    SIGNAL IN_A : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IN_B : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IMM_DATA : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IMM_DATA_SHIFT : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');


    BEGIN

    mul_inst : Multiplexer
    GENERIC MAP (
        MUL_DATA_WIDTH => DATA_WIDTH,
        MUL_SEL_WIDTH => SEL_WIDTH
    )
    PORT MAP (
        rst => rst,
        clk => clk,
        mul_input_0 => IN_ALU,
        mul_input_1 => IN_MEM,
        mul_output => RESULT,
        mul_sel => ALU_MEM_SEL
    );
end ARCHITECTURE RTL;