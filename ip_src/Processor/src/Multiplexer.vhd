LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY Multiplexer IS
    GENERIC (
        MUL_DATA_WIDTH : INTEGER := 32;
        MUL_SEL_WIDTH : INTEGER := 1
    );
    PORT (
        mul_input_0 : IN UNSIGNED(MUL_DATA_WIDTH - 1 DOWNTO 0);
        mul_input_1 : IN UNSIGNED(MUL_DATA_WIDTH - 1 DOWNTO 0);
        mul_output : OUT UNSIGNED(MUL_DATA_WIDTH - 1 DOWNTO 0);
        mul_sel : IN UNSIGNED(MUL_SEL_WIDTH - 1 DOWNTO 0)
    );
END ENTITY Multiplexer;

ARCHITECTURE rtl OF Multiplexer IS
BEGIN
    mux_proc : PROCESS (mul_input_0, mul_input_1, mul_sel)
    BEGIN
        IF mul_sel = "0" THEN
            mul_output <= mul_input_0;
        ELSE
            mul_output <= mul_input_1;
        END IF;
    END PROCESS mux_proc;
END ARCHITECTURE rtl;