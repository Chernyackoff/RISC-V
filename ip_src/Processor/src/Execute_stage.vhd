LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Execute_stage is
    GENERIC(
        DATA_WIDTH: INTEGER := 32;-- Data lines amount
        FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
        FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
        SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
    PORT(
        rst    : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC := '0';--! input clock signal
        IN_REG_A : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal, A operand for ALU
        IN_REG_B : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal , B operand for ALU (switch by multiplexer)
        IN_IMM : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal , B operand for ALU (switch by multiplexer)
        ALU_RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU out
        WRITEDATA : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- output data signal, for writing into memory
        FUNCT3 : IN UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operation signal FUNCT3
        FUNCT7 : IN UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operation signal FUNCT7
        ALU_SEL_B : IN UNSIGNED(SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operand B multiplexer selection signal
        ZERO_FLAG : OUT STD_LOGIC := '0'; -- zero result sign
        PC_PLUS_4 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input PC + 4 value
        PC_BRANCH : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0') -- modified for branch PC value 

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
        alu_funct7 : IN unsigned(ALU_FUNCT7_WIDTH - 1 DOWNTO 0);--! input funct7 field from command
        zero_flag : OUT STD_LOGIC-- sign of zero result
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
    COMPONENT Adder IS
        GENERIC(ADDER_DATA_WIDHT : INTEGER);
        PORT(
            rst : IN STD_LOGIC;--! sync active high reset. sync -> refclk
            clk : IN STD_LOGIC;--! input clock signal
            ADDER_INPUT_A : IN UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0); -- input A (from fetch adder)
            ADDER_INPUT_B : IN UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0); -- input B (from shifter)
            ADDER_OUTPUT : OUT UNSIGNED(ADDER_DATA_WIDHT - 1 DOWNTO 0) -- output
        );
    END COMPONENT;

    COMPONENT Shifter IS
        GENERIC(SHIFTER_DATA_WIDHT : INTEGER);
        PORT(
            rst : IN STD_LOGIC;--! sync active high reset. sync -> refclk
            clk : IN STD_LOGIC;--! input clock signal
            SHIFTER_INPUT : IN UNSIGNED(SHIFTER_DATA_WIDHT - 1 DOWNTO 0); -- input (from sign-extend block)
            SHIFTER_OUTPUT : OUT UNSIGNED(SHIFTER_DATA_WIDHT - 1 DOWNTO 0) -- output
        );
    END COMPONENT;

    SIGNAL IN_A : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IN_B : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IMM_DATA : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL IMM_DATA_SHIFT : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');


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
        alu_input_a => IN_REG_A,
        alu_input_b => IN_B,
        alu_output => ALU_RESULT,
        alu_funct3 => FUNCT3,
        alu_funct7 => FUNCT7,
        zero_flag => ZERO_FLAG
    );

    mul_inst : Multiplexer
    GENERIC MAP (
        MUL_DATA_WIDTH => DATA_WIDTH,
        MUL_SEL_WIDTH => SEL_WIDTH
    )
    PORT MAP (
        rst => rst,
        clk => clk,
        mul_input_0 => IN_REG_B,
        mul_input_1 => IMM_DATA,
        mul_output => IN_B,
        mul_sel => ALU_SEL_B
    );

    adder_inst : Adder
    GENERIC MAP (
        ADDER_DATA_WIDHT => DATA_WIDTH
    )
    PORT MAP (
        rst => rst,
        clk => clk,
        ADDER_INPUT_A => IMM_DATA_SHIFT,
        ADDER_INPUT_B => PC_PLUS_4,
        ADDER_OUTPUT => PC_BRANCH
    );

    shifter_inst : Shifter
    GENERIC MAP (
        SHIFTER_DATA_WIDHT => DATA_WIDTH
    )
    PORT MAP (
        rst => rst,
        clk => clk,
        SHIFTER_INPUT => IMM_DATA,
        SHIFTER_OUTPUT => IMM_DATA_SHIFT
    );

    main_proc : PROCESS(clk)
    BEGIN
        IF(RST = '0') THEN
            IF(rising_edge(clk)) THEN
                IMM_DATA <= IN_IMM;
                WRITEDATA <= IN_REG_B;
            END IF;
        END IF;
    END PROCESS main_proc;
end ARCHITECTURE RTL;