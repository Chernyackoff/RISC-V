LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Execute_stage_TB IS
    GENERIC(
        DATA_WIDTH: INTEGER := 32;-- Data lines amount
        FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
        FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
        SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
END ENTITY Execute_stage_TB;

ARCHITECTURE RTL OF Execute_stage_TB IS


    COMPONENT Execute_stage is
        GENERIC(
            DATA_WIDTH: INTEGER := 32;-- Data lines amount
            FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
            FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
            SEL_WIDTH: INTEGER := 1 --! select signal lines amount
        );
        PORT(
            rst    : IN STD_LOGIC := '0';--! sync active high reset. sync -> refclk
            clk    : IN STD_LOGIC := '0';--! input clock signal
            IN_REG_A : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal, A operand for ALU
            IN_REG_B : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal , B operand for ALU (switch by multiplexer)
            IN_IMM : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input data signal , B operand for ALU (switch by multiplexer)
            ALU_RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU out
            --WRITEDATA : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
            FUNCT3 : IN UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operation signal FUNCT3
            FUNCT7 : IN UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operation signal FUNCT7
            ALU_SEL_B : IN UNSIGNED(SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- ALU operand B multiplexer selection signal
            ZERO_FLAG : OUT STD_LOGIC := '0'; -- zero result sign
            PC_PLUS_4 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- input PC + 4 value
            PC_BRANCH : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0') -- modified for branch PC value 
    
        );
    END COMPONENT;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
    SIGNAL a : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"000000AA";
    SIGNAL b1 : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"000000FF";
    SIGNAL b2 : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"00000000";
    SIGNAL result : unsigned(DATA_WIDTH - 1 DOWNTO 0) := x"000000FF";
    SIGNAL funct3 : unsigned(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL funct7 : unsigned(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL sel : unsigned(SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL a1 : signed (DATA_WIDTH - 1 DOWNTO 0) := x"FFFFFFF9";
    SIGNAL pc_plus_4 : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_branch : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL zero : STD_LOGIC := '1';
    signal test_completed: boolean := false;
BEGIN

    ex_inst: Execute_stage
        GENERIC MAP (
            DATA_WIDTH => DATA_WIDTH,
            FUNCT3_WIDTH => FUNCT3_WIDTH,
            FUNCT7_WIDTH => FUNCT7_WIDTH,
            SEL_WIDTH => SEL_WIDTH
        )
        PORT MAP (
            rst => rst,
            clk => clk,
            IN_REG_A => a,
            IN_REG_B => b1,
            IN_IMM => b2,
            ALU_RESULT => result,
            FUNCT3 => funct3,
            FUNCT7 => funct7,
            ALU_SEL_B => sel,
            PC_PLUS_4 => pc_plus_4,
            PC_BRANCH => pc_branch,
            ZERO_FLAG => zero
        );
    
    clk_gen: process is
        begin
            loop
                clk <= not clk;
                wait for 5 us;
            end loop;
        end process clk_gen;
    
        main : process
        begin
            rst <= '0';
            wait for 20 us;
            sel <= "0";
            -- ALU test
            for k in 0 to 8 loop
                if(k = 1) then
                    funct7(funct7'length - 2) <= '1';
                    funct3 <= to_unsigned(0, funct3'length); -- add operation
                elsif (k = 0) then
                    funct7(funct7'length - 2) <= '0';
                    funct3 <= to_unsigned(k, funct3'length); -- add operation
                else
                    funct7(funct7'length - 2) <= '0';
                    funct3 <= to_unsigned(k - 1, funct3'length); -- add operation
                end if;
                wait for 20 us;
                for i in 0 to 5 loop
                    a <= to_unsigned(i, a'length); -- all values of the first operator
                    --wait for 20 us;
                    for j in 0 to 5 loop
                        b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                        wait for 20 us;
                    end loop;
                end loop;
                b1 <= to_unsigned(0, b1'length); 
                wait for 20 us;
            end loop;
            -- branch test
            pc_plus_4(0) <= '1';
            b2(0) <= '1'; 
            wait for 20 us;

            test_completed <= true after 15 us;
            wait;
        end process main;
END ARCHITECTURE;