LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY instruction_cache IS
    GENERIC (
        ADDR_WIDTH : INTEGER := 32; -- Address width
        DATA_WIDTH : INTEGER := 32; -- Data width (instruction width)
        CACHE_SIZE : INTEGER := 1024; -- Cache size in words
        CACHE_LINE_SIZE : INTEGER := 4; -- Words per cache line
        LINE_OFFSET_BITS : INTEGER := 2; -- log2(CACHE_LINE_SIZE)
        INDEX_BITS : INTEGER := 8 -- log2(CACHE_SIZE/CACHE_LINE_SIZE)
    );
    PORT (
        -- Clock and reset
        clk : IN STD_LOGIC;
        reset_n : IN STD_LOGIC;

        -- Processor interface
        proc_addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Address from processor
        proc_req : IN STD_LOGIC; -- Request from processor
        proc_ready : OUT STD_LOGIC; -- Ready signal to processor
        proc_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Instruction data to processor

        -- AXI Master interface
        axi_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Address to AXI
        axi_req : OUT STD_LOGIC; -- Request to AXI
        axi_ready : OUT STD_LOGIC; -- Ready signal to AXI (changed from in to out)
        axi_data : IN STD_LOGIC_VECTOR(DATA_WIDTH * CACHE_LINE_SIZE - 1 DOWNTO 0); -- Data from AXI
        axi_valid : IN STD_LOGIC -- Data valid from AXI
    );
END instruction_cache;

