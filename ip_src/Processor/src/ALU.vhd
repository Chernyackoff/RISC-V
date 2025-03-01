LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity ALU is
GENERIC (
    ALU_DATA_WIDTH: INTEGER := 32;
    ALU_OPCODE_WIDTH: INTEGER := 3
);
PORT (
    rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
    alu_input_a : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    alu_input_b : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    alu_output : OUT unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    alu_opcode : IN unsigned(ALU_OPCODE_WIDTH - 1 DOWNTO 0) := (OTHERS => '0')
);
END entity ALU;


architecture rtl of ALU is
    SIGNAL out_val : unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN
main_proc : PROCESS(alu_opcode, alu_input_a, alu_input_b) is
BEGIN
    if(rst = '0') then
        case (alu_opcode) is
            when "000" => out_val <= alu_input_a + alu_input_b; -- a + b
            when "001" => out_val <= alu_input_a sll to_integer(alu_input_b); -- a << b
            when "100" => out_val <= alu_input_a xor alu_input_b; -- a xor b
            when "101" => out_val <= alu_input_a srl to_integer(alu_input_b); -- a >> b
            when "110" => out_val <= alu_input_a or alu_input_b; -- a or b
            when "111" => out_val <= alu_input_a and alu_input_b; -- a and b
            when others => out_val <= (OTHERS => '0');
        end case;
        if(alu_opcode = "010") then -- Set 1 if b (immediate) > a. All parameter are signed
            if(signed(alu_input_b) > signed(alu_input_a)) then
                out_val <= to_unsigned(1, out_val'length);
            else 
                out_val <= to_unsigned(0, out_val'length);
            end if;
        end if;
        if(alu_opcode = "011") then -- Set 1 if b (immediate) > a. All parameter are unsigned
            if(alu_input_b > alu_input_a) then
                out_val <= to_unsigned(1, out_val'length);
            else 
                out_val <= to_unsigned(0, out_val'length);
            end if;
        end if;
        alu_output <= out_val;
    end if;
end process main_proc;
END architecture rtl;