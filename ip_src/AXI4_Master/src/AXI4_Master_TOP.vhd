
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY AXI4_Master_TOP IS
  GENERIC (
    ADDR_WIDTH : INTEGER := 32;
    DATA_WIDTH : INTEGER := 32
  );
  PORT (
    refclk : IN STD_LOGIC;--! reference clock expect 250Mhz
    arst_n : IN STD_LOGIC;--! sync active low reset. sync -> refclk

    --! Controll ports 
    i_addr     : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    i_data     : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    i_read_req : IN STD_LOGIC;
    i_ready    : IN STD_LOGIC;

    o_data  : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    o_valid : OUT STD_LOGIC;

    --! AXI4 ports
    -- write address signals 
    -- AWID     : OUT STD_LOGIC(2 downto 0);
    -- AWADDR   : OUT STD_LOGIC_VECTOR;
    -- AWLEN    : OUT STD_LOGIC_VECTOR(7 downto 0);
    -- AWSIZE   : OUT STD_LOGIC_VECTOR(2 downto 0);
    -- AWBURST  : OUT STD_LOGIC_VECTOR(1 downto 0);
    -- AWLOCK   : OUT STD_LOGIC;
    -- AWCACHE  : OUT STD_LOGIC_VECTOR(3 downto 0);
    -- AWPROT   : OUT STD_LOGIC_VECTOR(2 downto 0);
    -- AWQOS    : OUT STD_LOGIC_VECTOR(3 downto 0);
    -- AWVALID  : OUT STD_LOGIC;
    -- AWREADY  : IN  STD_LOGIC;

    -- write data signals
    -- WID    : OUT STD_LOGIC_VECTOR;
    -- WDATA  : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    -- WSTRB  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    -- WLAST  : OUT STD_LOGIC;
    -- WVALID : OUT STD_LOGIC;
    -- WREADY : IN  STD_LOGIC;

    -- write response signals
    -- BID    : IN STD_LOGIC_VECTOR;
    -- BRESP  : IN STD_LOGIC_VECTOR(1 downto 0);
    -- BVALID : IN STD_LOGIC;
    -- BREADY : IN STD_LOGIC;

    -- read address signals 
    M_AXI_ARID    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARADDR  : OUT STD_LOGIC_VECTOR(31 downto 0);
    M_AXI_ARLEN   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    M_AXI_ARSIZE  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_ARLOCK  : OUT STD_LOGIC;
    M_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    M_AXI_ARPROT  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_ARQOS   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

    M_AXI_ARVALID : OUT STD_LOGIC;
    M_AXI_ARREADY : IN  STD_LOGIC;

    -- read data signals
    M_AXI_RID   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    M_AXI_RDATA : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    M_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    M_AXI_RLAST : IN STD_LOGIC;

    M_AXI_RVALID : IN  STD_LOGIC;
    M_AXI_RREADY : OUT STD_LOGIC

  );
END ENTITY AXI4_Master_TOP;
ARCHITECTURE rtl OF AXI4_Master_TOP IS
  TYPE control_automaton IS (st_idle, st_address, st_data);
  TYPE channel_automaton IS (st_idle, st_busy, st_done);

  SIGNAL cur_ar_state, cur_r_state          : channel_automaton;
  SIGNAL cur_r_ctrl_state, cur_w_ctrl_state : control_automaton;

  SIGNAL go_ar, go_r     : STD_LOGIC;
  SIGNAL done_ar, done_r : STD_LOGIC;

  SIGNAL data_counter : INTEGER := 0;