ARCHITECTURE rtl OF instruction_cache IS
    -- Calculate tag bits directly from generics
    CONSTANT TAG_BITS : INTEGER := ADDR_WIDTH - INDEX_BITS - LINE_OFFSET_BITS;

    -- Cache memory type definitions
    TYPE cache_data_type IS ARRAY (0 TO CACHE_SIZE - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    TYPE cache_tag_type IS ARRAY (0 TO (CACHE_SIZE/CACHE_LINE_SIZE) - 1) OF STD_LOGIC_VECTOR(TAG_BITS - 1 DOWNTO 0);
    TYPE cache_valid_type IS ARRAY (0 TO (CACHE_SIZE/CACHE_LINE_SIZE) - 1) OF STD_LOGIC;

    -- Cache memory signals
    SIGNAL cache_data : cache_data_type := (OTHERS => (OTHERS => '0'));
    SIGNAL cache_tag : cache_tag_type := (OTHERS => (OTHERS => '0'));
    SIGNAL cache_valid : cache_valid_type := (OTHERS => '0');

    -- Address decomposition
    SIGNAL addr_tag : STD_LOGIC_VECTOR(TAG_BITS - 1 DOWNTO 0);
    SIGNAL addr_index : STD_LOGIC_VECTOR(INDEX_BITS - 1 DOWNTO 0);
    SIGNAL addr_offset : STD_LOGIC_VECTOR(LINE_OFFSET_BITS - 1 DOWNTO 0);

    -- Cache control signals
    SIGNAL cache_hit : STD_LOGIC;
    SIGNAL line_index : INTEGER RANGE 0 TO (CACHE_SIZE/CACHE_LINE_SIZE) - 1;
    SIGNAL word_offset : INTEGER RANGE 0 TO CACHE_LINE_SIZE - 1;

    -- FSM states
    TYPE state_type IS (IDLE, CHECK_HIT, FETCH, UPDATE_CACHE);
    SIGNAL current_state : state_type;
    SIGNAL next_state : state_type;

    -- Output registers
    SIGNAL proc_ready_i : STD_LOGIC := '0';
    SIGNAL proc_data_i : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL axi_req_i : STD_LOGIC := '0';
    SIGNAL axi_addr_i : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL axi_ready_i : STD_LOGIC := '0'; -- Added internal signal for axi_ready

BEGIN
    -- Assign outputs
    proc_ready <= proc_ready_i;
    proc_data <= proc_data_i;
    axi_req <= axi_req_i;
    axi_addr <= axi_addr_i;
    axi_ready <= axi_ready_i; -- Connect internal signal to output port

    -- Address decomposition (fixed bit ranges based on generic parameters)
    addr_tag <= proc_addr(ADDR_WIDTH - 1 DOWNTO ADDR_WIDTH - TAG_BITS);
    addr_index <= proc_addr(ADDR_WIDTH - TAG_BITS - 1 DOWNTO LINE_OFFSET_BITS);
    addr_offset <= proc_addr(LINE_OFFSET_BITS - 1 DOWNTO 0);

    -- Convert address parts to integers for indexing
    line_index <= to_integer(unsigned(addr_index));
    word_offset <= to_integer(unsigned(addr_offset(LINE_OFFSET_BITS - 1 DOWNTO 2)));

    -- Cache hit detection logic
    cache_hit <= '1' WHEN (cache_valid(line_index) = '1' AND
        cache_tag(line_index) = addr_tag) ELSE
        '0';

    -- State machine process - sequential logic
    PROCESS (clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            -- Reset state and signals
            current_state <= IDLE;
            proc_ready_i <= '0';
            proc_data_i <= (OTHERS => '0');
            axi_req_i <= '0';
            axi_addr_i <= (OTHERS => '0');
            axi_ready_i <= '0'; -- Initialize axi_ready

            -- Initialize cache valid bits to 0
            FOR i IN 0 TO (CACHE_SIZE/CACHE_LINE_SIZE) - 1 LOOP
                cache_valid(i) <= '0';
            END LOOP;

        ELSIF rising_edge(clk) THEN
            -- Default state transition
            current_state <= next_state;

            -- Default values for output signals
            proc_ready_i <= '0';
            axi_req_i <= '0';
            axi_ready_i <= '0'; -- Default value for axi_ready

            -- State-specific actions
            CASE current_state IS
                WHEN IDLE =>
                    -- Nothing to do

                WHEN CHECK_HIT =>
                    IF cache_hit = '1' THEN
                        -- Cache hit
                        proc_ready_i <= '1';
                        proc_data_i <= cache_data(line_index * CACHE_LINE_SIZE + word_offset);
                    END IF;

                WHEN FETCH =>
                    -- Request data from AXI
                    axi_req_i <= '1';
                    -- Align address to cache line boundary
                    axi_addr_i <= proc_addr(ADDR_WIDTH - 1 DOWNTO LINE_OFFSET_BITS) &
                        (LINE_OFFSET_BITS - 1 DOWNTO 0 => '0');
                    -- Signal ready to accept data from AXI
                    axi_ready_i <= '1'; -- Set ready signal to indicate cache is ready to accept data

                WHEN UPDATE_CACHE =>
                    -- Continue to signal readiness to accept data
                    axi_ready_i <= '1'; -- Maintain ready signal while waiting for data

                    IF axi_valid = '1' THEN
                        -- Update tag and valid bit
                        cache_tag(line_index) <= addr_tag;
                        cache_valid(line_index) <= '1';

                        -- Update cache data (fill the entire cache line)
                        FOR i IN 0 TO CACHE_LINE_SIZE - 1 LOOP
                            cache_data(line_index * CACHE_LINE_SIZE + i) <=
                            axi_data((i + 1) * DATA_WIDTH - 1 DOWNTO i * DATA_WIDTH);
                        END LOOP;

                        -- Forward the requested word to processor
                        proc_ready_i <= '1';
                        proc_data_i <= axi_data((to_integer(unsigned(addr_offset(LINE_OFFSET_BITS - 1 DOWNTO 2))) + 1) * DATA_WIDTH - 1
                            DOWNTO to_integer(unsigned(addr_offset(LINE_OFFSET_BITS - 1 DOWNTO 2))) * DATA_WIDTH);
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- Next state logic - combinational process
    PROCESS (current_state, proc_req, cache_hit, axi_valid)
    BEGIN
        -- Default: keep current state
        next_state <= current_state;

        CASE current_state IS
            WHEN IDLE =>
                IF proc_req = '1' THEN
                    next_state <= CHECK_HIT;
                END IF;

            WHEN CHECK_HIT =>
                IF cache_hit = '1' THEN
                    next_state <= IDLE;
                ELSE
                    next_state <= FETCH;
                END IF;

            WHEN FETCH =>
                next_state <= UPDATE_CACHE;

            WHEN UPDATE_CACHE =>
                IF axi_valid = '1' THEN
                    next_state <= IDLE;
                END IF;
        END CASE;
    END PROCESS;

END rtl;