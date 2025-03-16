LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY Execute_stage_TB IS
    GENERIC(
        DATA_WIDTH: INTEGER := 32;-- Data lines amount
        FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
        FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
        MUL_SEL_WIDTH: INTEGER := 1 --! select signal lines amount
    );
END ENTITY Execute_stage_TB;

ARCHITECTURE RTL OF Execute_stage_TB IS


    COMPONENT Execute_stage is
        GENERIC(
            DATA_WIDTH: INTEGER := 32;-- Data lines amount
            FUNCT3_WIDTH: INTEGER := 3;-- funct3 signal lines amount
            FUNCT7_WIDTH: INTEGER := 7;-- funct7 signal lines amount
            MUL_SEL_WIDTH: INTEGER := 1 --! select signal lines amount
        );
        PORT(
            rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
            clk    : IN STD_LOGIC;--! input clock signal
            SRC_A : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
            SRC_B_1 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
            SRC_B_2 : IN UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
            ALU_RESULT : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
            --WRITEDATA : OUT UNSIGNED(DATA_WIDTH - 1 DOWNTO 0);
            FUNCT3 : IN UNSIGNED(FUNCT3_WIDTH - 1 DOWNTO 0);
            FUNCT7 : IN UNSIGNED(FUNCT7_WIDTH - 1 DOWNTO 0);
            MUL_SEL : IN UNSIGNED(MUL_SEL_WIDTH - 1 DOWNTO 0)
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
    SIGNAL sel : unsigned(MUL_SEL_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL a1 : signed (DATA_WIDTH - 1 DOWNTO 0) := x"FFFFFFF9";
    signal test_completed: boolean := false;
BEGIN

    ex_inst: Execute_stage
        GENERIC MAP (
            DATA_WIDTH => DATA_WIDTH,
            FUNCT3_WIDTH => FUNCT3_WIDTH,
            FUNCT7_WIDTH => FUNCT7_WIDTH,
            MUL_SEL_WIDTH => MUL_SEL_WIDTH
        )
        PORT MAP (
            rst => rst,
            clk => clk,
            SRC_A => a,
            SRC_B_1 => b1,
            SRC_B_2 => b2,
            ALU_RESULT => result,
            FUNCT3 => funct3,
            FUNCT7 => funct7,
            MUL_SEL => sel
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
            wait for 15 us;
            sel <= "0";
            funct7 <= (OTHERS => '0');
            funct3 <= "000"; -- add operation
            wait for 15 us;
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct7(funct7'length - 2) <= '1';
            funct3 <= "000"; -- sub operation
            wait for 15 us;
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct7 <= (OTHERS => '0');
            funct3 <= "001"; -- logical left shift 
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct3 <= "010"; -- Set 1 if b (immediate) > a. All parameter are signed
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct3 <= "011"; -- Set 1 if b (immediate) > a. All parameter are unsigned
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct3 <= "100"; -- xor
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct3 <= "101"; -- logical shift right
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct7(funct7'length - 2) <= '1';
            funct3 <= "101"; -- arithmetic shift right
            a <= unsigned(a1); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                wait for 15 us;
            end loop;
            wait for 15 us;
            funct7 <= (OTHERS => '0');
            funct3 <= "110"; -- or
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
    
            end loop;
            wait for 15 us;
            funct3 <= "111"; -- and
            for i in 0 to 5 loop
                a <= to_unsigned(i, a'length); -- all values of the first operator
                wait for 15 us;
                for j in 0 to 5 loop
                    b1 <= to_unsigned(j, b1'length); -- all values of the second operator
                    wait for 15 us;
                end loop;
            end loop;
            test_completed <= true after 15 us;
            wait;
        end process main;
END ARCHITECTURE;