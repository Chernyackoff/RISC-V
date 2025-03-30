LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY control_unit IS
    PORT (
        -- Inputs from Decode Stage
        i_opcode : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        i_funct3 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        i_funct7 : IN STD_LOGIC_VECTOR(6 DOWNTO 0);

        -- Inputs from Execute Stage (for branch resolution)
        i_zero_flag : IN STD_LOGIC; -- Assumes Execute stage provides zero flag

        -- Outputs for Pipeline Control
        o_reg_write_enable : OUT STD_LOGIC; -- To Register File (pipelined to WB)
        o_branch_taken : OUT STD_LOGIC; -- To Fetch Stage (Conditional Branch logic)
        o_alu_sel_b : OUT STD_LOGIC; -- To Execute Stage ('0' = RegB, '1' = Imm)
        o_wb_sel_pc4 : OUT STD_LOGIC; -- To Writeback Stage Mux ('1'=PC+4, '0'=ALU) (pipelined to WB)
        o_is_jump : OUT STD_LOGIC -- To Fetch Stage (Unconditional Jumps JAL/JALR)
    );
END ENTITY control_unit;

ARCHITECTURE behavioral OF control_unit IS

    -- Opcodes (Relevant RV32I subset)
    CONSTANT OPCODE_LUI : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110111";
    CONSTANT OPCODE_AUIPC : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010111";
    CONSTANT OPCODE_JAL : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1101111";
    CONSTANT OPCODE_JALR : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100111";
    CONSTANT OPCODE_BRANCH : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100011";
    -- No LOAD ("0000011")
    -- No STORE ("0100011")
    CONSTANT OPCODE_IMM : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010011"; -- Ops with Immediate
    CONSTANT OPCODE_REG : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110011"; -- Ops with Register

    -- Control signal values
    CONSTANT ALU_B_REG : STD_LOGIC := '0';
    CONSTANT ALU_B_IMM : STD_LOGIC := '1';
    CONSTANT WB_SEL_ALU : STD_LOGIC := '0';
    CONSTANT WB_SEL_PC4 : STD_LOGIC := '1';

    -- Internal signal for conditional branch evaluation
    SIGNAL branch_condition_met : STD_LOGIC;

BEGIN

    -- Branch Condition Logic (Minimal: only BEQ/BNE based on zero flag)
    branch_condition_met <= '1' WHEN (i_opcode = OPCODE_BRANCH) AND
        ((i_funct3 = "000" AND i_zero_flag = '1') OR -- BEQ Z=1
        (i_funct3 = "001" AND i_zero_flag = '0')) -- BNE Z=0
        ELSE
        '0';

    -- Main Control Logic (Combinational)
    control_decode_proc : PROCESS (i_opcode, i_funct3, i_funct7, i_zero_flag, branch_condition_met)
    BEGIN
        -- Default values (inactive state)
        o_reg_write_enable <= '0';
        o_branch_taken <= '0';
        o_alu_sel_b <= ALU_B_REG; -- Default
        o_wb_sel_pc4 <= WB_SEL_ALU; -- Default to ALU result
        o_is_jump <= '0';

        CASE i_opcode IS
            WHEN OPCODE_LUI =>
                o_reg_write_enable <= '1';
                o_alu_sel_b <= ALU_B_IMM;
                o_wb_sel_pc4 <= WB_SEL_ALU; -- Result comes from ALU path

            WHEN OPCODE_AUIPC =>
                o_reg_write_enable <= '1';
                o_alu_sel_b <= ALU_B_IMM;
                o_wb_sel_pc4 <= WB_SEL_ALU;

            WHEN OPCODE_JAL =>
                o_reg_write_enable <= '1';
                o_wb_sel_pc4 <= WB_SEL_PC4; -- Write PC+4 (link address)
                o_is_jump <= '1'; -- Unconditional jump signal
                o_branch_taken <= '1'; -- Tell Fetch stage to take the calculated jump target

            WHEN OPCODE_JALR =>
                o_reg_write_enable <= '1';
                o_alu_sel_b <= ALU_B_IMM; -- Add RegA + Immediate for target address
                o_wb_sel_pc4 <= WB_SEL_PC4; -- Write PC+4 (link address)
                o_is_jump <= '1'; -- Unconditional jump signal
                o_branch_taken <= '1'; -- Tell Fetch stage to take the calculated jump target

            WHEN OPCODE_BRANCH =>
                -- No register write for branches
                o_alu_sel_b <= ALU_B_REG; -- Comparison uses RegA and RegB
                o_branch_taken <= branch_condition_met; -- Use pre-calculated condition

                -- case OPCODE_LOAD removed
                -- case OPCODE_STORE removed

            WHEN OPCODE_IMM => -- I-Type ALU
                o_reg_write_enable <= '1';
                o_alu_sel_b <= ALU_B_IMM; -- Use Immediate
                o_wb_sel_pc4 <= WB_SEL_ALU;

            WHEN OPCODE_REG => -- R-Type ALU
                o_reg_write_enable <= '1';
                o_alu_sel_b <= ALU_B_REG; -- Use Register B
                o_wb_sel_pc4 <= WB_SEL_ALU;

            WHEN OTHERS =>
                -- Undefined or unsupported opcode (or Load/Store treated as NOP)
                -- Keep defaults (effectively a NOP)
                NULL;

        END CASE;
    END PROCESS control_decode_proc;

END ARCHITECTURE behavioral;