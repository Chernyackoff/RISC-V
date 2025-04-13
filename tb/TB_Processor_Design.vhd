library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

entity Processor_Design_tb is
end entity Processor_Design_tb;

architecture behavioral of Processor_Design_tb is

    component Processor_Design_wrapper is
        port (
            clk   : in std_logic;
            rst_n : in std_logic
        );
    end component Processor_Design_wrapper;

    signal clk_tb   : std_logic := '0';
    signal rst_n_tb : std_logic;

    constant CLK_FREQ_HZ : real    := 250_000_000.0;
    constant CLK_PERIOD  : time    := 1 sec / CLK_FREQ_HZ;

    signal sim_stop : boolean := false;

begin

    UUT : component Processor_Design_wrapper
        port map (
            clk   => clk_tb,
            rst_n => rst_n_tb
        );

    clk_process : process
    begin
        if not sim_stop then
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        else
            wait;
        end if;
    end process clk_process;

    stim_proc : process
    begin
        report "Testbench: Starting simulation.";

        rst_n_tb <= '0';
        report "Testbench: Reset Asserted (rst_n = 0)";
        wait for CLK_PERIOD * 20;

        rst_n_tb <= '1';
        report "Testbench: Reset De-asserted (rst_n = 1)";
        wait for CLK_PERIOD * 5;

        report "Testbench: Processor released from reset. Running program...";

        wait for 10 us;

        report "Testbench: Simulation time limit reached. Stopping simulation." severity note;
        sim_stop <= true;
        wait;

    end process stim_proc;

end architecture behavioral;