BEGIN
  M_AXI_ARQOS  <= (OTHERS => '0'); -- QoS  (optional)
  M_AXI_ARLOCK <= '0';             -- lock type (optional)
  M_AXI_ARPROT <= (OTHERS => '0'); -- priority of transaction (optional)
  M_AXI_ARID   <= (OTHERS => '0'); -- ID of transaction (not nessessary)

  M_AXI_ARCACHE <= (OTHERS => '0'); --memory type (will use Device Non-bufferable)

  -----------------------------------------------------------------------
  -- read automatons
  -----------------------------------------------------------------------
  read_sm_handler : PROCESS (refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF arst_n = '0' THEN
        cur_r_ctrl_state <= st_idle;
        go_ar            <= '0';
        go_r             <= '0';
      ELSE
        CASE cur_r_ctrl_state IS
          WHEN st_address =>
            go_r <= '0';
            IF done_ar = '1' THEN
              cur_r_ctrl_state <= st_data;
              go_ar            <= '0';
            ELSE
              cur_r_ctrl_state <= st_address;
              go_ar            <= '1';
            END IF;

          WHEN st_data =>
            go_ar <= '0';
            IF done_r = '1' THEN
              cur_r_ctrl_state <= st_idle;
              go_r             <= '0';
            ELSE
              cur_r_ctrl_state <= st_data;
              go_r             <= '1';
            END IF;

          WHEN OTHERS =>
            go_ar <= '0';
            go_r  <= '0';
            IF i_read_req = '1' THEN
              cur_r_ctrl_state <= st_address;
            ELSE
              cur_r_ctrl_state <= st_idle;
            END IF;
        END CASE;
      END IF;
    END IF;
  END PROCESS;

  address_read_channel : PROCESS (refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF arst_n = '0' THEN
        cur_ar_state  <= st_idle;
        M_AXI_ARADDR  <= (OTHERS => '0');
        M_AXI_ARLEN   <= (OTHERS => '0');
        M_AXI_ARSIZE  <= (OTHERS => '0');
        M_AXI_ARBURST <= (OTHERS => '0');
        M_AXI_ARVALID <= '0';
        done_ar       <= '0';

      ELSE
        CASE cur_ar_state IS
          WHEN st_busy =>
            done_ar       <= '0';
            M_AXI_ARADDR  <= i_addr;
            M_AXI_ARLEN   <=  std_logic_vector(to_unsigned (63, 8)); -- IN VHDL2008 : 8D"63";    -- from docs : "Burst_Length = AxLEN[7:0] + 1, to accommodate the extended burst length of the INCR burst type in AXI4"
            M_AXI_ARSIZE  <= B"101"; -- 32-bit bus
            M_AXI_ARBURST <= B"01";  -- increment address on every data burst
            M_AXI_ARVALID <= '1';
            IF M_AXI_ARREADY = '1' THEN
              cur_ar_state <= st_done;
            ELSE
              cur_ar_state <= st_busy;
            END IF;

          WHEN st_done =>
            M_AXI_ARADDR  <= (OTHERS => '0');
            M_AXI_ARLEN   <= (OTHERS => '0');
            M_AXI_ARSIZE  <= (OTHERS => '0');
            M_AXI_ARBURST <= (OTHERS => '0');
            M_AXI_ARVALID <= '0';
            done_ar       <= '1';
            cur_ar_state  <= st_idle;

          WHEN OTHERS => -- define it as idle 
            M_AXI_ARADDR  <= (OTHERS => '0');
            M_AXI_ARLEN   <= (OTHERS => '0');
            M_AXI_ARSIZE  <= (OTHERS => '0');
            M_AXI_ARBURST <= (OTHERS => '0');
            M_AXI_ARVALID <= '0';
            IF go_ar = '1' THEN
              cur_ar_state <= st_busy;
            ELSE
              cur_ar_state <= st_idle;
            END IF;
        END CASE;

      END IF;
    END IF;
  END PROCESS;

  read_data_channel : PROCESS (refclk)
  BEGIN
    IF rising_edge(refclk) THEN
      IF arst_n = '0' THEN
        cur_r_state  <= st_idle;
        M_AXI_RREADY <= '0';
        o_data       <= (OTHERS => '0');
        o_valid      <= '0';
        data_counter <= 0;
        done_r      <= '0';
      ELSE
        CASE cur_r_state IS
          WHEN st_busy =>
            done_r      <= '0';
            M_AXI_RREADY <= '0';
            IF data_counter < 64 THEN
              IF M_AXI_RVALID = '1' AND M_AXI_RRESP /= "10" AND M_AXI_RRESP /= "11" then
                IF i_ready ='1' then
                  M_AXI_RREADY <= '1';
                  o_data       <= M_AXI_RDATA;
                  o_valid      <= '1';
                  data_counter <= data_counter + 1;
                ELSE
                  M_AXI_RREADY <= '0';
                  o_data       <= M_AXI_RDATA;
                  o_valid      <= '1';
                END IF;
                IF M_AXI_RLAST = '1' then
                  cur_r_state <= st_done;
                ELSE
                  cur_r_state <= st_busy;
                END IF;
              ELSE
                M_AXI_RREADY <= '0';
                o_data       <= (OTHERS => '0');
                o_valid      <= '0';
              END IF;
            ELSE
              cur_r_state  <= st_done;
              M_AXI_RREADY <= '0';
              o_data       <= (OTHERS => '0');
              o_valid      <= '0';
            END IF;

          WHEN st_done =>
            M_AXI_RREADY <= '0';
            o_data       <= (OTHERS => '0');
            o_valid      <= '0';
            data_counter <= 0;
            done_r      <= '1';
            cur_r_state  <= st_idle;

          WHEN OTHERS =>
            M_AXI_RREADY <= '0';
            o_data       <= (OTHERS => '0');
            o_valid      <= '0';
            data_counter <= 0;
            done_r      <= '0';
            IF go_r = '1' THEN
              cur_r_state <= st_busy;
            ELSE
              cur_r_state <= st_idle;
            END IF;

        END CASE;

      END IF;
    END IF;
  END PROCESS;

  ------------------------------------------------------------------------
  -- END read automatons
  ------------------------------------------------------------------------

END ARCHITECTURE rtl;
