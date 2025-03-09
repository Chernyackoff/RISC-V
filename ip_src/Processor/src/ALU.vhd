LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity ALU is
GENERIC (
    ALU_DATA_WIDTH: INTEGER := 32;-- Data lines amount
    ALU_FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
    ALU_FUNCT7_WIDTH: INTEGER := 7-- funct7 signal lines amount
);
PORT (
    rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
    clk    : IN STD_LOGIC;--! input clock signal
    alu_input_a : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! input from regfile
    alu_input_b : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! input from multiplexer
    alu_output : OUT unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! output
    alu_funct3 : IN unsigned(ALU_FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');--! input funct3 field from command
    alu_funct7 : IN unsigned(ALU_FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0')--! input funct7 field from command
);
END entity ALU;


architecture rtl of ALU is
    SIGNAL out_val : unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN
    main_proc : PROCESS(clk) is
    BEGIN
        if(rst = '0') then
            if(rising_edge(clk)) then
                case (alu_funct3) is
                    when "001" => out_val <= alu_input_a sll to_integer(alu_input_b); -- a << b
                    when "100" => out_val <= alu_input_a xor alu_input_b; -- a xor b
                    when "110" => out_val <= alu_input_a or alu_input_b; -- a or b
                    when "111" => out_val <= alu_input_a and alu_input_b; -- a and b
                    when others => out_val <= (OTHERS => '0');
                end case;
                if(alu_funct3 = "000") then
                    if(alu_funct7(ALU_FUNCT7_WIDTH - 2) = '0') then
                        out_val <= alu_input_a + alu_input_b; -- a + b
                    else
                        out_val <= alu_input_a - alu_input_b; -- a - b
                    end if;
                end if;
                if(alu_funct3 = "101") then
                    if(alu_funct7(ALU_FUNCT7_WIDTH - 2) = '0') then
                        out_val <= alu_input_a srl to_integer(alu_input_b); -- a >> b (logic)
                    else
                        out_val <= unsigned (to_stdlogicvector(to_bitvector(std_logic_vector(alu_input_a)) sra to_integer(alu_input_b))); -- a >> b (aritmetical)
                    end if;
                end if;
                if(alu_funct3 = "010") then -- Set 1 if b (immediate) > a. All parameter are signed
                    if(signed(alu_input_b) > signed(alu_input_a)) then
                        out_val <= to_unsigned(1, out_val'length);
                    else 
                        out_val <= to_unsigned(0, out_val'length);
                    end if;
                end if;
                if(alu_funct3 = "011") then -- Set 1 if b (immediate) > a. All parameter are unsigned
                    if(alu_input_b > alu_input_a) then
                        out_val <= to_unsigned(1, out_val'length);
                    else 
                        out_val <= to_unsigned(0, out_val'length);
                    end if;
                end if;
                alu_output <= out_val;
            end if;
        end if;
    end process main_proc;
END architecture rtl;