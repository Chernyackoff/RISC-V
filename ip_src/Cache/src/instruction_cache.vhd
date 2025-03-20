library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instruction_cache is
    generic (
        ADDR_WIDTH      : integer := 32;    -- Address width
        DATA_WIDTH      : integer := 32;    -- Data width (instruction width)
        CACHE_SIZE      : integer := 1024;  -- Cache size in words
        CACHE_LINE_SIZE : integer := 4;     -- Words per cache line
        LINE_OFFSET_BITS: integer := 2;     -- log2(CACHE_LINE_SIZE)
        INDEX_BITS      : integer := 8      -- log2(CACHE_SIZE/CACHE_LINE_SIZE)
    );
    port (
        -- Clock and reset
        clk             : in  std_logic;
        reset_n         : in  std_logic;
        
        -- Processor interface
        proc_addr       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Address from processor
        proc_req        : in  std_logic;                                -- Request from processor
        proc_ready      : out std_logic;                                -- Ready signal to processor
        proc_data       : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Instruction data to processor
        
        -- AXI Master interface
        axi_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Address to AXI
        axi_req         : out std_logic;                                -- Request to AXI
        axi_ready       : out std_logic;                                -- Ready signal to AXI (changed from in to out)
        axi_data        : in  std_logic_vector(DATA_WIDTH*CACHE_LINE_SIZE-1 downto 0);  -- Data from AXI
        axi_valid       : in  std_logic                                 -- Data valid from AXI
    );
end instruction_cache;

architecture rtl of instruction_cache is
    -- Calculate tag bits directly from generics
    constant TAG_BITS   : integer := ADDR_WIDTH - INDEX_BITS - LINE_OFFSET_BITS;
    
    -- Cache memory type definitions
    type cache_data_type is array (0 to CACHE_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type cache_tag_type is array (0 to (CACHE_SIZE/CACHE_LINE_SIZE)-1) of std_logic_vector(TAG_BITS-1 downto 0);
    type cache_valid_type is array (0 to (CACHE_SIZE/CACHE_LINE_SIZE)-1) of std_logic;
    
    -- Cache memory signals
    signal cache_data   : cache_data_type := (others => (others => '0'));
    signal cache_tag    : cache_tag_type := (others => (others => '0'));
    signal cache_valid  : cache_valid_type := (others => '0');
    
    -- Address decomposition
    signal addr_tag     : std_logic_vector(TAG_BITS-1 downto 0);
    signal addr_index   : std_logic_vector(INDEX_BITS-1 downto 0);
    signal addr_offset  : std_logic_vector(LINE_OFFSET_BITS-1 downto 0);
    
    -- Cache control signals
    signal cache_hit    : std_logic;
    signal line_index   : integer range 0 to (CACHE_SIZE/CACHE_LINE_SIZE)-1;
    signal word_offset  : integer range 0 to CACHE_LINE_SIZE-1;
    
    -- FSM states
    type state_type is (IDLE, CHECK_HIT, FETCH, UPDATE_CACHE);
    signal current_state : state_type;
    signal next_state    : state_type;
    
    -- Output registers
    signal proc_ready_i : std_logic := '0';
    signal proc_data_i  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_req_i    : std_logic := '0';
    signal axi_addr_i   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal axi_ready_i  : std_logic := '0';  -- Added internal signal for axi_ready
    
begin
    -- Assign outputs
    proc_ready <= proc_ready_i;
    proc_data <= proc_data_i;
    axi_req <= axi_req_i;
    axi_addr <= axi_addr_i;
    axi_ready <= axi_ready_i;  -- Connect internal signal to output port
    
    -- Address decomposition (fixed bit ranges based on generic parameters)
    addr_tag    <= proc_addr(ADDR_WIDTH-1 downto ADDR_WIDTH-TAG_BITS);
    addr_index  <= proc_addr(ADDR_WIDTH-TAG_BITS-1 downto LINE_OFFSET_BITS);
    addr_offset <= proc_addr(LINE_OFFSET_BITS-1 downto 0);
    
    -- Convert address parts to integers for indexing
    line_index <= to_integer(unsigned(addr_index));
    word_offset <= to_integer(unsigned(addr_offset(LINE_OFFSET_BITS-1 downto 2)));
    
    -- Cache hit detection logic
    cache_hit <= '1' when (cache_valid(line_index) = '1' and 
                          cache_tag(line_index) = addr_tag) else '0';
    
    -- State machine process - sequential logic
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            -- Reset state and signals
            current_state <= IDLE;
            proc_ready_i <= '0';
            proc_data_i <= (others => '0');
            axi_req_i <= '0';
            axi_addr_i <= (others => '0');
            axi_ready_i <= '0';  -- Initialize axi_ready
            
            -- Initialize cache valid bits to 0
            for i in 0 to (CACHE_SIZE/CACHE_LINE_SIZE)-1 loop
                cache_valid(i) <= '0';
            end loop;
            
        elsif rising_edge(clk) then
            -- Default state transition
            current_state <= next_state;
            
            -- Default values for output signals
            proc_ready_i <= '0';
            axi_req_i <= '0';
            axi_ready_i <= '0';  -- Default value for axi_ready
            
            -- State-specific actions
            case current_state is
                when IDLE =>
                    -- Nothing to do
                    
                when CHECK_HIT =>
                    if cache_hit = '1' then
                        -- Cache hit
                        proc_ready_i <= '1';
                        proc_data_i <= cache_data(line_index * CACHE_LINE_SIZE + word_offset);
                    end if;
                    
                when FETCH =>
                    -- Request data from AXI
                    axi_req_i <= '1';
                    -- Align address to cache line boundary
                    axi_addr_i <= proc_addr(ADDR_WIDTH-1 downto LINE_OFFSET_BITS) & 
                                 (LINE_OFFSET_BITS-1 downto 0 => '0');
                    -- Signal ready to accept data from AXI
                    axi_ready_i <= '1';  -- Set ready signal to indicate cache is ready to accept data
                    
                when UPDATE_CACHE =>
                    -- Continue to signal readiness to accept data
                    axi_ready_i <= '1';  -- Maintain ready signal while waiting for data
                    
                    if axi_valid = '1' then
                        -- Update tag and valid bit
                        cache_tag(line_index) <= addr_tag;
                        cache_valid(line_index) <= '1';
                        
                        -- Update cache data (fill the entire cache line)
                        for i in 0 to CACHE_LINE_SIZE-1 loop
                            cache_data(line_index * CACHE_LINE_SIZE + i) <= 
                                axi_data((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH);
                        end loop;
                        
                        -- Forward the requested word to processor
                        proc_ready_i <= '1';
                        proc_data_i <= axi_data((to_integer(unsigned(addr_offset(LINE_OFFSET_BITS-1 downto 2)))+1)*DATA_WIDTH-1 
                                              downto to_integer(unsigned(addr_offset(LINE_OFFSET_BITS-1 downto 2)))*DATA_WIDTH);
                    end if;
            end case;
        end if;
    end process;
    
    -- Next state logic - combinational process
    process(current_state, proc_req, cache_hit, axi_valid)
    begin
        -- Default: keep current state
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if proc_req = '1' then
                    next_state <= CHECK_HIT;
                end if;
                
            when CHECK_HIT =>
                if cache_hit = '1' then
                    next_state <= IDLE;
                else
                    next_state <= FETCH;
                end if;
                
            when FETCH =>
                next_state <= UPDATE_CACHE;
                
            when UPDATE_CACHE =>
                if axi_valid = '1' then
                    next_state <= IDLE;
                end if;
        end case;
    end process;
    
end rtl;