LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY instruction_decoder IS
  PORT (
    i_instruction : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_opcode : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_funct3 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_funct7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    o_source1 : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_source2 : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_dest : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    o_immediate : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END ENTITY instruction_decoder;

ARCHITECTURE rtl OF instruction_decoder IS
  SIGNAL opcode : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN

  opcode <= i_instruction(6 DOWNTO 0);
  o_opcode <= opcode;

  decoder_proc : PROCESS (opcode, i_instruction)
  BEGIN
    o_funct3 <= "000";
    o_funct7 <= "0000000";
    o_source1 <= "00000";
    o_source2 <= "00000";
    o_dest <= "00000";
    o_immediate <= (OTHERS => '0');

    CASE opcode IS
        -- U-type: LUI, AUIPC
      WHEN "0110111" | "0010111" =>
        o_dest <= i_instruction(11 DOWNTO 7);
        o_immediate <= i_instruction(31 DOWNTO 12) & X"000";

        -- J-type: JAL
      WHEN "1101111" =>
        o_dest <= i_instruction(11 DOWNTO 7);
        o_immediate <= (31 DOWNTO 21 => i_instruction(31)) &
          i_instruction(31) &
          i_instruction(19 DOWNTO 12) &
          i_instruction(20) &
          i_instruction(30 DOWNTO 21) &
          '0';

        -- I-type: JALR, Loads, System
      WHEN "1100111" | "0000011" | "1110011" =>
        o_funct3 <= i_instruction(14 DOWNTO 12);
        o_source1 <= i_instruction(19 DOWNTO 15);
        o_dest <= i_instruction(11 DOWNTO 7);
        o_immediate <= (31 DOWNTO 12 => i_instruction(31)) & i_instruction(31 DOWNTO 20);

        -- B-type: Branches
      WHEN "1100011" =>
        o_funct3 <= i_instruction(14 DOWNTO 12);
        o_source1 <= i_instruction(19 DOWNTO 15);
        o_source2 <= i_instruction(24 DOWNTO 20);
        o_immediate <= (31 DOWNTO 13 => i_instruction(31)) &
          i_instruction(31) &
          i_instruction(7) &
          i_instruction(30 DOWNTO 25) &
          i_instruction(11 DOWNTO 8) &
          '0';

        -- S-type: Stores
      WHEN "0100011" =>
        o_funct3 <= i_instruction(14 DOWNTO 12);
        o_source1 <= i_instruction(19 DOWNTO 15);
        o_source2 <= i_instruction(24 DOWNTO 20);
        o_immediate <= (31 DOWNTO 12 => i_instruction(31)) &
          i_instruction(31 DOWNTO 25) &
          i_instruction(11 DOWNTO 7);

        -- I-type: Integer Immediate (incl. SLLI, SRLI, SRAI)
      WHEN "0010011" =>
        o_funct3 <= i_instruction(14 DOWNTO 12);
        o_funct7 <= i_instruction(31 DOWNTO 25);
        o_source1 <= i_instruction(19 DOWNTO 15);
        o_dest <= i_instruction(11 DOWNTO 7);
        o_immediate <= (31 DOWNTO 12 => i_instruction(31)) & i_instruction(31 DOWNTO 20);

        -- R-type: Integer Register-Register
      WHEN "0110011" =>
        o_funct3 <= i_instruction(14 DOWNTO 12);
        o_funct7 <= i_instruction(31 DOWNTO 25);
        o_source1 <= i_instruction(19 DOWNTO 15);
        o_source2 <= i_instruction(24 DOWNTO 20);
        o_dest <= i_instruction(11 DOWNTO 7);
        -- o_immediate keeps default

      WHEN OTHERS =>
        NULL;

    END CASE;
  END PROCESS decoder_proc;

END ARCHITECTURE rtl;