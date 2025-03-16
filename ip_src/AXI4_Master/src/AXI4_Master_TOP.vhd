
LIBRARY IEEE;--! standard library IEEE (Institute of Electrical and Electronics Engineers)
USE IEEE.std_logic_1164.ALL;--! standard unresolved logic UX01ZWLH-
USE IEEE.numeric_std.ALL;--! for the signed, unsigned types and arithmetic ops

ENTITY AXI4_Master_TOP IS
  GENERIC (
    ADDR_WIDTH : INTEGER = 32;
    DATA_WIDTH : INTEGER = 32;
  );
  PORT (
    refclk : IN STD_LOGIC;--! reference clock expect 250Mhz
    arst_n : IN STD_LOGIC;--! sync active low reset. sync -> refclk

    --! Controll ports 
    i_rw    : IN STD_LOGIC;
    i_addr  : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0)
    i_data  : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    i_req   : IN STD_LOGIC;
    i_ready : IN STD_LOGIC;

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
    ARID     : OUT STD_LOGIC_VECTOR(2 downto 0);
    ARADDR   : OUT STD_LOGIC_VECTOR;
    ARLEN    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ARSIZE   : OUT STD_LOGIC_VECTOR(2 downto 0);
    ARBURST  : OUT STD_LOGIC_VECTOR(1 downto 0);
    ARLOCK   : OUT STD_LOGIC;
    ARCACHE  : OUT STD_LOGIC_VECTOR(3 downto 0);
    ARPROT   : OUT STD_LOGIC_VECTOR(2 downto 0);
    ARQOS    : OUT STD_LOGIC_VECTOR(3 downto 0); 

    ARVALID  : OUT STD_LOGIC;
    ARREADY  : IN  STD_LOGIC;

    -- read data signals
    RID    : IN  STD_LOGIC_VECTOR(2 downto 0);
    RDATA  : IN  STD_LOGIC_VECTOR(DATAWIDTH - 1 DOWNTO 0);
    RRESP  : IN  STD_LOGIC_VECTOR(1 downto 0);
    RLAST  : IN  STD_LOGIC;

    RVALID : IN  STD_LOGIC;
    RREADY : OUT STD_LOGIC

  );
END ENTITY AXI4_Master_TOP;
ARCHITECTURE rtl OF AXI4_Master_TOP IS
BEGIN
END ARCHITECTURE rtl;
