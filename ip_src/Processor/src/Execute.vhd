LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY execute IS
    GENERIC (
        DW : INTEGER := 32; -- Data width
        F3W : INTEGER := 3; -- Funct3 width
        F7W : INTEGER := 7; -- Funct7 width
        SW : INTEGER := 1 -- Select width (for alu_sel_b)
    );
    PORT (
        -- Control Inputs
        alu_sel_b : IN UNSIGNED(SW - 1 DOWNTO 0); -- Selects ALU B input (reg_b or imm)
        funct3 : IN UNSIGNED(F3W - 1 DOWNTO 0); -- ALU control
        funct7 : IN UNSIGNED(F7W - 1 DOWNTO 0); -- ALU control

        -- Data Inputs
        pc : IN UNSIGNED(DW - 1 DOWNTO 0); -- Current Program Counter
        reg_a : IN UNSIGNED(DW - 1 DOWNTO 0); -- Operand A (rs1)
        reg_b : IN UNSIGNED(DW - 1 DOWNTO 0); -- Operand B (rs2)
        imm : IN UNSIGNED(DW - 1 DOWNTO 0); -- Sign-extended immediate

        -- Data Outputs
        alu_out : OUT UNSIGNED(DW - 1 DOWNTO 0); -- Result of ALU operation
        writedata : OUT UNSIGNED(DW - 1 DOWNTO 0); -- Data for memory store (comes from reg_b)
        pc_branch : OUT UNSIGNED(DW - 1 DOWNTO 0); -- Calculated branch target address (PC + imm)
        link_address : OUT UNSIGNED(DW - 1 DOWNTO 0); -- PC + 4 for JAL/JALR return address

        -- Status Outputs
        zero_flag : OUT STD_LOGIC -- ALU Zero flag output
    );
END ENTITY execute;

ARCHITECTURE RTL OF execute IS
    COMPONENT ALU IS
        GENERIC (
            ALU_DATA_WIDTH : INTEGER := 32;
            ALU_FUNCT3_WIDTH : INTEGER := 3;
            ALU_FUNCT7_WIDTH : INTEGER := 7
        );
        PORT (
            alu_input_a : IN UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0);
            alu_input_b : IN UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0);
            alu_funct3 : IN UNSIGNED(ALU_FUNCT3_WIDTH - 1 DOWNTO 0);
            alu_funct7 : IN UNSIGNED(ALU_FUNCT7_WIDTH - 1 DOWNTO 0);
            alu_output : OUT UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0);
            zero_flag : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Multiplexer IS
        GENERIC (
            MUL_DATA_WIDTH : INTEGER := 32;
            MUL_SEL_WIDTH : INTEGER := 1
        );
        PORT (
            mul_input_0 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);
            mul_input_1 : IN unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);
            mul_output : OUT unsigned(MUL_DATA_WIDTH - 1 DOWNTO 0);
            mul_sel : IN unsigned(MUL_SEL_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Adder IS
        GENERIC (ADDER_DATA_WIDTH : INTEGER := 32);
        PORT (
            ADDER_INPUT_A : IN UNSIGNED(ADDER_DATA_WIDTH - 1 DOWNTO 0);
            ADDER_INPUT_B : IN UNSIGNED(ADDER_DATA_WIDTH - 1 DOWNTO 0);
            ADDER_OUTPUT : OUT UNSIGNED(ADDER_DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL alu_b_operand : UNSIGNED(DW - 1 DOWNTO 0);
    SIGNAL pc_plus_4 : UNSIGNED(DW - 1 DOWNTO 0);

BEGIN

    pc_plus_4 <= pc + 4;

    mux_alu_operand_b : Multiplexer
    GENERIC MAP(
        MUL_DATA_WIDTH => DW,
        MUL_SEL_WIDTH => SW
    )
    PORT MAP(
        mul_input_0 => reg_b,
        mul_input_1 => imm,
        mul_sel => alu_sel_b,
        mul_output => alu_b_operand
    );

    add_branch_target : Adder
    GENERIC MAP(
        ADDER_DATA_WIDTH => DW
    )
    PORT MAP(
        ADDER_INPUT_A => pc,
        ADDER_INPUT_B => imm,
        ADDER_OUTPUT => pc_branch
    );

    link_address <= pc_plus_4;

    writedata <= reg_b;

    alu_inst : ALU
    GENERIC MAP(
        ALU_DATA_WIDTH => DW,
        ALU_FUNCT3_WIDTH => F3W,
        ALU_FUNCT7_WIDTH => F7W
    )
    PORT MAP(
        alu_input_a => reg_a,
        alu_input_b => alu_b_operand,
        alu_funct3 => funct3,
        alu_funct7 => funct7,
        alu_output => alu_out,
        zero_flag => zero_flag
    );

END ARCHITECTURE RTL;