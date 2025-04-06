LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

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
    SIGNAL instr_mem : instr_memory_t := (
        0 => x"00500113", -- 0x00: addi x2, x0, 5       (x2 = 5)
        1 => x"00A00193", -- 0x04: addi x3, x0, 10      (x3 = 10)
        2 => x"00310233", -- 0x08: add x4, x2, x3       (x4 = 15)
        3 => x"FE310CE3", -- 0x0C: beq x2, x3, +28(??)  (Branch to 0x28 if 5==10, Offset seems wrong in original, using it as is)
        4 => x"00100313", -- 0x10: addi x6, x0, 1       (x6 = 1)
        5 => x"01C000EF", -- 0x14: jal ra, +28          (Jump to 0x30, Link Addr=0x18 -> ra=x1)
        6 => x"06300293", -- 0x18: addi x5, x0, 99      (x5 = 99, Execution resumes here after JALR)
        7 => x"02000063", -- 0x1C: beq x0, x0, +32      (Jump to end_loop at 0x3C)
        8 => x"00000013", -- 0x20: nop
        9 => x"00000013", -- 0x24: nop
        10 => x"00000013", -- 0x28: nop (Target of original BEQ)
        11 => x"00000013", -- 0x2C: nop
        12 => x"04D00393", -- 0x30: addi x7, x0, 77      (Subroutine code: x7 = 77)
        13 => x"00008067", -- 0x34: jalr x0, ra, 0       (Return: Jump to address in ra=x1, which is 0x18)
        14 => x"00000013", -- 0x38: nop
        15 => x"00000E63", -- 0x3C: beq x0, x0, 0        (end_loop: Infinite loop jump to self)
        OTHERS => x"00000013" -- Fill remaining memory with NOPs
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
                IF addr_index >= 0 AND addr_index < instr_mem'length THEN
                    cache_data <= instr_mem(addr_index);
                ELSE
                    cache_data <= X"00000013"; -- Return NOP for out-of-range addresses
                END IF;
            ELSE
                cache_ready <= '0';
            END IF;
        END IF;
    END PROCESS;

    stimulus : PROCESS
        PROCEDURE wait_cycles (count : INTEGER) IS
        BEGIN
            FOR i IN 1 TO count LOOP
                WAIT UNTIL rising_edge(clk);
            END LOOP;
        END PROCEDURE wait_cycles;

        -- Procedure to wait for a specific PC value when valid
        PROCEDURE wait_for_pc (target_pc : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); msg : STRING) IS
        BEGIN
            REPORT "Stimulus: Waiting for " & msg & "...";
            WAIT UNTIL rising_edge(clk) AND valid = '1' AND pc_out = target_pc;
            REPORT "Stimulus: " & msg & " detected.";
        END PROCEDURE wait_for_pc;

    BEGIN
        REPORT "Stimulus: Starting Testbench...";

        -- 1. Reset the system
        reset <= '1';
        stall <= '0';
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0');
        REPORT "Stimulus: Asserting Reset.";
        wait_cycles(3);
        reset <= '0';
        REPORT "Stimulus: Deasserting Reset.";
        wait_cycles(1); -- Wait one cycle for reset to propagate

        -- Fetch initial sequence, confirming each step
        wait_for_pc(X"00000000", "pc_out = 0x00");
        wait_for_pc(X"00000004", "pc_out = 0x04");
        wait_for_pc(X"00000008", "pc_out = 0x08");
        wait_for_pc(X"0000000C", "pc_out = 0x0C (BEQ)");
        wait_for_pc(X"00000010", "pc_out = 0x10");

        -- *** Synchronization Point ***
        -- Now wait specifically for PC=0x14 (the JAL) to be output
        wait_for_pc(X"00000014", "pc_out = 0x14 (JAL)");

        -- 2. Introduce a stall *after* fetching 0x14
        REPORT "Stimulus: PC=0x14 fetched. Asserting Stall.";
        stall <= '1';
        wait_cycles(4); -- Hold stall
        stall <= '0';
        REPORT "Stimulus: Deasserting Stall.";
        wait_cycles(1); -- Allow recovery cycle (important!)

        -- 3. Apply branch signals for JAL (PC=0x14 -> Target=0x30)
        -- This should happen in the cycle *after* recovery from stall
        REPORT "Stimulus: Applying JAL branch (Target 0x30).";
        pc_branch <= X"00000030";
        branch_taken <= '1';
        wait_cycles(1); -- Assert branch signals for one cycle
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0'); -- Deassert target
        REPORT "Stimulus: JAL Branch signals pulsed. Expecting fetch for PC=0x30 next.";

        -- Wait for the branch target to be fetched
        wait_for_pc(X"00000030", "pc_out = 0x30 (JAL target)");

        -- Wait for JALR instruction at 0x34
        wait_for_pc(X"00000034", "pc_out = 0x34 (JALR)");

        -- 4. Apply branch signals for JALR (PC=0x34 -> Target=0x18)
        REPORT "Stimulus: Applying JALR branch (Target 0x18).";
        pc_branch <= X"00000018";
        branch_taken <= '1';
        wait_cycles(1); -- Assert branch signals for one cycle
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0');
        REPORT "Stimulus: JALR Branch signals pulsed. Expecting fetch for PC=0x18 next.";

        -- Wait for JALR target
        wait_for_pc(X"00000018", "pc_out = 0x18 (JALR target)");

        -- Wait for BEQ instruction at 0x1C
        wait_for_pc(X"0000001C", "pc_out = 0x1C (BEQ)");

        -- 5. Apply stall + branch for BEQ (PC=0x1C -> Target=0x3C)
        REPORT "Stimulus: Applying BEQ branch (Target 0x3C) and Stall concurrently.";
        pc_branch <= X"0000003C";
        branch_taken <= '1';
        stall <= '1'; -- Stall concurrently with branch signals
        wait_cycles(1);
        -- Hold stall, deassert branch signals after one cycle
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0');
        REPORT "Stimulus: BEQ Branch signals pulsed (while stalled).";
        wait_cycles(3); -- Hold stall longer
        stall <= '0';
        REPORT "Stimulus: Deasserting Stall. Expecting fetch for PC=0x3C next.";

        -- Wait for BEQ target (start of loop)
        wait_for_pc(X"0000003C", "pc_out = 0x3C (BEQ target/Loop start)");

        -- Wait for the fetch *after* 0x3C (which should be 0x40 before the loop redirects)
        wait_for_pc(X"00000040", "pc_out = 0x40 (Sequential after 0x3C)");

        -- 6. Apply branch for Loop (PC=0x3C -> Target=0x3C) - 1st Iteration
        REPORT "Stimulus: Applying Loop branch (Target 0x3C) - Iter 1.";
        pc_branch <= X"0000003C";
        branch_taken <= '1';
        wait_cycles(1);
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0');
        REPORT "Stimulus: Loop Branch pulsed (Iter 1).";

        -- Wait for loop target again
        wait_for_pc(X"0000003C", "pc_out = 0x3C (Loop Iter 1 target)");
        -- Wait for sequential fetch again
        wait_for_pc(X"00000040", "pc_out = 0x40 (Sequential after 0x3C - Iter 1)");

        -- 7. Apply branch for Loop (PC=0x3C -> Target=0x3C) - 2nd Iteration
        REPORT "Stimulus: Applying Loop branch (Target 0x3C) - Iter 2.";
        pc_branch <= X"0000003C";
        branch_taken <= '1';
        wait_cycles(1);
        branch_taken <= '0';
        pc_branch <= (OTHERS => '0');
        REPORT "Stimulus: Loop Branch pulsed (Iter 2).";

        -- Wait for loop target again
        wait_for_pc(X"0000003C", "pc_out = 0x3C (Loop Iter 2 target)");

        -- Let it run a bit more
        wait_cycles(5);

        -- End simulation
        REPORT "Stimulus: Test scenario complete.";
        ASSERT false REPORT "Simulation Stop" SEVERITY failure;
        WAIT; -- Stop process
    END PROCESS stimulus;

    -- monitor process remains the same
    monitor : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD * 20; -- Wait to collect some results
        ASSERT valid = '1' REPORT "Valid signal not asserted after initial fetch" SEVERITY error;
        WAIT;
    END PROCESS;

END ARCHITECTURE behav;