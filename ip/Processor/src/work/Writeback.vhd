LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY writeback IS
    GENERIC (
        DATA_WIDTH : INTEGER := 32
    );
    PORT (
        wb_sel_pc4 : IN STD_LOGIC; -- '1' = select PC+4, '0' = select ALU result
        ex_alu_result : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Result from ALU in EX stage
        ex_link_address : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- PC+4 from EX stage (for JAL/JALR)

        wb_write_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END ENTITY writeback;

ARCHITECTURE behavioral OF writeback IS
BEGIN
    wb_mux_proc : PROCESS (wb_sel_pc4, ex_alu_result, ex_link_address)
    BEGIN
        IF wb_sel_pc4 = '1' THEN
            wb_write_data <= ex_link_address; -- Select PC+4 for JAL/JALR
        ELSE
            wb_write_data <= ex_alu_result; -- Select ALU result otherwise
        END IF;
    END PROCESS wb_mux_proc;

END ARCHITECTURE behavioral;