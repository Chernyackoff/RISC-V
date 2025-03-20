LIBRARY IEEE;                        -- standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;           -- standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;             -- for the signed, unsigned types and arithmetic ops

ENTITY regfile IS
  PORT (
    refclk       : IN  STD_LOGIC;
    we           : IN  STD_LOGIC;                     -- write enable
    ra1, ra2, wa : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);  -- read addr 1, read addr 2, write addr
    wd           : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); -- write data
    rd1, rd2     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)  -- read data 1, read data 2
  );
END ENTITY regfile;

ARCHITECTURE rtl OF regfile IS
  TYPE reg_arr_t IS ARRAY (31 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL memory : reg_arr_t;
BEGIN
  -- Write Process
  write : PROCESS (refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF we = '1' THEN
        memory(to_integer(unsigned(wa))) <= wd;
      END IF;
    END IF;
  END PROCESS;

  -- Read Process
  read : PROCESS (ra1, ra2)
  BEGIN
    IF (to_integer(unsigned(ra1)) = 0) THEN
      rd1 <= X"00000000";  -- Use <= for signal assignment
    ELSE
      rd1 <= memory(to_integer(unsigned(ra1)));
    END IF;

    IF (to_integer(unsigned(ra2)) = 0) THEN
      rd2 <= X"00000000";  -- Use <= for signal assignment
    ELSE
      rd2 <= memory(to_integer(unsigned(ra2)));
    END IF;
  END PROCESS;
END ARCHITECTURE rtl;
