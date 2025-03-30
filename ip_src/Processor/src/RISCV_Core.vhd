LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY riscv_core IS
    GENERIC (
        ADDR_WIDTH : INTEGER := 32;
        DATA_WIDTH : INTEGER := 32;
        REG_ADDR_WIDTH : INTEGER := 5;
        RESET_ACTIVE_AT : STD_LOGIC := '1' -- '1' for active-high, '0' for active-low
    );
    PORT (
        -- Clock and Reset
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC; -- Use RESET_ACTIVE_AT to determine polarity internally

        -- Instruction Cache Interface (Processor side)
        icache_proc_addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        icache_proc_req : OUT STD_LOGIC; -- Request TO ICache
        icache_proc_ready : IN STD_LOGIC; -- Ready FROM ICache
        icache_proc_data : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END ENTITY riscv_core;

ARCHITECTURE pipeline OF riscv_core IS

    -- == Constants ==
    CONSTANT NOP_INSTRUCTION : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := x"00000013"; -- addi x0, x0, 0

    -- == Signals Connecting Stages ==

    -- IF Stage Outputs -> IF/ID Registers
    SIGNAL if_pc_out : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL if_instr : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL if_valid : STD_LOGIC;
    SIGNAL if_cache_req : STD_LOGIC; -- Internal signal for IF stage cache request

    -- IF/ID Register Outputs -> ID Stage Inputs
    SIGNAL if_id_pc : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL if_id_instr : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL if_id_valid : STD_LOGIC := '0';

    -- ID Stage Outputs -> ID/EX Registers
    SIGNAL dec_opcode : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL dec_funct3 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL dec_funct7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL dec_rs1 : STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL dec_rs2 : STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL dec_rd : STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL dec_imm : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL rf_read_data1 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL rf_read_data2 : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Control Signals from Control Unit
    SIGNAL ctrl_reg_write_enable : STD_LOGIC;
    SIGNAL ctrl_branch_taken : STD_LOGIC;
    SIGNAL ctrl_alu_sel_b : STD_LOGIC;
    SIGNAL ctrl_wb_sel_pc4 : STD_LOGIC;
    SIGNAL ctrl_is_jump : STD_LOGIC;
    SIGNAL ctrl_is_jalr : STD_LOGIC;

    -- ID/EX Register Outputs -> EX Stage Inputs
    SIGNAL id_ex_pc : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL id_ex_rs1_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL id_ex_rs2_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL id_ex_imm : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL id_ex_rd : STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL id_ex_funct3 : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL id_ex_funct7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL id_ex_valid : STD_LOGIC := '0';
    -- Pipelined Control Signals
    SIGNAL id_ex_reg_write_enable : STD_LOGIC;
    SIGNAL id_ex_branch_taken_ctrl : STD_LOGIC;
    SIGNAL id_ex_alu_sel_b : STD_LOGIC;
    SIGNAL id_ex_wb_sel_pc4 : STD_LOGIC;
    SIGNAL id_ex_is_jump_ctrl : STD_LOGIC;
    SIGNAL id_ex_is_jalr_ctrl : STD_LOGIC;
    -- Intermediate signal for alu_sel_b conversion
    SIGNAL id_ex_alu_sel_b_vec : STD_LOGIC_VECTOR(0 DOWNTO 0);
    -- EX Stage Internal Signals (UNSIGNED as defined in execute entity)
    SIGNAL u_exe_alu_out : unsigned(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL u_exe_pc_branch : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL u_exe_link_address : unsigned(DATA_WIDTH - 1 DOWNTO 0);
    -- EX Stage Outputs -> EX/WB Registers (converted to std_logic_vector)
    SIGNAL exe_alu_out : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL exe_link_address : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL exe_pc_branch : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL exe_zero_flag : STD_LOGIC;
    SIGNAL ex_take_branch_jump : STD_LOGIC;
    SIGNAL ex_target_pc : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);

    -- EX/WB Register Outputs -> WB Stage Inputs
    SIGNAL ex_wb_alu_out : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL ex_wb_link_address : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL ex_wb_rd : STD_LOGIC_VECTOR(REG_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL ex_wb_valid : STD_LOGIC := '0';
    -- Pipelined Control Signals
    SIGNAL ex_wb_reg_write_enable : STD_LOGIC;
    SIGNAL ex_wb_sel_pc4 : STD_LOGIC;

    -- WB Stage Outputs -> Register File Write Port
    SIGNAL wb_write_data : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    -- Hazard / Stall / Flush Signals
    SIGNAL internal_reset : STD_LOGIC;
    SIGNAL pipeline_stall : STD_LOGIC;
    SIGNAL if_id_flush : STD_LOGIC;
    SIGNAL id_ex_flush : STD_LOGIC;

    -- Connect IF stage back to itself for branch control
    SIGNAL if_stall_in : STD_LOGIC;
    SIGNAL if_branch_taken_in : STD_LOGIC;
    SIGNAL if_pc_branch_in : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);

BEGIN

    internal_reset <= rst WHEN RESET_ACTIVE_AT = '1' ELSE
        NOT rst;

    -- == Hazard / Control Logic ==

    -- Stall the subsequent pipeline stages if ICache is not ready AND IF is requesting
    pipeline_stall <= '1' WHEN (if_cache_req = '1' AND icache_proc_ready = '0') ELSE '0';

    -- Flush IF/ID and ID/EX stages if a branch or jump is taken in the EX stage
    if_id_flush <= ex_take_branch_jump;
    id_ex_flush <= ex_take_branch_jump;

    -- Stall signal for IF stage and pipeline registers
    if_stall_in <= pipeline_stall;

    -- Branch/Jump control feedback to IF stage
    if_branch_taken_in <= ex_take_branch_jump;
    if_pc_branch_in <= ex_target_pc;

    -- ========================
    --      Pipeline Stages
    -- ========================

    -- ------------------------
    --      IF Stage
    -- ------------------------
    instruction_fetch_unit : ENTITY work.instruction_fetch
        GENERIC MAP(
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        PORT MAP(
            clk => clk,
            reset => internal_reset,
            stall => if_stall_in,
            pc_branch => if_pc_branch_in,
            branch_taken => if_branch_taken_in,
            cache_addr => icache_proc_addr,
            cache_req => if_cache_req,
            cache_ready => icache_proc_ready,
            cache_data => icache_proc_data,
            instr => if_instr,
            pc_out => if_pc_out,
            valid => if_valid
        );
    -- Drive the top-level output port from the internal signal
    icache_proc_req <= if_cache_req;

    -- ------------------------
    --      IF/ID Registers
    -- ------------------------
    if_id_reg_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF internal_reset = '1' THEN
                if_id_instr <= NOP_INSTRUCTION;
                if_id_pc <= (OTHERS => '0');
                if_id_valid <= '0';
            ELSIF pipeline_stall = '1' THEN
                NULL; -- Stall: No change
            ELSIF if_id_flush = '1' THEN
                if_id_instr <= NOP_INSTRUCTION;
                if_id_pc <= (OTHERS => '0');
                if_id_valid <= '0';
            ELSE
                if_id_instr <= if_instr;
                if_id_pc <= if_pc_out; -- Latch changing PC
                if_id_valid <= if_valid;
            END IF;
        END IF;
    END PROCESS if_id_reg_proc;

    -- ------------------------
    --      ID Stage
    -- ------------------------
    instruction_decode_unit : ENTITY work.instruction_decoder
        PORT MAP(
            i_instruction => if_id_instr,
            o_opcode => dec_opcode,
            o_funct3 => dec_funct3,
            o_funct7 => dec_funct7,
            o_source1 => dec_rs1,
            o_source2 => dec_rs2,
            o_dest => dec_rd,
            o_immediate => dec_imm
        );

    register_file_unit : ENTITY work.register_file
        GENERIC MAP(
            DATA_WIDTH => DATA_WIDTH,
            REG_ADDR_WIDTH => REG_ADDR_WIDTH
        )
        PORT MAP(
            clk => clk,
            rst => internal_reset,
            read_addr1 => dec_rs1,
            read_data1 => rf_read_data1,
            read_addr2 => dec_rs2,
            read_data2 => rf_read_data2,
            write_enable => ex_wb_reg_write_enable,
            write_addr => ex_wb_rd,
            write_data => wb_write_data
        );

    control_unit_inst : ENTITY work.control_unit
        PORT MAP(
            i_opcode => dec_opcode,
            i_funct3 => dec_funct3,
            i_funct7 => dec_funct7,
            i_zero_flag => exe_zero_flag,
            o_reg_write_enable => ctrl_reg_write_enable,
            o_branch_taken => ctrl_branch_taken,
            o_alu_sel_b => ctrl_alu_sel_b,
            o_wb_sel_pc4 => ctrl_wb_sel_pc4,
            o_is_jump => ctrl_is_jump
        );

    ctrl_is_jalr <= '1' WHEN dec_opcode = "1100111" ELSE
        '0';

    -- ------------------------
    --      ID/EX Registers
    -- ------------------------
    id_ex_reg_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF internal_reset = '1' THEN
                id_ex_pc <= (OTHERS => '0');
                id_ex_rs1_data <= (OTHERS => '0');
                id_ex_rs2_data <= (OTHERS => '0');
                id_ex_imm <= (OTHERS => '0');
                id_ex_rd <= (OTHERS => '0');
                id_ex_funct3 <= (OTHERS => '0');
                id_ex_funct7 <= (OTHERS => '0');
                id_ex_valid <= '0';
                id_ex_reg_write_enable <= '0';
                id_ex_branch_taken_ctrl <= '0';
                id_ex_alu_sel_b <= '0';
                id_ex_wb_sel_pc4 <= '0';
                id_ex_is_jump_ctrl <= '0';
                id_ex_is_jalr_ctrl <= '0';
            ELSIF pipeline_stall = '1' THEN
                NULL; -- Stall: No change
            ELSIF id_ex_flush = '1' THEN
                id_ex_pc <= (OTHERS => '0');
                id_ex_rs1_data <= (OTHERS => '0');
                id_ex_rs2_data <= (OTHERS => '0');
                id_ex_imm <= (OTHERS => '0');
                id_ex_rd <= (OTHERS => '0');
                id_ex_funct3 <= "000"; -- Funct3 for ADDI (NOP)
                id_ex_funct7 <= (OTHERS => '0');
                id_ex_valid <= '0'; -- Mark as invalid/bubble
                id_ex_reg_write_enable <= '0';
                id_ex_branch_taken_ctrl <= '0';
                id_ex_alu_sel_b <= '1'; -- NOP uses immediate
                id_ex_wb_sel_pc4 <= '0';
                id_ex_is_jump_ctrl <= '0';
                id_ex_is_jalr_ctrl <= '0';
            ELSIF if_id_valid = '1' THEN
                id_ex_pc <= if_id_pc;
                id_ex_rs1_data <= rf_read_data1;
                id_ex_rs2_data <= rf_read_data2;
                id_ex_imm <= dec_imm;
                id_ex_rd <= dec_rd;
                id_ex_funct3 <= dec_funct3;
                id_ex_funct7 <= dec_funct7;
                id_ex_valid <= '1';
                id_ex_reg_write_enable <= ctrl_reg_write_enable;
                id_ex_branch_taken_ctrl <= ctrl_branch_taken;
                id_ex_alu_sel_b <= ctrl_alu_sel_b;
                id_ex_wb_sel_pc4 <= ctrl_wb_sel_pc4;
                id_ex_is_jump_ctrl <= ctrl_is_jump;
                id_ex_is_jalr_ctrl <= ctrl_is_jalr;
            ELSE
                id_ex_valid <= '0';
                id_ex_reg_write_enable <= '0';
                id_ex_branch_taken_ctrl <= '0';
                id_ex_is_jump_ctrl <= '0';
                id_ex_is_jalr_ctrl <= '0';
                id_ex_rd <= (OTHERS => '0');
                id_ex_alu_sel_b <= '0';
                id_ex_wb_sel_pc4 <= '0';
            END IF;
        END IF;
    END PROCESS id_ex_reg_proc;

    id_ex_alu_sel_b_vec(0) <= id_ex_alu_sel_b;

    -- ------------------------
    --      EX Stage
    -- ------------------------
    execute_unit : ENTITY work.execute
        GENERIC MAP(
            DW => DATA_WIDTH,
            F3W => 3,
            F7W => 7,
            SW => 1
        )
        PORT MAP(
            alu_sel_b => unsigned(id_ex_alu_sel_b_vec),
            funct3 => unsigned(id_ex_funct3),
            funct7 => unsigned(id_ex_funct7),
            pc => unsigned(id_ex_pc),
            reg_a => unsigned(id_ex_rs1_data),
            reg_b => unsigned(id_ex_rs2_data),
            imm => unsigned(id_ex_imm),
            alu_out => u_exe_alu_out,
            writedata => OPEN,
            pc_branch => u_exe_pc_branch,
            link_address => u_exe_link_address,
            zero_flag => exe_zero_flag
        );

    exe_alu_out <= STD_LOGIC_VECTOR(u_exe_alu_out);
    exe_pc_branch <= STD_LOGIC_VECTOR(u_exe_pc_branch);
    exe_link_address <= STD_LOGIC_VECTOR(u_exe_link_address);

    ex_take_branch_jump <= (id_ex_branch_taken_ctrl OR id_ex_is_jump_ctrl) AND id_ex_valid;
    ex_target_pc <= exe_alu_out WHEN id_ex_is_jalr_ctrl = '1' AND id_ex_valid = '1' ELSE
        exe_pc_branch;

    -- ------------------------
    --      EX/WB Registers
    -- ------------------------
    ex_wb_reg_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF internal_reset = '1' THEN
                ex_wb_alu_out <= (OTHERS => '0');
                ex_wb_link_address <= (OTHERS => '0');
                ex_wb_rd <= (OTHERS => '0');
                ex_wb_valid <= '0';
                ex_wb_reg_write_enable <= '0';
                ex_wb_sel_pc4 <= '0';
            ELSIF id_ex_valid = '1' THEN -- Latch if EX stage received valid data
                ex_wb_alu_out <= exe_alu_out;
                ex_wb_link_address <= exe_link_address;
                ex_wb_rd <= id_ex_rd;
                ex_wb_valid <= '1';
                ex_wb_reg_write_enable <= id_ex_reg_write_enable;
                ex_wb_sel_pc4 <= id_ex_wb_sel_pc4;
            ELSE
                ex_wb_valid <= '0'; -- Propagate invalidity
                ex_wb_reg_write_enable <= '0';
                ex_wb_rd <= (OTHERS => '0');
                ex_wb_sel_pc4 <= '0';
            END IF;
        END IF;
    END PROCESS ex_wb_reg_proc;

    -- ------------------------
    --      WB Stage
    -- ------------------------
    writeback_unit : ENTITY work.writeback
        GENERIC MAP(
            DATA_WIDTH => DATA_WIDTH
        )
        PORT MAP(
            wb_sel_pc4 => ex_wb_sel_pc4,
            ex_alu_result => ex_wb_alu_out,
            ex_link_address => ex_wb_link_address,
            wb_write_data => wb_write_data
        );

END ARCHITECTURE pipeline;