LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY register_file IS
    GENERIC (
        DATA_WIDTH : INTEGER := 32;
        REG_ADDR_WIDTH : INTEGER := 5
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Read Port 1
        read_addr1 : IN STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
        read_data1 : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

        -- Read Port 2
        read_addr2 : IN STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
        read_data2 : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

        -- Write Port
        write_enable : IN STD_LOGIC;
        write_addr : IN STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
        write_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END ENTITY register_file;

ARCHITECTURE behavioral OF register_file IS

    -- Register file storage type
    CONSTANT NUM_REGS : INTEGER := 2 ** REG_ADDR_WIDTH;
    TYPE reg_array_t IS ARRAY (0 TO NUM_REGS - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL regs : reg_array_t := (OTHERS => (OTHERS => '0'));

    -- Internal signals for read addresses converted to integer
    SIGNAL i_read_addr1 : NATURAL RANGE 0 TO NUM_REGS - 1;
    SIGNAL i_read_addr2 : NATURAL RANGE 0 TO NUM_REGS - 1;
    SIGNAL i_write_addr : NATURAL RANGE 0 TO NUM_REGS - 1;

BEGIN

    -- Address conversion
    i_read_addr1 <= to_integer(unsigned(read_addr1));
    i_read_addr2 <= to_integer(unsigned(read_addr2));
    i_write_addr <= to_integer(unsigned(write_addr));

    -- Write Process (Synchronous)
    write_proc : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            regs <= (OTHERS => (OTHERS => '0')); -- Reset all registers to 0
        ELSIF rising_edge(clk) THEN
            IF write_enable = '1' THEN
                -- Ensure x0 (register 0) is never written
                IF i_write_addr /= 0 THEN
                    regs(i_write_addr) <= write_data;
                END IF;
            END IF;
        END IF;
    END PROCESS write_proc;

    read_data1 <= (OTHERS => '0') WHEN i_read_addr1 = 0 ELSE
        regs(i_read_addr1);

    read_data2 <= (OTHERS => '0') WHEN i_read_addr2 = 0 ELSE
        regs(i_read_addr2);

END ARCHITECTURE behavioral;