LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ALU IS
    GENERIC (
        ALU_DATA_WIDTH   : INTEGER := 32;
        ALU_FUNCT3_WIDTH : INTEGER := 3;
        ALU_FUNCT7_WIDTH : INTEGER := 7
    );
    PORT (
        alu_input_a : IN  UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0); -- Operand A (from regfile/PC)
        alu_input_b : IN  UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0); -- Operand B (from mux: regfile/imm)
        alu_funct3  : IN  UNSIGNED(ALU_FUNCT3_WIDTH - 1 DOWNTO 0); -- funct3 field
        alu_funct7  : IN  UNSIGNED(ALU_FUNCT7_WIDTH - 1 DOWNTO 0); -- funct7 field (bit 5 matters most here)

        alu_output  : OUT UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0); -- Result of ALU operation
        zero_flag   : OUT STD_LOGIC                              -- '1' if alu_output is zero
    );
END ENTITY ALU;

ARCHITECTURE rtl OF ALU IS
    SIGNAL alu_result_comb : UNSIGNED(ALU_DATA_WIDTH - 1 DOWNTO 0);
BEGIN

    alu_logic_proc : PROCESS(alu_input_a, alu_input_b, alu_funct3, alu_funct7)
        VARIABLE slt_result           : BOOLEAN; -- For SLT/SLTU comparisons
        VARIABLE current_shift_amount : NATURAL range 0 to 2**5 - 1;
    BEGIN
        current_shift_amount := to_integer(alu_input_b(4 DOWNTO 0));

        alu_result_comb <= (OTHERS => '0');

        CASE alu_funct3 IS
            WHEN "000" => -- ADD / SUB (determined by funct7 bit 5)
                IF alu_funct7(5) = '0' THEN -- ADD
                    alu_result_comb <= alu_input_a + alu_input_b;
                ELSE -- SUB ('1')
                    alu_result_comb <= alu_input_a - alu_input_b;
                END IF;

            WHEN "001" => -- SLL (Shift Left Logical)
                alu_result_comb <= shift_left(alu_input_a, current_shift_amount);

            WHEN "010" => -- SLT (Set Less Than, Signed)
                slt_result := signed(alu_input_a) < signed(alu_input_b);
                IF slt_result THEN
                    alu_result_comb <= to_unsigned(1, ALU_DATA_WIDTH);
                ELSE
                    alu_result_comb <= (OTHERS => '0');
                END IF;

            WHEN "011" => -- SLTU (Set Less Than, Unsigned)
                slt_result := alu_input_a < alu_input_b;
                IF slt_result THEN
                    alu_result_comb <= to_unsigned(1, ALU_DATA_WIDTH);
                ELSE
                    alu_result_comb <= (OTHERS => '0');
                END IF;

            WHEN "100" => -- XOR
                alu_result_comb <= alu_input_a XOR alu_input_b;

            WHEN "101" => -- SRL / SRA (Shift Right Logical/Arithmetic, determined by funct7 bit 5)
                IF alu_funct7(5) = '0' THEN -- SRL (Logical)
                    alu_result_comb <= shift_right(alu_input_a, current_shift_amount);
                ELSE -- SRA (Arithmetic) ('1')
                    alu_result_comb <= unsigned(shift_right(signed(alu_input_a), current_shift_amount));
                END IF;

            WHEN "110" => -- OR
                alu_result_comb <= alu_input_a OR alu_input_b;

            WHEN "111" => -- AND
                alu_result_comb <= alu_input_a AND alu_input_b;

            WHEN OTHERS =>
                alu_result_comb <= (OTHERS => 'X');
        END CASE;
    END PROCESS alu_logic_proc;
    alu_output <= alu_result_comb;
    zero_flag <= '1' WHEN alu_result_comb = (alu_result_comb'RANGE => '0') ELSE '0';
END ARCHITECTURE rtl;