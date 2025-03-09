
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity ALU_TB is
GENERIC (
    DATA_WIDTH : INTEGER := 32; --! Data lines amount
    FUNCT3_WIDTH: INTEGER := 3; --! funct3 signal lines amount
    FUNCT7_WIDTH: INTEGER := 7 --! funct7 signal lines amount
);
end entity ALU_TB;

architecture rtl of ALU_TB is
    component ALU is
    GENERIC (
        ALU_DATA_WIDTH: INTEGER := 32;--! Data lines amount
        ALU_FUNCT3_WIDTH: INTEGER := 3;--! funct3 signal lines amount
        ALU_FUNCT7_WIDTH: INTEGER := 7--! funct7 signal lines amount
    );
    PORT (
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        clk    : IN STD_LOGIC;--! input clock signal
        alu_input_a : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! input from regfile
        alu_input_b : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! input from multiplexer
        alu_output : OUT unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);--! output
        alu_funct3 : IN unsigned(ALU_FUNCT3_WIDTH - 1 DOWNTO 0);--! input funct3 field from command
        alu_funct7 : IN unsigned(ALU_FUNCT7_WIDTH - 1 DOWNTO 0)--! input funct7 field from command
    );
    END component;
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
    SIGNAL a : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL c : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL funct3 : unsigned(FUNCT3_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL funct7 : unsigned(FUNCT7_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL a1 : signed (DATA_WIDTH - 1 DOWNTO 0) := x"FFFFFFF9";
    signal test_completed: boolean := false;
begin

alu_inst: ALU 
GENERIC MAP (
    ALU_DATA_WIDTH => DATA_WIDTH,
    ALU_FUNCT3_WIDTH => FUNCT3_WIDTH
)
PORT MAP (
    rst => rst,
    clk => clk,
    alu_input_a => a,
    alu_input_b => b,
    alu_output => c,
    alu_funct3 => funct3,
    alu_funct7 => funct7
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
        funct7 <= (OTHERS => '0');
        funct3 <= "000"; -- add operation
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
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
                b <= to_unsigned(j, b'length); -- all values of the second operator
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
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct3 <= "010"; -- Set 1 if b (immediate) > a. All parameter are signed
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct3 <= "011"; -- Set 1 if b (immediate) > a. All parameter are unsigned
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct3 <= "100"; -- xor
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct3 <= "101"; -- logical shift right
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct7(funct7'length - 2) <= '1';
        funct3 <= "101"; -- arithmetic shift right
        a <= unsigned(a1); -- all values of the first operator
        wait for 15 us;
        for j in 0 to 5 loop
            b <= to_unsigned(j, b'length); -- all values of the second operator
            wait for 15 us;
        end loop;
        wait for 15 us;
        funct7 <= (OTHERS => '0');
        funct3 <= "110"; -- or
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        wait for 15 us;
        funct3 <= "111"; -- and
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;
        end loop;
        test_completed <= true after 15 us;
        wait;
    end process main;


end architecture rtl;
