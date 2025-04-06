LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instruction_fetch IS
    GENERIC (
        ADDR_WIDTH : INTEGER := 32;
        DATA_WIDTH : INTEGER := 32
    );
    PORT (
        clk         : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        stall       : IN  STD_LOGIC;                                 -- Stall signal from pipeline
        pc_branch   : IN  STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Target PC if branch is taken
        branch_taken: IN  STD_LOGIC;                                 -- Control signal indicating branch should be taken
        cache_addr  : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- Address requested from cache
        cache_req   : OUT STD_LOGIC;                                 -- Request signal to cache
        cache_ready : IN  STD_LOGIC;                                 -- Cache indicates data is ready
        cache_data  : IN  STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Data from cache
        instr       : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Instruction output
        pc_out      : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0); -- PC of the instruction output
        valid       : OUT STD_LOGIC                                  -- Indicates instr and pc_out are valid
    );
END instruction_fetch;

ARCHITECTURE rtl OF instruction_fetch IS
    TYPE state_t IS (FETCH, WAIT_CACHE);
    
    SIGNAL state           : state_t := FETCH;
    SIGNAL pc_reg          : unsigned(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL fetching_pc     : unsigned(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL instr_reg       : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_out_reg      : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valid_reg       : STD_LOGIC := '0';
    SIGNAL cache_req_reg   : STD_LOGIC := '0';

BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= FETCH;
            pc_reg <= (OTHERS => '0');
            fetching_pc <= (OTHERS => '0');
            instr_reg <= (OTHERS => '0');
            pc_out_reg <= (OTHERS => '0');
            valid_reg <= '0';
            cache_req_reg <= '0';
            
        ELSIF rising_edge(clk) THEN
            valid_reg <= '0';
            
            IF branch_taken = '1' THEN
                pc_reg <= unsigned(pc_branch);
                cache_req_reg <= '0';
                state <= FETCH;
            ELSIF stall = '0' THEN
                CASE state IS
                    WHEN FETCH =>
                        cache_req_reg <= '1';
                        fetching_pc <= pc_reg;
                        state <= WAIT_CACHE;
                        
                    WHEN WAIT_CACHE =>
                        IF cache_ready = '1' THEN
                            instr_reg <= cache_data;
                            pc_out_reg <= STD_LOGIC_VECTOR(fetching_pc);
                            valid_reg <= '1';
                            cache_req_reg <= '0';
                            
                            pc_reg <= pc_reg + 4;
                            state <= FETCH;
                        END IF;
                END CASE;
            ELSIF state = WAIT_CACHE AND cache_ready = '1' THEN
                instr_reg <= cache_data;
                pc_out_reg <= STD_LOGIC_VECTOR(fetching_pc);
                valid_reg <= '1';
                cache_req_reg <= '0';
                state <= FETCH;
            END IF;
        END IF;
    END PROCESS;

    cache_addr <= STD_LOGIC_VECTOR(pc_reg);
    cache_req <= cache_req_reg;
    pc_out <= pc_out_reg;
    instr <= instr_reg;
    valid <= valid_reg;

END ARCHITECTURE rtl;