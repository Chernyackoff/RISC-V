LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY riscv_core_tb IS
END ENTITY riscv_core_tb;

ARCHITECTURE behavioral OF riscv_core_tb IS

    CONSTANT ADDR_WIDTH : INTEGER := 32;
    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT REG_ADDR_WIDTH : INTEGER := 5;
    CONSTANT RESET_POLARITY : STD_LOGIC := '1'; -- Set to '1' for Active High, '0' for Active Low

    CONSTANT CLK_PERIOD : TIME := 10 ns;

    COMPONENT riscv_core IS
        GENERIC (
            ADDR_WIDTH : INTEGER := ADDR_WIDTH;
            DATA_WIDTH : INTEGER := DATA_WIDTH;
            REG_ADDR_WIDTH : INTEGER := REG_ADDR_WIDTH;
            RESET_ACTIVE_AT : STD_LOGIC := RESET_POLARITY
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            icache_proc_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
            icache_proc_req : OUT STD_LOGIC;
            icache_proc_ready : IN STD_LOGIC;
            icache_proc_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT riscv_core;

    -- Testbench Signals
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL tb_rst : STD_LOGIC;
    SIGNAL tb_icache_proc_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL tb_icache_proc_req : STD_LOGIC;
    SIGNAL tb_icache_proc_ready : STD_LOGIC := '0';
    SIGNAL tb_icache_proc_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Instruction Memory Model
    CONSTANT INSTR_MEM_SIZE : INTEGER := 64; -- Size in words (adjust as needed)
    TYPE instruction_memory_t IS ARRAY (0 TO INSTR_MEM_SIZE - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_mem : instruction_memory_t := (
        0 => x"00500113", -- 0x00: addi x2, x0, 5       (x2 = 5)
        1 => x"00A00193", -- 0x04: addi x3, x0, 10      (x3 = 10)
        2 => x"00310233", -- 0x08: add x4, x2, x3       (x4 = 15)
        3 => x"FE310CE3", -- 0x0C: beq x2, x3, +28      (Branch to 0x28 if 5==10, Offset seems wrong in original, using it as is)
        4 => x"00100313", -- 0x10: addi x6, x0, 1       (x6 = 1)
        5 => x"01C000EF", -- 0x14: jal ra, +28          (Jump to 0x30, Link Addr=0x18 -> ra=x1)
        6 => x"06300293", -- 0x18: addi x5, x0, 99      (x5 = 99, Execution resumes here after JALR)
        7 => x"02000063", -- 0x1C: beq x0, x0, +32      (Jump to end_loop at 0x3C)
        8  => x"00000013", -- 0x20: nop
        9  => x"00000013", -- 0x24: nop
        10 => x"00000013", -- 0x28: nop (Target of original BEQ)
        11 => x"00000013", -- 0x2C: nop
        12 => x"04D00393", -- 0x30: addi x7, x0, 77      (Subroutine code: x7 = 77)
        13 => x"00008067", -- 0x34: jalr x0, ra, 0       (Return: Jump to address in ra=x1, which is 0x18)
        14 => x"00000013", -- 0x38: nop
        15 => x"00000E63", -- 0x3C: beq x0, x0, 0        (end_loop: Infinite loop jump to self)
    
        OTHERS => x"00000013" -- Fill remaining memory with NOPs
    );

    SIGNAL requested_addr_reg : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL req_pending : STD_LOGIC := '0';

    -- Function to convert std_logic_vector to hex string (pre-VHDL-2008)
    FUNCTION to_hex_string (slv : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO slv'length / 4);
        VARIABLE slv_padded : STD_LOGIC_VECTOR(slv'length + (4 - (slv'length MOD 4)) MOD 4 - 1 DOWNTO 0);
        VARIABLE digit : INTEGER;
    BEGIN
        slv_padded := (OTHERS => '0');
        slv_padded(slv'length - 1 DOWNTO 0) := slv;

        FOR i IN result'RANGE LOOP
            digit := to_integer(unsigned(slv_padded((result'length - i + 1) * 4 - 1 DOWNTO (result'length - i) * 4)));
            CASE digit IS
                WHEN 0 => result(i) := '0';
                WHEN 1 => result(i) := '1';
                WHEN 2 => result(i) := '2';
                WHEN 3 => result(i) := '3';
                WHEN 4 => result(i) := '4';
                WHEN 5 => result(i) := '5';
                WHEN 6 => result(i) := '6';
                WHEN 7 => result(i) := '7';
                WHEN 8 => result(i) := '8';
                WHEN 9 => result(i) := '9';
                WHEN 10 => result(i) := 'A';
                WHEN 11 => result(i) := 'B';
                WHEN 12 => result(i) := 'C';
                WHEN 13 => result(i) := 'D';
                WHEN 14 => result(i) := 'E';
                WHEN 15 => result(i) := 'F';
                WHEN OTHERS => result(i) := 'X';
            END CASE;
        END LOOP;
        RETURN result;
    END FUNCTION to_hex_string;
BEGIN

    dut : riscv_core
    GENERIC MAP(
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH,
        REG_ADDR_WIDTH => REG_ADDR_WIDTH,
        RESET_ACTIVE_AT => RESET_POLARITY
    )
    PORT MAP(
        clk => tb_clk,
        rst => tb_rst,
        icache_proc_addr => tb_icache_proc_addr,
        icache_proc_req => tb_icache_proc_req,
        icache_proc_ready => tb_icache_proc_ready,
        icache_proc_data => tb_icache_proc_data
    );

    clk_gen_proc : PROCESS
    BEGIN
        tb_clk <= '0';
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS clk_gen_proc;

    reset_gen_proc : PROCESS
    BEGIN
        tb_rst <= RESET_POLARITY;
        WAIT FOR CLK_PERIOD * 5;
        tb_rst <= NOT RESET_POLARITY;
        WAIT;
    END PROCESS reset_gen_proc;

    -- Instruction Cache Model (Simple 1-cycle latency ROM)
    icache_model_proc : PROCESS (tb_clk)
        VARIABLE word_addr : INTEGER;
        VARIABLE L : line;
        VARIABLE hex_str_addr : STRING(1 TO ADDR_WIDTH/4);
        VARIABLE hex_str_data : STRING(1 TO DATA_WIDTH/4);
    BEGIN
        IF rising_edge(tb_clk) THEN
            IF tb_rst = RESET_POLARITY THEN
                tb_icache_proc_ready <= '0';
                req_pending <= '0';
                requested_addr_reg <= (OTHERS => '0');
            ELSE
                -- Handle previous cycle's request
                IF req_pending = '1' THEN
                    word_addr := to_integer(unsigned(requested_addr_reg(ADDR_WIDTH - 1 DOWNTO 2)));
                    IF word_addr < INSTR_MEM_SIZE THEN
                        tb_icache_proc_data <= instr_mem(word_addr);
                        hex_str_addr := to_hex_string(requested_addr_reg);
                        hex_str_data := to_hex_string(instr_mem(word_addr));
                        write(L, STRING'("TB: Serving instr 0x"));
                        write(L, hex_str_data);
                        write(L, STRING'(" for addr 0x"));
                        write(L, hex_str_addr);
                        writeline(output, L);
                    ELSE
                        tb_icache_proc_data <= x"00000000";
                        hex_str_addr := to_hex_string(requested_addr_reg);
                        write(L, STRING'("TB: WARNING - Address 0x"));
                        write(L, hex_str_addr);
                        write(L, STRING'(" out of instr_mem bounds."));
                        writeline(output, L);
                    END IF;
                    tb_icache_proc_ready <= '1'; -- Data is ready now
                    req_pending <= '0';
                ELSE
                    tb_icache_proc_ready <= '0'; -- Not ready unless req was pending last cycle
                    tb_icache_proc_data <= (OTHERS => 'X'); -- Default data when not ready
                END IF;

                -- Check for new request this cycle, but only if not currently serving
                IF tb_icache_proc_req = '1' AND req_pending = '0' AND tb_icache_proc_ready = '0' THEN
                    requested_addr_reg <= tb_icache_proc_addr;
                    req_pending <= '1'; -- Mark request as pending for next cycle
                    hex_str_addr := to_hex_string(tb_icache_proc_addr);
                    write(L, STRING'("TB: Got req for addr 0x"));
                    write(L, hex_str_addr);
                    writeline(output, L);
                END IF;
            END IF;
        END IF;
    END PROCESS icache_model_proc;

    stimulus_proc : PROCESS
        VARIABLE L : line;
    BEGIN
        write(L, STRING'("TB: Simulation Starting..."));
        writeline(output, L);

        -- Wait for reset to finish
        WAIT UNTIL tb_rst = (NOT RESET_POLARITY);
        WAIT FOR CLK_PERIOD * 2;

        write(L, STRING'("TB: Core should be fetching instructions now..."));
        writeline(output, L);

        -- Let simulation run for a certain number of cycles
        WAIT FOR CLK_PERIOD * 50;

        write(L, STRING'("TB: Simulation Finished."));
        writeline(output, L);

        -- Use assert false to stop simulation (pre-VHDL-2008)
        ASSERT false REPORT "Simulation Stop" SEVERITY failure;

        WAIT;

    END PROCESS stimulus_proc;

END ARCHITECTURE behavioral;