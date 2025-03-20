library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity instruction_cache_tb is
-- Testbench has no ports
end instruction_cache_tb;

architecture Behavioral of instruction_cache_tb is
    -- Constants
    constant CLK_PERIOD : time := 10 ns;
    constant ADDR_WIDTH : integer := 32;
    constant DATA_WIDTH : integer := 32;
    constant CACHE_SIZE : integer := 64;  -- Smaller size for simulation
    constant CACHE_LINE_SIZE : integer := 4;
    constant LINE_OFFSET_BITS : integer := 2;  -- log2(CACHE_LINE_SIZE)
    constant INDEX_BITS : integer := 4;  -- log2(CACHE_SIZE/CACHE_LINE_SIZE)
    
    -- Component declaration
    component instruction_cache
        generic (
            ADDR_WIDTH      : integer;
            DATA_WIDTH      : integer;
            CACHE_SIZE      : integer;
            CACHE_LINE_SIZE : integer;
            LINE_OFFSET_BITS: integer;
            INDEX_BITS      : integer
        );
        port (
            clk             : in  std_logic;
            reset_n         : in  std_logic;
            proc_addr       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
            proc_req        : in  std_logic;
            proc_ready      : out std_logic;
            proc_data       : out std_logic_vector(DATA_WIDTH-1 downto 0);
            axi_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            axi_req         : out std_logic;
            axi_ready       : in  std_logic;
            axi_data        : in  std_logic_vector(DATA_WIDTH*CACHE_LINE_SIZE-1 downto 0);
            axi_valid       : in  std_logic
        );
    end component;
    
    -- Signal declarations
    -- Clock and reset
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    
    -- Processor interface
    signal proc_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal proc_req : std_logic := '0';
    signal proc_ready : std_logic;
    signal proc_data : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- AXI interface
    signal axi_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal axi_req : std_logic;
    signal axi_ready : std_logic := '0';
    signal axi_data : std_logic_vector(DATA_WIDTH*CACHE_LINE_SIZE-1 downto 0) := (others => '0');
    signal axi_valid : std_logic := '0';
    
    -- Test control
    signal sim_done : boolean := false;
    
    -- Stimulus data
    type addr_array is array (natural range <>) of std_logic_vector(ADDR_WIDTH-1 downto 0);
    type data_array is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Test data - addresses and expected data
    constant TEST_ADDRESSES : addr_array := (
        X"00000000", -- First address
        X"00000004", -- Next word in same line
        X"00000008", -- Next word in same line
        X"0000000C", -- Last word in first line
        X"00000010", -- First word in new line
        X"00000000", -- Repeat first address (should be cache hit)
        X"00000100", -- New cache line
        X"00000104"  -- Next word in new line
    );
    
    -- Helper function to create test data pattern
    function create_test_data(addr: std_logic_vector) return std_logic_vector is
        variable line_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
        variable data_out : std_logic_vector(DATA_WIDTH*CACHE_LINE_SIZE-1 downto 0);
    begin
        -- Align to cache line boundary
        line_addr := addr(ADDR_WIDTH-1 downto LINE_OFFSET_BITS) & (LINE_OFFSET_BITS-1 downto 0 => '0');
        
        -- Create unique data pattern for each word in the line
        for i in 0 to CACHE_LINE_SIZE-1 loop
            -- Pattern: Upper bits from address, lower bits from word position
            data_out((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH) := 
                std_logic_vector(unsigned(line_addr) + i*4) or X"DEADBEEF";
        end loop;
        
        return data_out;
    end function;
    
    -- Helper function to convert std_logic_vector to string for reporting
    function vec_to_str(vec: std_logic_vector) return string is
        variable result : string(1 to vec'length);
        variable bit_str : string(1 to 1);
    begin
        for i in vec'range loop
            case vec(i) is
                when '0' => bit_str := "0";
                when '1' => bit_str := "1";
                when others => bit_str := "X";
            end case;
            result(vec'length - i) := bit_str(1);
        end loop;
        return result;
    end function;
    
    -- Helper function to convert hex 4-bit vector to character
    function hex_char(vec: std_logic_vector(3 downto 0)) return character is
        variable result : character;
    begin
        case vec is
            when "0000" => result := '0';
            when "0001" => result := '1';
            when "0010" => result := '2';
            when "0011" => result := '3';
            when "0100" => result := '4';
            when "0101" => result := '5';
            when "0110" => result := '6';
            when "0111" => result := '7';
            when "1000" => result := '8';
            when "1001" => result := '9';
            when "1010" => result := 'A';
            when "1011" => result := 'B';
            when "1100" => result := 'C';
            when "1101" => result := 'D';
            when "1110" => result := 'E';
            when "1111" => result := 'F';
            when others => result := 'X';
        end case;
        return result;
    end function;
    
    -- Helper function to convert vector to hex string
    function to_hex_string(vec: std_logic_vector) return string is
        variable result : string(1 to (vec'length+3)/4);  -- Ceiling division
        variable v : std_logic_vector(vec'length-1 downto 0) := vec;
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in result'range loop
            if (i-1)*4+3 <= v'high then
                nibble := v((i-1)*4+3 downto (i-1)*4);
            elsif (i-1)*4 <= v'high then
                nibble := (3 downto v'high-(i-1)*4+1 => '0') & v(v'high downto (i-1)*4);
            else
                nibble := (others => '0');
            end if;
            result(result'length-i+1) := hex_char(nibble);
        end loop;
        return result;
    end function;
    
begin
    -- Clock generation
    process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- DUT instantiation
    DUT: instruction_cache
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH,
            CACHE_SIZE => CACHE_SIZE,
            CACHE_LINE_SIZE => CACHE_LINE_SIZE,
            LINE_OFFSET_BITS => LINE_OFFSET_BITS,
            INDEX_BITS => INDEX_BITS
        )
        port map (
            clk => clk,
            reset_n => reset_n,
            proc_addr => proc_addr,
            proc_req => proc_req,
            proc_ready => proc_ready,
            proc_data => proc_data,
            axi_addr => axi_addr,
            axi_req => axi_req,
            axi_ready => axi_ready,
            axi_data => axi_data,
            axi_valid => axi_valid
        );
    
    -- Stimulus process
    process
        variable expected_data : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable line_data : std_logic_vector(DATA_WIDTH*CACHE_LINE_SIZE-1 downto 0);
        variable offset : integer;
        variable line_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    begin
        -- Reset sequence
        reset_n <= '0';
        wait for CLK_PERIOD * 5;
        reset_n <= '1';
        wait for CLK_PERIOD * 2;
        
        report "Starting test sequence";
        
        -- Test sequence
        for i in TEST_ADDRESSES'range loop
            -- Set processor request
            proc_addr <= TEST_ADDRESSES(i);
            proc_req <= '1';
            
            -- Calculate expected data
            offset := to_integer(unsigned(TEST_ADDRESSES(i)(LINE_OFFSET_BITS-1 downto 0))) / 4;
            line_addr := TEST_ADDRESSES(i)(ADDR_WIDTH-1 downto LINE_OFFSET_BITS) & (LINE_OFFSET_BITS-1 downto 0 => '0');
            line_data := create_test_data(TEST_ADDRESSES(i));
            expected_data := line_data((offset+1)*DATA_WIDTH-1 downto offset*DATA_WIDTH);
            
            report "Test " & integer'image(i) & ": Requesting address " & 
                   to_hex_string(TEST_ADDRESSES(i));
            
            -- Wait for cache to respond
            wait for CLK_PERIOD * 3;
            proc_req <= '0';
            
            -- Wait for cache to process
            if axi_req = '1' then
                -- Cache miss - simulate AXI response
                report "Cache miss detected";
                wait for CLK_PERIOD * 2;  -- Simulate AXI latency
                
                axi_ready <= '1';
                wait for CLK_PERIOD;
                axi_ready <= '0';
                
                -- Prepare AXI data response
                axi_data <= line_data;
                
                -- Wait and then assert valid
                wait for CLK_PERIOD * 2;  -- Simulate memory access time
                axi_valid <= '1';
                wait for CLK_PERIOD;
                axi_valid <= '0';
            end if;
            
            
            if proc_data = expected_data then
                report "Test " & integer'image(i) & " PASSED: Data matches expected";
            else
                report "Test " & integer'image(i) & " FAILED: Data mismatch" &
                       " Got: " & to_hex_string(proc_data) &
                       " Expected: " & to_hex_string(expected_data)
                severity error;
            end if;
        
            -- Wait before next test
            wait for CLK_PERIOD * 2;
        end loop;
        
        -- End simulation
        report "Test sequence completed";
        sim_done <= true;
        wait;
    end process;
    
    -- Monitor process
    process
    begin
        wait until sim_done;
        report "Simulation completed successfully";
        wait;
    end process;
    
end Behavioral;