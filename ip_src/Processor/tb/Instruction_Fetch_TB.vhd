LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instruction_fetch_tb IS
END instruction_fetch_tb;

ARCHITECTURE behav OF instruction_fetch_tb IS
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT ADDR_WIDTH : INTEGER := 32;
    CONSTANT DATA_WIDTH : INTEGER := 32;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '1';
    SIGNAL stall : STD_LOGIC := '0';
    SIGNAL pc_branch : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL branch_taken : STD_LOGIC := '0';
    SIGNAL cache_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL cache_req : STD_LOGIC;
    SIGNAL cache_ready : STD_LOGIC := '0';
    SIGNAL cache_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL instr : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL pc_out : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL valid : STD_LOGIC;

    TYPE instr_memory_t IS ARRAY(0 TO 15) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL instr_memory : instr_memory_t := (
        X"00000013", -- NOP (ADDI x0, x0, 0)
        X"00100093", -- ADDI x1, x0, 1
        X"00200113", -- ADDI x2, x0, 2
        X"00308193", -- ADDI x3, x1, 3
        X"00208213", -- ADDI x4, x1, 2
        X"00210233", -- ADD  x4, x2, x2
        X"40215293", -- SRAI x5, x2, 2
        X"0023E313", -- ORI  x6, x7, 2
        X"40428393", -- ADDI x7, x5, 1028
        X"00500E13", -- ADDI x28, x0, 5
        X"00600E93", -- ADDI x29, x0, 6
        X"00700F13", -- ADDI x30, x0, 7
        X"00800F93", -- ADDI x31, x0, 8
        X"0000006F", -- JAL x0, 0 (infinite loop)
        X"00000013", -- NOP
        X"00000013" -- NOP
    );

BEGIN
    UUT : ENTITY work.instruction_fetch
        GENERIC MAP(
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        PORT MAP(
            clk => clk,
            reset => reset,
            stall => stall,
            pc_branch => pc_branch,
            branch_taken => branch_taken,
            cache_addr => cache_addr,
            cache_req => cache_req,
            cache_ready => cache_ready,
            cache_data => cache_data,
            instr => instr,
            pc_out => pc_out,
            valid => valid
        );

    clk <= NOT clk AFTER CLK_PERIOD/2;

    cache_emulation : PROCESS (clk)
        VARIABLE addr_index : INTEGER;
    BEGIN
        IF rising_edge(clk) THEN
            IF cache_req = '1' THEN
                -- Simple cache simulation with 1-cycle latency
                cache_ready <= '1';

                -- Convert address to word-aligned index into our instruction memory
                addr_index := to_integer(unsigned(cache_addr(5 DOWNTO 2)));

                -- Bound check to prevent out-of-range access
                IF addr_index >= 0 AND addr_index < instr_memory'length THEN
                    cache_data <= instr_memory(addr_index);
                ELSE
                    cache_data <= X"00000013"; -- Return NOP for out-of-range addresses
                END IF;
            ELSE
                cache_ready <= '0';
            END IF;
        END IF;
    END PROCESS;

    stimulus : PROCESS
    BEGIN
        -- Reset the system
        reset <= '1';
        WAIT FOR CLK_PERIOD * 2;
        reset <= '0';
        WAIT FOR CLK_PERIOD;

        -- Let it fetch a few instructions
        WAIT FOR CLK_PERIOD * 5;

        -- Test stalling
        stall <= '1';
        WAIT FOR CLK_PERIOD * 3;
        stall <= '0';
        WAIT FOR CLK_PERIOD * 3;

        -- Test branching
        pc_branch <= X"00000020"; -- Branch to address 0x20 (word 8)
        branch_taken <= '1';
        WAIT FOR CLK_PERIOD;
        branch_taken <= '0';
        WAIT FOR CLK_PERIOD * 5;

        -- Test stalling during branch
        stall <= '1';
        pc_branch <= X"00000004"; -- Branch to address 0x4 (word 1)
        branch_taken <= '1';
        WAIT FOR CLK_PERIOD;
        branch_taken <= '0';
        WAIT FOR CLK_PERIOD;
        stall <= '0';
        WAIT FOR CLK_PERIOD * 5;

        -- End simulation
        ASSERT false REPORT "Simulation Stop" SEVERITY failure;
        WAIT;
    END PROCESS;

    monitor : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 20; -- Wait to collect some results
        ASSERT valid = '1' REPORT "Valid signal not asserted after initial fetch" SEVERITY error;
        WAIT;
    END PROCESS;

END behav;