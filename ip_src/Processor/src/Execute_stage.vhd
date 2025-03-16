LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Execute_stage is
    GENERIC(
        DATA_WIDTH: INTEGER := 32;-- Data lines amount
        FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
        FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
        MUL_SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
    PORT(
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC;--! input clock signal
        SRC_A : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        SRC_B_1 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        SRC_B_2 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        ALU_RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        --WRITEDATA : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        FUNCT3 : IN UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        FUNCT7 : IN UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
        MUL_SEL : IN UNSIGNED(MUL_SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0')
    );
END ENTITY Execute_stage;

ARCHITECTURE RTL OF Execute_stage is

    COMPONENT ALU IS
    GENERIC (
        ALU_DATA_WIDTH: INTEGER;-- Data lines amount
        ALU_FUNCT3_WIDTH: INTEGER;-- funct3 signal lines amount
        ALU_FUNCT7_WIDTH: INTEGER-- funct7 signal lines amount
    );
    PORT (
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC;--! input clock signal
        alu_input_a : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! input from regfile
        alu_input_b : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! input from multiplexer
        alu_output : OUT unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! output
        alu_funct3 : IN unsigned(ALU_FUNCT3_WIDTH - 1 DOWNTO 0);--! input funct3 field from command
        alu_funct7 : IN unsigned(ALU_FUNCT7_WIDTH - 1 DOWNTO 0)--! input funct7 field from command
    );
    END COMPONENT;

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
    --SIGNAL SRC_A : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SRC_B : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL SRC_B_1 : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL SRC_B_2 : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    --SIGNAL ALU_RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
    --WRITEDATA : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
    --SIGNAL FUNCT3 : UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0);
    --SIGNAL FUNCT7 : UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0);
    --SIGNAL MUL_SEL : UNSIGNED(MUL_SEL_WIDTH - 1 DOWNTO 0);


    BEGIN
    alu_inst: ALU
    GENERIC MAP (
        ALU_DATA_WIDTH => DATA_WIDTH,
        ALU_FUNCT3_WIDTH => FUNCT3_WIDTH,
        ALU_FUNCT7_WIDTH => FUNCT7_WIDTH
    )
    PORT MAP(
        rst => rst,
        clk => clk,
        alu_input_a => SRC_A,
        alu_input_b => SRC_B,
        alu_output => ALU_RESULT,
        alu_funct3 => FUNCT3,
        alu_funct7 => FUNCT7
    );

    mul_inst : Multiplexer
    GENERIC MAP (
        MUL_DATA_WIDTH => DATA_WIDTH,
        MUL_SEL_WIDTH => MUL_SEL_WIDTH
    )
    PORT MAP (
        rst => rst,
        clk => clk,
        mul_input_0 => SRC_B_1,
        mul_input_1 => SRC_B_2,
        mul_output => SRC_B,
        mul_sel => MUL_SEL
    );

    --main_proc : PROCESS 
    --BEGIN
        --IF(RST = '0') THEN
            --IF(rising_edge(clk)) THEN

            --END IF;
        --END IF;

    --END PROCESS main_proc;
end ARCHITECTURE RTL;