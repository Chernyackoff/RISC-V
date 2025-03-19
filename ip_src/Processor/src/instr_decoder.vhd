LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY instr_decoder IS
  PORT (
    refclk        : IN STD_LOGIC;--! reference clock expect 250Mhz
    rst           : IN STD_LOGIC;
    i_instruction : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

    o_opcode    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_funct3    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_funct7    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_source1   : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_source2   : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_dest      : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_immediate : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)

  );
END ENTITY instr_decoder;

ARCHITECTURE rtl OF instr_decoder IS

BEGIN
  -- TODO: Add FENCE instruction decoding 
  decoder : PROCESS (refclk)
  BEGIN
    IF (rising_edge(refclk))
      IF (rst = '0') THEN
        o_opcode <= i_instruction(6 DOWNTO 0);
        CASE (i_instruction(6 DOWNTO 0))
            -- U-type: lui and auipc
          WHEN "0110111" | "0010111" =>
            o_funct3                  <= X"00000000";
            o_funct7                  <= X"00000000";
            o_source1                 <= X"00000000";
            o_source2                 <= X"00000000";
            o_dest                    <= i_instruction(7 DOWNTO 11);
            o_immediate(31 DOWNTO 12) <= i_instruction(31 DOWNTO 12);
            o_immediate(11 DOWNTO 0)  <= X"000";

            -- J-type: jal  
          WHEN "1101111" =>
            o_funct3                  <= X"00000000";
            o_funct7                  <= X"00000000";
            o_source1                 <= X"00000000";
            o_source2                 <= X"00000000";
            o_dest                    <= i_instruction(7 DOWNTO 11);
            o_immediate(20)           <= i_instruction(31);
            o_immediate(10 DOWNTO 1)  <= i_instruction(30 DOWNTO 21);
            o_immediate(11)           <= i_instruction(20);
            o_immediate(19 DOWNTO 12) <= i_instruction(19 DOWNTO 12);

            --I-type: jalr, LB, LH, LW, LBU, LHU, ECALL, EBREAK
          WHEN "1100111" | "0000011" | "1110011" =>
            o_funct3                  <= i_instruction(14 DOWNTO 12);
            o_funct7                  <= X"00000000";
            o_source1                 <= i_instruction(19 DOWNTO 15);
            o_source2                 <= X"00000000";
            o_dest                    <= i_instruction(7 DOWNTO 11);
            o_immediate(11 DOWNTO 0)  <= i_instruction(31 DOWNTO 20);
            o_immediate(31 DOWNTO 12) <= X"00000";

            -- B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
          WHEN "1100011" =>
            o_funct3  <= i_instruction(14 DOWNTO 12);
            o_funct7  <= X"00000000";
            o_source1 <= i_instruction(19 DOWNTO 15);
            o_source2 <= i_instruction(24 DOWNTO 20);
            o_dest    <= X"00000000";

            o_immediate(11)          <= i_instruction(7);
            o_immediate(4 DOWNTO 1)  <= i_instruction(11 DOWNTO 8);
            o_immediate(10 DOWNTO 5) <= i_instruction(30 DOWNTO 25);
            o_immediate(12)          <= i_instruction(31);

            -- S-type : SB, SH, SW
          WHEN "0100011" =>
            o_funct3  <= i_instruction(14 DOWNTO 12);
            o_funct7  <= X"00000000";
            o_source1 <= i_instruction(19 DOWNTO 15);
            o_source2 <= i_instruction(24 DOWNTO 20);
            o_dest    <= X"00000000";

            o_immediate(4 DOWNTO 0)  <= i_instruction(11 DOWNTO 7);
            o_immediate(11 DOWNTO 5) <= i_instruction(31 DOWNTO 25);

            -- I- or R-type (funct3 dependent):  
          WHEN "0010011" =>
            o_funct3 <= i_instruction(14 DOWNTO 12);

            funct3 : CASE (i_instruction(14 DOWNTO 12))
              WHEN "001" | "101" => -- R-type : SLLI, SRLI, SRAI
                o_funct7    <= i_instruction(31 DOWNTO 25);
                o_source1   <= i_instruction(19 DOWNTO 15);
                o_source2   <= i_instruction(24 DOWNTO 20);
                o_dest      <= i_instruction(11 DOWNTO 7);
                o_immediate <= X"00000000";

              WHEN OTHERS => -- I-type : ADDI, SLTI, SLTIU, XORI, ORI, ANDI
                o_funct7                  <= X"00000000";
                o_source1                 <= i_instruction(19 DOWNTO 15);
                o_source2                 <= X"00000000";
                o_dest                    <= i_instruction(7 DOWNTO 11);
                o_immediate(11 DOWNTO 0)  <= i_instruction(31 DOWNTO 20);
                o_immediate(31 DOWNTO 12) <= X"00000";
            END CASE funct3;

            -- R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND 
          WHEN "0110011" =>
            o_funct3    <= i_instruction(14 DOWNTO 12);
            o_funct7    <= i_instruction(31 DOWNTO 25);
            o_source1   <= i_instruction(19 DOWNTO 15);
            o_source2   <= i_instruction(24 DOWNTO 20);
            o_dest      <= i_instruction(11 DOWNTO 7);
            o_immediate <= X"00000000";

          WHEN OTHERS =>
            o_funct3    <= "000";
            o_funct7    <= "0000000";
            o_source1   <= "00000";
            o_source2   <= "00000";
            o_dest      <= "00000";
            o_immediate <= X"00000000";
        END CASE;
      ELSE
        o_funct3    <= "000";
        o_funct7    <= "0000000";
        o_source1   <= "00000";
        o_source2   <= "00000";
        o_dest      <= "00000";
        o_immediate <= X"00000000";
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE rtl;
