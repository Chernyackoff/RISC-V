LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ALU_tb IS
END ENTITY ALU_tb;

ARCHITECTURE behavior OF ALU_tb IS
    COMPONENT ALU
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

    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT FUNCT3_WIDTH : INTEGER := 3;
    CONSTANT FUNCT7_WIDTH : INTEGER := 7;

    SIGNAL tb_input_a : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_input_b : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_funct3 : UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_funct7 : UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_output : UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL tb_zero : STD_LOGIC;

    -- Clock period definition (not used directly since ALU is combinational)
    CONSTANT clk_period : TIME := 10 ns;

BEGIN
    uut : ALU
    GENERIC MAP(
        ALU_DATA_WIDTH => DATA_WIDTH,
        ALU_FUNCT3_WIDTH => FUNCT3_WIDTH,
        ALU_FUNCT7_WIDTH => FUNCT7_WIDTH
    )
    PORT MAP(
        alu_input_a => tb_input_a,
        alu_input_b => tb_input_b,
        alu_funct3 => tb_funct3,
        alu_funct7 => tb_funct7,
        alu_output => tb_output,
        zero_flag => tb_zero
    );

    stim_proc : PROCESS
    BEGIN
        -- Wait for initial stabilization
        WAIT FOR clk_period;

        -- Test ADD (funct3 = 000, funct7[5] = 0)
        tb_input_a <= to_unsigned(15, DATA_WIDTH);
        tb_input_b <= to_unsigned(27, DATA_WIDTH);
        tb_funct3 <= "000";
        tb_funct7 <= "0000000";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(42, DATA_WIDTH)
        REPORT "ADD failed" SEVERITY ERROR;

        -- Test SUB (funct3 = 000, funct7[5] = 1)
        tb_input_a <= to_unsigned(50, DATA_WIDTH);
        tb_input_b <= to_unsigned(30, DATA_WIDTH);
        tb_funct7 <= "0100000";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(20, DATA_WIDTH)
        REPORT "SUB failed" SEVERITY ERROR;

        -- Test SLL (funct3 = 001)
        tb_input_a <= to_unsigned(5, DATA_WIDTH);
        tb_input_b <= to_unsigned(2, DATA_WIDTH);
        tb_funct3 <= "001";
        tb_funct7 <= "0000000";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(20, DATA_WIDTH)
        REPORT "SLL failed" SEVERITY ERROR;

        -- Test SLT (funct3 = 010)
        tb_input_a <= to_unsigned(5, DATA_WIDTH);
        tb_input_b <= to_unsigned(10, DATA_WIDTH);
        tb_funct3 <= "010";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(1, DATA_WIDTH)
        REPORT "SLT failed" SEVERITY ERROR;

        -- Test SLTU (funct3 = 011)
        tb_input_a <= to_unsigned(10, DATA_WIDTH);
        tb_input_b <= to_unsigned(5, DATA_WIDTH);
        tb_funct3 <= "011";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(0, DATA_WIDTH)
        REPORT "SLTU failed" SEVERITY ERROR;

        -- Test XOR (funct3 = 100)
        tb_input_a <= to_unsigned(13, DATA_WIDTH); -- 1101
        tb_input_b <= to_unsigned(6, DATA_WIDTH); -- 0110
        tb_funct3 <= "100";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(11, DATA_WIDTH) -- 1011
        REPORT "XOR failed" SEVERITY ERROR;

        -- Test SRL (funct3 = 101, funct7[5] = 0)
        tb_input_a <= to_unsigned(16, DATA_WIDTH);
        tb_input_b <= to_unsigned(2, DATA_WIDTH);
        tb_funct3 <= "101";
        tb_funct7 <= "0000000";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(4, DATA_WIDTH)
        REPORT "SRL failed" SEVERITY ERROR;

        -- Test SRA (funct3 = 101, funct7[5] = 1)
        tb_input_a <= unsigned(to_signed(-16, DATA_WIDTH));
        tb_input_b <= to_unsigned(2, DATA_WIDTH);
        tb_funct7 <= "0100000";
        WAIT FOR clk_period;
        ASSERT tb_output = unsigned(to_signed(-4, DATA_WIDTH))
        REPORT "SRA failed" SEVERITY ERROR;

        -- Test OR (funct3 = 110)
        tb_input_a <= to_unsigned(12, DATA_WIDTH); -- 1100
        tb_input_b <= to_unsigned(5, DATA_WIDTH); -- 0101
        tb_funct3 <= "110";
        tb_funct7 <= "0000000";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(13, DATA_WIDTH) -- 1101
        REPORT "OR failed" SEVERITY ERROR;

        -- Test AND (funct3 = 111)
        tb_input_a <= to_unsigned(12, DATA_WIDTH); -- 1100
        tb_input_b <= to_unsigned(5, DATA_WIDTH); -- 0101
        tb_funct3 <= "111";
        WAIT FOR clk_period;
        ASSERT tb_output = to_unsigned(4, DATA_WIDTH) -- 0100
        REPORT "AND failed" SEVERITY ERROR;

        -- Test zero flag
        tb_input_a <= to_unsigned(5, DATA_WIDTH);
        tb_input_b <= to_unsigned(5, DATA_WIDTH);
        tb_funct3 <= "000";
        tb_funct7 <= "0100000"; -- SUB
        WAIT FOR clk_period;
        ASSERT tb_zero = '1'
        REPORT "Zero flag failed" SEVERITY ERROR;

        -- End simulation
        REPORT "Simulation completed" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END ARCHITECTURE behavior;