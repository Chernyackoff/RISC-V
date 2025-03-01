
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

entity ALU_TB is
GENERIC (
  DATA_WIDTH : INTEGER := 32;
  OPCODE_WIDTH :INTEGER := 3
);
end entity ALU_TB;

architecture rtl of ALU_TB is
    component ALU is
    GENERIC (
        ALU_DATA_WIDTH: INTEGER := 32;
        ALU_OPCODE_WIDTH: INTEGER := 3
    );
    PORT (
        rst    : IN STD_LOGIC;--! sync active high reset. sync -> refclk
        alu_input_a : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);
        alu_input_b : IN unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);
        alu_output : OUT unsigned(ALU_DATA_WIDTH - 1 DOWNTO 0);
        alu_opcode : IN unsigned(ALU_OPCODE_WIDTH - 1 DOWNTO 0)
    );
    END component;
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
    SIGNAL a : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL c : unsigned(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL opcode : unsigned(OPCODE_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    signal test_completed: boolean := false;
begin

alu_inst: ALU 
GENERIC MAP (
    ALU_DATA_WIDTH => DATA_WIDTH,
    ALU_OPCODE_WIDTH => OPCODE_WIDTH
)
PORT MAP (
    rst => rst,
    alu_input_a => a,
    alu_input_b => b,
    alu_output => c,
    alu_opcode => opcode
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
        opcode <= "000"; -- add operation
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "001"; -- logical left shift 
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "010"; -- all values of the first operator
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "011"; -- Set 1 if b (immediate) > a. All parameter are unsigned
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "100"; -- xor
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "101"; -- logical shift right
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "110"; -- or
        wait for 15 us;
        for i in 0 to 5 loop
            a <= to_unsigned(i, a'length); -- all values of the first operator
            wait for 15 us;
            for j in 0 to 5 loop
                b <= to_unsigned(j, b'length); -- all values of the second operator
                wait for 15 us;
            end loop;

        end loop;
        opcode <= "111"; -- and
        wait for 15 us;
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
