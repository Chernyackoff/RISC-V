LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY instruction_cache_tb IS
    -- Testbench has no ports
END instruction_cache_tb;

ARCHITECTURE Behavioral OF instruction_cache_tb IS
    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT ADDR_WIDTH : INTEGER := 32;
    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT CACHE_SIZE : INTEGER := 64; -- Smaller size for simulation
    CONSTANT CACHE_LINE_SIZE : INTEGER := 4;
    CONSTANT LINE_OFFSET_BITS : INTEGER := 2; -- log2(CACHE_LINE_SIZE)
    CONSTANT INDEX_BITS : INTEGER := 4; -- log2(CACHE_SIZE/CACHE_LINE_SIZE)

    -- Component declaration
    COMPONENT instruction_cache
        GENERIC (
            ADDR_WIDTH : INTEGER;
            DATA_WIDTH : INTEGER;
            CACHE_SIZE : INTEGER;
            CACHE_LINE_SIZE : INTEGER;
            LINE_OFFSET_BITS : INTEGER;
            INDEX_BITS : INTEGER
        );
        PORT (
            clk : IN STD_LOGIC;
            reset_n : IN STD_LOGIC;
            proc_addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
            proc_req : IN STD_LOGIC;
            proc_ready : OUT STD_LOGIC;
            proc_data : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
            axi_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
            axi_req : OUT STD_LOGIC;
            axi_ready : OUT STD_LOGIC; -- Changed from in to out
            axi_data : IN STD_LOGIC_VECTOR(DATA_WIDTH * CACHE_LINE_SIZE - 1 DOWNTO 0);
            axi_valid : IN STD_LOGIC
        );
    END COMPONENT;

    -- Signal declarations
    -- Clock and reset
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL reset_n : STD_LOGIC := '0';

    -- Processor interface
    SIGNAL proc_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL proc_req : STD_LOGIC := '0';
    SIGNAL proc_ready : STD_LOGIC;
    SIGNAL proc_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- AXI interface
    SIGNAL axi_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL axi_req : STD_LOGIC;
    SIGNAL axi_ready : STD_LOGIC; -- Now an output from the DUT
    SIGNAL axi_data : STD_LOGIC_VECTOR(DATA_WIDTH * CACHE_LINE_SIZE - 1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL axi_valid : STD_LOGIC := '0';

    -- Test control
    SIGNAL sim_done : BOOLEAN := false;

    -- Stimulus data
    TYPE addr_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    TYPE data_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Test data - addresses and expected data
    CONSTANT TEST_ADDRESSES : addr_array := (
        X"00000000", -- First address
        X"00000004", -- Next word in same line
        X"00000008", -- Next word in same line
        X"0000000C", -- Last word in first line
        X"00000010", -- First word in new line
        X"00000000", -- Repeat first address (should be cache hit)
        X"00000100", -- New cache line
        X"00000104" -- Next word in new line
    );

    -- Helper function to create test data pattern
    FUNCTION create_test_data(addr : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
        VARIABLE line_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        VARIABLE data_out : STD_LOGIC_VECTOR(DATA_WIDTH * CACHE_LINE_SIZE - 1 DOWNTO 0);
    BEGIN
        -- Align to cache line boundary
        line_addr := addr(ADDR_WIDTH - 1 DOWNTO LINE_OFFSET_BITS) & (LINE_OFFSET_BITS - 1 DOWNTO 0 => '0');

        -- Create unique data pattern for each word in the line
        FOR i IN 0 TO CACHE_LINE_SIZE - 1 LOOP
            -- Pattern: Upper bits from address, lower bits from word position
            data_out((i + 1) * DATA_WIDTH - 1 DOWNTO i * DATA_WIDTH) :=
            STD_LOGIC_VECTOR(unsigned(line_addr) + i * 4) OR X"DEADBEEF";
        END LOOP;

        RETURN data_out;
    END FUNCTION;

    -- Helper function to convert std_logic_vector to string for reporting
    FUNCTION vec_to_str(vec : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO vec'length);
        VARIABLE bit_str : STRING(1 TO 1);
    BEGIN
        FOR i IN vec'RANGE LOOP
            CASE vec(i) IS
                WHEN '0' => bit_str := "0";
                WHEN '1' => bit_str := "1";
                WHEN OTHERS => bit_str := "X";
            END CASE;
            result(vec'length - i) := bit_str(1);
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- Helper function to convert hex 4-bit vector to character
    FUNCTION hex_char(vec : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN CHARACTER IS
        VARIABLE result : CHARACTER;
    BEGIN
        CASE vec IS
            WHEN "0000" => result := '0';
            WHEN "0001" => result := '1';
            WHEN "0010" => result := '2';
            WHEN "0011" => result := '3';
            WHEN "0100" => result := '4';
            WHEN "0101" => result := '5';
            WHEN "0110" => result := '6';
            WHEN "0111" => result := '7';
            WHEN "1000" => result := '8';
            WHEN "1001" => result := '9';
            WHEN "1010" => result := 'A';
            WHEN "1011" => result := 'B';
            WHEN "1100" => result := 'C';
            WHEN "1101" => result := 'D';
            WHEN "1110" => result := 'E';
            WHEN "1111" => result := 'F';
            WHEN OTHERS => result := 'X';
        END CASE;
        RETURN result;
    END FUNCTION;

    -- Helper function to convert vector to hex string
    FUNCTION to_hex_string(vec : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO (vec'length + 3)/4); -- Ceiling division
        VARIABLE v : STD_LOGIC_VECTOR(vec'length - 1 DOWNTO 0) := vec;
        VARIABLE nibble : STD_LOGIC_VECTOR(3 DOWNTO 0);
    BEGIN
        FOR i IN result'RANGE LOOP
            IF (i - 1) * 4 + 3 <= v'high THEN
                nibble := v((i - 1) * 4 + 3 DOWNTO (i - 1) * 4);
            ELSIF (i - 1) * 4 <= v'high THEN
                nibble := (3 DOWNTO v'high - (i - 1) * 4 + 1 => '0') & v(v'high DOWNTO (i - 1) * 4);
            ELSE
                nibble := (OTHERS => '0');
            END IF;
            result(result'length - i + 1) := hex_char(nibble);
        END LOOP;
        RETURN result;
    END FUNCTION;

BEGIN
    -- Clock generation
    PROCESS
    BEGIN
        WHILE NOT sim_done LOOP
            clk <= '0';
            WAIT FOR CLK_PERIOD/2;
            clk <= '1';
            WAIT FOR CLK_PERIOD/2;
        END LOOP;
        WAIT;
    END PROCESS;

    -- DUT instantiation
    DUT : instruction_cache
    GENERIC MAP(
        ADDR_WIDTH => ADDR_WIDTH,
        DATA_WIDTH => DATA_WIDTH,
        CACHE_SIZE => CACHE_SIZE,
        CACHE_LINE_SIZE => CACHE_LINE_SIZE,
        LINE_OFFSET_BITS => LINE_OFFSET_BITS,
        INDEX_BITS => INDEX_BITS
    )
    PORT MAP(
        clk => clk,
        reset_n => reset_n,
        proc_addr => proc_addr,
        proc_req => proc_req,
        proc_ready => proc_ready,
        proc_data => proc_data,
        axi_addr => axi_addr,
        axi_req => axi_req,
        axi_ready => axi_ready, -- Now connected as an output
        axi_data => axi_data,
        axi_valid => axi_valid
    );

    -- Stimulus process
    PROCESS
        VARIABLE expected_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        VARIABLE line_data : STD_LOGIC_VECTOR(DATA_WIDTH * CACHE_LINE_SIZE - 1 DOWNTO 0);
        VARIABLE offset : INTEGER;
        VARIABLE line_addr : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    BEGIN
        -- Reset sequence
        reset_n <= '0';
        WAIT FOR CLK_PERIOD * 5;
        reset_n <= '1';
        WAIT FOR CLK_PERIOD * 2;

        REPORT "Starting test sequence";

        -- Test sequence
        FOR i IN TEST_ADDRESSES'RANGE LOOP
            -- Set processor request
            proc_addr <= TEST_ADDRESSES(i);
            proc_req <= '1';

            -- Calculate expected data
            offset := to_integer(unsigned(TEST_ADDRESSES(i)(LINE_OFFSET_BITS - 1 DOWNTO 0))) / 4;
            line_addr := TEST_ADDRESSES(i)(ADDR_WIDTH - 1 DOWNTO LINE_OFFSET_BITS) & (LINE_OFFSET_BITS - 1 DOWNTO 0 => '0');
            line_data := create_test_data(TEST_ADDRESSES(i));
            expected_data := line_data((offset + 1) * DATA_WIDTH - 1 DOWNTO offset * DATA_WIDTH);

            REPORT "Test " & INTEGER'image(i) & ": Requesting address " &
                to_hex_string(TEST_ADDRESSES(i));

            -- Wait for cache to respond
            WAIT FOR CLK_PERIOD * 3;
            proc_req <= '0';

            -- Wait for cache to process
            IF axi_req = '1' THEN
                -- Cache miss detected
                REPORT "Cache miss detected";
                WAIT FOR CLK_PERIOD * 2; -- Simulate AXI latency

                -- Modified: No need to manually set axi_ready anymore
                -- Now we monitor axi_ready and respond when it is asserted

                -- Wait for axi_ready to be asserted
                WAIT UNTIL axi_ready = '1' FOR CLK_PERIOD * 10;

                IF axi_ready = '1' THEN
                    REPORT "AXI ready received from cache";

                    -- Prepare AXI data response
                    axi_data <= line_data;

                    -- Wait and then assert valid
                    WAIT FOR CLK_PERIOD * 2; -- Simulate memory access time
                    axi_valid <= '1';
                    WAIT FOR CLK_PERIOD;
                    axi_valid <= '0';
                ELSE
                    REPORT "Timeout waiting for axi_ready" SEVERITY warning;
                END IF;
            END IF;

            -- Wait for proc_ready to be asserted

            IF proc_ready = '1' THEN
                -- Check if data matches expected
                IF proc_data = expected_data THEN
                    REPORT "Test " & INTEGER'image(i) & " PASSED: Data matches expected";
                ELSE
                    REPORT "Test " & INTEGER'image(i) & " FAILED: Data mismatch" &
                        " Got: " & to_hex_string(proc_data) &
                        " Expected: " & to_hex_string(expected_data)
                        SEVERITY error;
                END IF;
            ELSE
                REPORT "Timeout waiting for proc_ready" SEVERITY error;
            END IF;

            -- Wait before next test
            WAIT FOR CLK_PERIOD * 2;
        END LOOP;

        -- End simulation
        REPORT "Test sequence completed";
        sim_done <= true;
        WAIT;
    END PROCESS;

    -- Monitor process
    PROCESS
    BEGIN
        WAIT UNTIL sim_done;
        REPORT "Simulation completed successfully";
        WAIT;
    END PROCESS;

END Behavioral;