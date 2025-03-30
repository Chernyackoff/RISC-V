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
        stall : IN STD_LOGIC;
        pc_branch : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        branch_taken : IN STD_LOGIC;
        cache_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        cache_req : OUT STD_LOGIC;
        cache_ready : IN STD_LOGIC;
        cache_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        instr : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        pc_out : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        valid : OUT STD_LOGIC
    );
END instruction_fetch;

ARCHITECTURE rtl OF instruction_fetch IS
    TYPE state_t IS (IDLE, WAIT_CACHE);
    SIGNAL state : state_t := IDLE;
    SIGNAL pc_reg : unsigned(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL instr_reg : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pc_out_reg : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valid_reg : STD_LOGIC := '0';
    SIGNAL cache_req_internal : STD_LOGIC := '0';
BEGIN
    PROCESS (clk, reset)
        VARIABLE next_pc : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
    BEGIN
        IF reset = '1' THEN
            pc_reg <= (OTHERS => '0');
            state <= IDLE;
            valid_reg <= '0';
            pc_out_reg <= (OTHERS => '0');
            instr_reg <= (OTHERS => '0');
            cache_req_internal <= '0';
        ELSIF rising_edge(clk) THEN
            IF branch_taken = '1' THEN
                next_pc := unsigned(pc_branch);
            ELSE
                next_pc := pc_reg + 4;
            END IF;

            IF stall = '0' THEN
                CASE state IS
                    WHEN IDLE =>
                        IF cache_req_internal = '0' THEN
                            cache_req_internal <= '1';
                            state <= WAIT_CACHE;
                        END IF;

                    WHEN WAIT_CACHE =>
                        IF cache_ready = '1' THEN
                            instr_reg <= cache_data;
                            pc_out_reg <= STD_LOGIC_VECTOR(pc_reg);

                            pc_reg <= next_pc;
                            valid_reg <= '1';
                            cache_req_internal <= '0';
                            state <= IDLE;
                        END IF;
                END CASE;
            ELSE
                -- Stall handling
                IF branch_taken = '1' THEN
                    pc_reg <= next_pc;
                    state <= IDLE;
                    cache_req_internal <= '0';
                END IF;
                valid_reg <= '0';
            END IF;
        END IF;
    END PROCESS;

    cache_addr <= STD_LOGIC_VECTOR(pc_reg);
    cache_req <= cache_req_internal;
    pc_out <= pc_out_reg;
    instr <= instr_reg;
    valid <= valid_reg;
END ARCHITECTURE rtl;