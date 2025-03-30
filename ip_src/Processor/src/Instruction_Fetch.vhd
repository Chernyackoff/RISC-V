LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instruction_fetch IS
    GENERIC (
        ADDR_WIDTH : INTEGER := 32;
        DATA_WIDTH : INTEGER := 32
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        stall : IN STD_LOGIC; -- Stall signal from pipeline (e.g., ID stage not ready)
        pc_branch : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Target PC if branch is taken
        branch_taken : IN STD_LOGIC; -- Control signal indicating branch should be taken
        cache_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Address requested from cache
        cache_req : OUT STD_LOGIC; -- Request signal to cache
        cache_ready : IN STD_LOGIC; -- Cache indicates data is ready
        cache_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Data from cache
        instr : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Instruction output
        pc_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- PC of the instruction output
        valid : OUT STD_LOGIC -- Indicates instr and pc_out are valid
    );
END instruction_fetch;

ARCHITECTURE rtl OF instruction_fetch IS
    TYPE state_t IS (FETCH, WAIT_CACHE);
    SIGNAL state : state_t := FETCH;
    SIGNAL pc_reg : unsigned(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL instr_reg : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_out_reg : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valid_reg : STD_LOGIC := '0';
    SIGNAL cache_req_internal : STD_LOGIC := '0';
    SIGNAL fetching_pc : unsigned(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

BEGIN

    PROCESS (clk, reset)
        VARIABLE pc_plus_4 : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
        VARIABLE update_outputs : BOOLEAN;
        VARIABLE next_state : state_t;
        VARIABLE next_pc : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
        VARIABLE next_req : STD_LOGIC;
    BEGIN
        IF reset = '1' THEN
            pc_reg <= (OTHERS => '0');
            fetching_pc <= (OTHERS => '0');
            state <= FETCH;
            valid_reg <= '0';
            pc_out_reg <= (OTHERS => '0');
            instr_reg <= (OTHERS => '0');
            cache_req_internal <= '0';
        ELSIF rising_edge(clk) THEN

            update_outputs := FALSE;
            next_state := state;
            next_pc := pc_reg;
            next_req := cache_req_internal;

            IF state = WAIT_CACHE AND cache_ready = '1' THEN
                update_outputs := TRUE;
                next_state := FETCH;
                next_req := '0';
            END IF;

            IF branch_taken = '1' THEN
                next_pc := unsigned(pc_branch);

                next_state := FETCH;
                next_req := '0';

                IF NOT (state = WAIT_CACHE AND cache_ready = '1') THEN
                    update_outputs := FALSE;
                END IF;

            ELSIF stall = '1' THEN
                next_pc := pc_reg;
                next_state := state;
                next_req := cache_req_internal;

                update_outputs := FALSE;

            ELSE
                pc_plus_4 := pc_reg + 4;
                IF state = FETCH THEN
                    next_req := '1';
                    fetching_pc <= pc_reg;
                    next_state := WAIT_CACHE;
                ELSIF state = WAIT_CACHE THEN
                    IF cache_ready = '1' THEN
                        next_pc := pc_plus_4;
                    ELSE
                        next_pc := pc_reg;
                        next_state := WAIT_CACHE;
                        next_req := '1';
                    END IF;
                END IF;
            END IF;

            IF update_outputs THEN
                instr_reg <= cache_data;
                pc_out_reg <= STD_LOGIC_VECTOR(fetching_pc);
                valid_reg <= '1';
            ELSE
                valid_reg <= '0';
            END IF;

            state <= next_state;
            pc_reg <= next_pc;
            cache_req_internal <= next_req;

        END IF;
    END PROCESS;

    cache_addr <= STD_LOGIC_VECTOR(pc_reg);
    cache_req <= cache_req_internal;
    pc_out <= pc_out_reg;
    instr <= instr_reg;
    valid <= valid_reg;

END ARCHITECTURE rtl;