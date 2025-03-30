LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY execute_tb IS
END ENTITY execute_tb;

ARCHITECTURE behavior OF execute_tb IS

    -- Constants matching the Generic parameters of the DUT
    CONSTANT G_DW : INTEGER := 32;
    CONSTANT G_F3W : INTEGER := 3;
    CONSTANT G_F7W : INTEGER := 7;
    CONSTANT G_SW : INTEGER := 1;

    -- Component declaration for the Unit Under Test (UUT)
    COMPONENT execute IS
        GENERIC (
            DW : INTEGER := G_DW; -- Data width
            F3W : INTEGER := G_F3W; -- Funct3 width
            F7W : INTEGER := G_F7W; -- Funct7 width
            SW : INTEGER := G_SW -- Select width (for alu_sel_b)
        );
        PORT (
            -- Control Inputs
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            alu_sel_b : IN UNSIGNED(SW - 1 DOWNTO 0);
            funct3 : IN UNSIGNED(F3W - 1 DOWNTO 0);
            funct7 : IN UNSIGNED(F7W - 1 DOWNTO 0);
            -- Data Inputs
            pc : IN UNSIGNED(DW - 1 DOWNTO 0);
            reg_a : IN UNSIGNED(DW - 1 DOWNTO 0);
            reg_b : IN UNSIGNED(DW - 1 DOWNTO 0);
            imm : IN UNSIGNED(DW - 1 DOWNTO 0);
            -- Data Outputs
            alu_out : OUT UNSIGNED(DW - 1 DOWNTO 0);
            writedata : OUT UNSIGNED(DW - 1 DOWNTO 0);
            pc_branch : OUT UNSIGNED(DW - 1 DOWNTO 0);
            link_address : OUT UNSIGNED(DW - 1 DOWNTO 0);
            -- Status Outputs
            zero_flag : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Testbench signals
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0'; -- Clock (optional if DUT purely combinational)
    SIGNAL sim_done : BOOLEAN := FALSE;
    SIGNAL tb_alu_sel_b : UNSIGNED(G_SW - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_funct3 : UNSIGNED(G_F3W - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_funct7 : UNSIGNED(G_F7W - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_pc : UNSIGNED(G_DW - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_reg_a : UNSIGNED(G_DW - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_reg_b : UNSIGNED(G_DW - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_imm : UNSIGNED(G_DW - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_alu_out : UNSIGNED(G_DW - 1 DOWNTO 0);
    SIGNAL tb_writedata : UNSIGNED(G_DW - 1 DOWNTO 0);
    SIGNAL tb_pc_branch : UNSIGNED(G_DW - 1 DOWNTO 0);
    SIGNAL tb_link_address : UNSIGNED(G_DW - 1 DOWNTO 0);
    SIGNAL tb_zero_flag : STD_LOGIC;

    -- Clock period definition
    CONSTANT clk_period : TIME := 10 ns;

BEGIN

    uut : ENTITY work.execute
        GENERIC MAP(
            DW => G_DW,
            F3W => G_F3W,
            F7W => G_F7W,
            SW => G_SW
        )
        PORT MAP(
            alu_sel_b => tb_alu_sel_b,
            funct3 => tb_funct3,
            funct7 => tb_funct7,
            pc => tb_pc,
            reg_a => tb_reg_a,
            reg_b => tb_reg_b,
            imm => tb_imm,
            alu_out => tb_alu_out,
            writedata => tb_writedata,
            pc_branch => tb_pc_branch,
            link_address => tb_link_address,
            zero_flag => tb_zero_flag
        );

    clk_proc : PROCESS
    BEGIN
        WHILE NOT sim_done LOOP
            tb_clk <= '0';
            WAIT FOR clk_period / 2;
            IF sim_done THEN
                EXIT;
            END IF;
            tb_clk <= '1';
            WAIT FOR clk_period / 2;
        END LOOP;
        WAIT;
    END PROCESS clk_proc;

    stim_proc : PROCESS
        VARIABLE expected_alu : UNSIGNED(G_DW - 1 DOWNTO 0);
        VARIABLE expected_branch : UNSIGNED(G_DW - 1 DOWNTO 0);
        VARIABLE expected_link : UNSIGNED(G_DW - 1 DOWNTO 0);
        VARIABLE expected_write : UNSIGNED(G_DW - 1 DOWNTO 0);
        VARIABLE expected_zero : STD_LOGIC;
    BEGIN
        -- Apply reset
        REPORT "Starting simulation, applying reset." SEVERITY NOTE;
        tb_rst <= '1';
        WAIT FOR clk_period * 1.5; -- Hold reset for > 1 clock cycle
        tb_rst <= '0';
        WAIT FOR clk_period; -- Wait for reset to de-assert

        -- Test Case 1: R-type ADD (reg_a + reg_b)
        REPORT "Test Case 1: R-type ADD" SEVERITY NOTE;
        tb_pc <= to_unsigned(100, G_DW);
        tb_reg_a <= to_unsigned(15, G_DW);
        tb_reg_b <= to_unsigned(27, G_DW);
        tb_imm <= to_unsigned(8, G_DW); -- Example immediate for branch calc
        tb_alu_sel_b <= "0"; -- Select reg_b
        tb_funct3 <= "000";
        tb_funct7 <= "0000000"; -- funct7[5]=0 for ADD

        WAIT FOR clk_period; -- Wait for combinational logic to settle

        expected_alu := to_unsigned(42, G_DW); -- 15 + 27
        expected_branch := to_unsigned(108, G_DW); -- 100 + 8
        expected_link := to_unsigned(104, G_DW); -- 100 + 4
        expected_write := tb_reg_b; -- Should be reg_b
        expected_zero := '0';

        ASSERT tb_alu_out = expected_alu
        REPORT "TC1 ADD: ALU output mismatch. Expected " & INTEGER'image(to_integer(expected_alu)) & ", Got " & INTEGER'image(to_integer(tb_alu_out)) SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC1 ADD: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC1 ADD: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC1 ADD: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC1 ADD: Zero flag mismatch." SEVERITY ERROR;

        -- Test Case 2: I-type ADDI (reg_a + imm)
        REPORT "Test Case 2: I-type ADDI" SEVERITY NOTE;
        tb_pc <= to_unsigned(200, G_DW);
        tb_reg_a <= to_unsigned(50, G_DW);
        tb_reg_b <= to_unsigned(999, G_DW); -- Value for writedata check
        tb_imm <= to_unsigned(25, G_DW);
        tb_alu_sel_b <= "1"; -- Select immediate
        tb_funct3 <= "000";
        tb_funct7 <= "0000000"; -- Not strictly needed for ADDI

        WAIT FOR clk_period;

        expected_alu := to_unsigned(75, G_DW); -- 50 + 25
        expected_branch := to_unsigned(225, G_DW); -- 200 + 25
        expected_link := to_unsigned(204, G_DW); -- 200 + 4
        expected_write := tb_reg_b; -- Should still be reg_b
        expected_zero := '0';

        ASSERT tb_alu_out = expected_alu
        REPORT "TC2 ADDI: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC2 ADDI: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC2 ADDI: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC2 ADDI: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC2 ADDI: Zero flag mismatch." SEVERITY ERROR;
        -- Test Case 3: R-type SUB (reg_a - reg_b), Result Zero
        REPORT "Test Case 3: R-type SUB (Zero Result)" SEVERITY NOTE;
        tb_pc <= to_unsigned(300, G_DW);
        tb_reg_a <= to_unsigned(30, G_DW);
        tb_reg_b <= to_unsigned(30, G_DW);
        tb_imm <= unsigned(to_signed(-12, G_DW)); -- Negative immediate for branch calc
        tb_alu_sel_b <= "0"; -- Select reg_b
        tb_funct3 <= "000";
        tb_funct7 <= "0100000"; -- funct7[5]=1 for SUB

        WAIT FOR clk_period;

        expected_alu := to_unsigned(0, G_DW); -- 30 - 30
        expected_branch := to_unsigned(288, G_DW); -- 300 + (-12)
        expected_link := to_unsigned(304, G_DW); -- 300 + 4
        expected_write := tb_reg_b;
        expected_zero := '1'; -- Expect zero flag

        ASSERT tb_alu_out = expected_alu
        REPORT "TC3 SUB Zero: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC3 SUB Zero: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC3 SUB Zero: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC3 SUB Zero: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC3 SUB Zero: Zero flag mismatch. Expected 1." SEVERITY ERROR;
        -- Test Case 4: I-type SLLI (Shift Left Logical Immediate)
        REPORT "Test Case 4: I-type SLLI" SEVERITY NOTE;
        tb_pc <= to_unsigned(400, G_DW);
        tb_reg_a <= to_unsigned(7, G_DW); -- 0...0111
        tb_reg_b <= to_unsigned(111, G_DW); -- For writedata check
        -- Immediate for SLLI encodes shift amount in lower 5 bits (RISC-V spec)
        -- Let's shift by 3. Immediate = 0...00011
        tb_imm <= to_unsigned(3, G_DW);
        tb_alu_sel_b <= "1"; -- Select immediate (although ALU uses only lower bits of imm for shift amount)
        tb_funct3 <= "001"; -- SLL/SLLI
        tb_funct7 <= "0000000"; -- Not used for SLLI variant

        WAIT FOR clk_period;

        expected_alu := to_unsigned(56, G_DW); -- 7 << 3 (0...0111000)
        expected_branch := to_unsigned(403, G_DW); -- 400 + 3
        expected_link := to_unsigned(404, G_DW); -- 400 + 4
        expected_write := tb_reg_b;
        expected_zero := '0';

        ASSERT tb_alu_out = expected_alu
        REPORT "TC4 SLLI: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC4 SLLI: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC4 SLLI: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC4 SLLI: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC4 SLLI: Zero flag mismatch." SEVERITY ERROR;

        -- Test Case 5: R-type SLT (Set Less Than, Signed)
        REPORT "Test Case 5: R-type SLT (Signed)" SEVERITY NOTE;
        tb_pc <= to_unsigned(500, G_DW);
        tb_reg_a <= unsigned(to_signed(-5, G_DW)); -- Reg A is negative
        tb_reg_b <= to_unsigned(10, G_DW); -- Reg B is positive
        tb_imm <= to_unsigned(100, G_DW);
        tb_alu_sel_b <= "0"; -- Select reg_b
        tb_funct3 <= "010"; -- SLT
        tb_funct7 <= "0000000"; -- Default funct7

        WAIT FOR clk_period;

        expected_alu := to_unsigned(1, G_DW); -- -5 < 10 is true
        expected_branch := to_unsigned(600, G_DW); -- 500 + 100
        expected_link := to_unsigned(504, G_DW); -- 500 + 4
        expected_write := tb_reg_b;
        expected_zero := '0'; -- Result is 1, not 0

        ASSERT tb_alu_out = expected_alu
        REPORT "TC5 SLT: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC5 SLT: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC5 SLT: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC5 SLT: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC5 SLT: Zero flag mismatch." SEVERITY ERROR;

        -- Test Case 6: I-type SLTIU (Set Less Than Immediate Unsigned)
        REPORT "Test Case 6: I-type SLTIU (Unsigned)" SEVERITY NOTE;
        tb_pc <= to_unsigned(600, G_DW);
        tb_reg_a <= to_unsigned(20, G_DW);
        tb_reg_b <= to_unsigned(1, G_DW); -- For writedata check
        tb_imm <= to_unsigned(10, G_DW); -- Immediate to compare against
        tb_alu_sel_b <= "1"; -- Select immediate
        tb_funct3 <= "011"; -- SLTIU
        tb_funct7 <= "0000000"; -- Not used

        WAIT FOR clk_period;

        expected_alu := to_unsigned(0, G_DW); -- 20 < 10 (unsigned) is false
        expected_branch := to_unsigned(610, G_DW); -- 600 + 10
        expected_link := to_unsigned(604, G_DW); -- 600 + 4
        expected_write := tb_reg_b;
        expected_zero := '1'; -- Result is 0, so zero flag is set

        ASSERT tb_alu_out = expected_alu
        REPORT "TC6 SLTIU: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC6 SLTIU: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC6 SLTIU: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC6 SLTIU: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC6 SLTIU: Zero flag mismatch. Expected 1." SEVERITY ERROR;

        -- Add more test cases here for XOR, SRL, SRA, OR, AND (R-type and I-type)
        -- Example: R-type AND
        REPORT "Test Case 7: R-type AND" SEVERITY NOTE;
        tb_pc <= to_unsigned(700, G_DW);
        tb_reg_a <= X"0000_FF0F";
        tb_reg_b <= X"0000_FFFF";
        tb_imm <= to_unsigned(0, G_DW);
        tb_alu_sel_b <= "0"; -- Select reg_b
        tb_funct3 <= "111"; -- AND
        tb_funct7 <= "0000000";

        WAIT FOR clk_period;

        expected_alu := X"0000_FF0F";
        expected_branch := to_unsigned(700, G_DW);
        expected_link := to_unsigned(704, G_DW);
        expected_write := tb_reg_b;
        expected_zero := '0';

        ASSERT tb_alu_out = expected_alu
        REPORT "TC7 AND: ALU output mismatch." SEVERITY ERROR;
        ASSERT tb_pc_branch = expected_branch
        REPORT "TC7 AND: Branch PC mismatch." SEVERITY ERROR;
        ASSERT tb_link_address = expected_link
        REPORT "TC7 AND: Link Address mismatch." SEVERITY ERROR;
        ASSERT tb_writedata = expected_write
        REPORT "TC7 AND: Write Data mismatch." SEVERITY ERROR;
        ASSERT tb_zero_flag = expected_zero
        REPORT "TC7 AND: Zero flag mismatch." SEVERITY ERROR;

        -- End simulation
        REPORT "Simulation completed." SEVERITY NOTE;
        sim_done <= TRUE;
        WAIT;

    END PROCESS stim_proc;

END ARCHITECTURE behavior;