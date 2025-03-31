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

    SIGNAL alu_b_operand : UNSIGNED(DW - 1 DOWNTO 0);

BEGIN

    alu_b_operand <= reg_b WHEN alu_sel_b = "0" ELSE imm;

    pc_branch <= pc + imm;

    link_address <= pc + 4;

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