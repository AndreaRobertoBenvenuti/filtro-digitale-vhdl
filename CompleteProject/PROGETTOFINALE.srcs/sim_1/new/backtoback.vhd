-- TB for Back-to-Back Operations with Different Parameters
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
 
entity tb_back_to_backSBAGLIATO is
end tb_back_to_backSBAGLIATO;
 
architecture project_tb_arch of tb_back_to_backSBAGLIATO is

    constant CLOCK_PERIOD : time := 20 ns;

    -- Signals to be connected to the component
    signal tb_clk : std_logic := '0';
    signal tb_rst, tb_start, tb_done : std_logic;
    signal tb_add : std_logic_vector(15 downto 0);
 
    -- Signals for the memory
    signal tb_o_mem_addr, exc_o_mem_addr, init_o_mem_addr : std_logic_vector(15 downto 0);
    signal tb_o_mem_data, exc_o_mem_data, init_o_mem_data : std_logic_vector(7 downto 0);
    signal tb_i_mem_data : std_logic_vector(7 downto 0);
    signal tb_o_mem_we, tb_o_mem_en, exc_o_mem_we, exc_o_mem_en, init_o_mem_we, init_o_mem_en : std_logic;

    -- Memory
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);
    signal RAM : ram_type := (OTHERS => "00000000");
 
    -- Scenario 1: Order 3 filter
    type scenario_config_type is array (0 to 16) of integer;
    constant SCENARIO1_LENGTH : integer := 12;
    constant SCENARIO1_LENGTH_STL : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(SCENARIO1_LENGTH, 16));
    type scenario_type is array (0 to 31) of integer; -- Larger to accommodate all scenarios
    
    signal scenario1_config : scenario_config_type := (to_integer(unsigned(SCENARIO1_LENGTH_STL(15 downto 8))),   -- K1
                                                      to_integer(unsigned(SCENARIO1_LENGTH_STL(7 downto 0))),     -- K2
                                                      0,                                                         -- S (Order 3)
                                                      0, -1, 8, 0, -8, 1, 0, 1, -9, 45, 0, -45, 9, -1            -- C1-C14
                                                     );
    signal scenario1_input : scenario_type := (32, -24, -35, 0, 46, -54, -39, -22, -53, -47, 12, 11, 
                                              others => 0);
    signal scenario1_output : scenario_type := (11, 43, -13, -54, 33, 53, -28, 8, 18, -38, -32, 10, 5,
                                               others => 0);

    -- Scenario 2: Order 5 filter
    constant SCENARIO2_LENGTH : integer := 10;
    constant SCENARIO2_LENGTH_STL : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(SCENARIO2_LENGTH, 16));
    
    signal scenario2_config : scenario_config_type := (to_integer(unsigned(SCENARIO2_LENGTH_STL(15 downto 8))),   -- K1
                                                      to_integer(unsigned(SCENARIO2_LENGTH_STL(7 downto 0))),     -- K2
                                                      1,                                                         -- S (Order 5)
                                                     0, -1, 8, 0, -8, 1, 0, 1, -9, 45, 0, -45, 9, -1             -- C1-C14 (different from scenario 1)
                                                     );
    signal scenario2_input : scenario_type := (50, -30, 20, 15, -40, 60, -25, 10, 5, -15,
                                              others => 0);
    signal scenario2_output : scenario_type := (24, 24, -47, 59, -40, -11, 43, -34, 23, 1, -11, 2,
                                               others => 0);
                                               
    -- Scenario 3: Another Order 3 filter with different coefficients
    constant SCENARIO3_LENGTH : integer := 8;
    constant SCENARIO3_LENGTH_STL : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(SCENARIO3_LENGTH, 16));
    
    signal scenario3_config : scenario_config_type := (to_integer(unsigned(SCENARIO3_LENGTH_STL(15 downto 8))),   -- K1
                                                      to_integer(unsigned(SCENARIO3_LENGTH_STL(7 downto 0))),     -- K2
                                                      0,                                                         -- S (Order 3)
                                                      1, -2, 10, 0, -10, 2, -1, 0, 0, 0, 0, 0, 0, 0               -- C1-C14 (different coefficients)
                                                     );
    signal scenario3_input : scenario_type := (15, 25, -20, 30, -15, 45, -10, 5,
                                              others => 0);
    signal scenario3_output : scenario_type := (-23, 32, -7, 0, -10, -7, 33, -13, 5,
                                               others => 0);
 
    signal memory_control : std_logic := '0';      -- A signal to decide when the memory is accessed
                                                   -- by the testbench or by the project
 
    constant SCENARIO1_ADDRESS : integer := 1000;    -- Addresses for different scenarios
    constant SCENARIO2_ADDRESS : integer := 2000;
    constant SCENARIO3_ADDRESS : integer := 3000;
 
    component project_reti_logiche is
        port (
                i_clk : in std_logic;
                i_rst : in std_logic;
                i_start : in std_logic;
                i_add : in std_logic_vector(15 downto 0);
 
                o_done : out std_logic;
 
                o_mem_addr : out std_logic_vector(15 downto 0);
                i_mem_data : in  std_logic_vector(7 downto 0);
                o_mem_data : out std_logic_vector(7 downto 0);
                o_mem_we   : out std_logic;
                o_mem_en   : out std_logic
        );
    end component project_reti_logiche;
 
begin
    UUT : project_reti_logiche
    port map(
                i_clk   => tb_clk,
                i_rst   => tb_rst,
                i_start => tb_start,
                i_add   => tb_add,
 
                o_done => tb_done,
 
                o_mem_addr => exc_o_mem_addr,
                i_mem_data => tb_i_mem_data,
                o_mem_data => exc_o_mem_data,
                o_mem_we   => exc_o_mem_we,
                o_mem_en   => exc_o_mem_en
    );
 
    -- Clock generation
    tb_clk <= not tb_clk after CLOCK_PERIOD/2;
 
    -- Process related to the memory
    MEM : process (tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if tb_o_mem_en = '1' then
                if tb_o_mem_we = '1' then
                    RAM(to_integer(unsigned(tb_o_mem_addr))) <= tb_o_mem_data after 1 ns;
                    tb_i_mem_data <= tb_o_mem_data after 1 ns;
                else
                    tb_i_mem_data <= RAM(to_integer(unsigned(tb_o_mem_addr))) after 1 ns;
                end if;
            end if;
        end if;
    end process;
 
    memory_signal_swapper : process(memory_control, init_o_mem_addr, init_o_mem_data,
                                    init_o_mem_en,  init_o_mem_we,   exc_o_mem_addr,
                                    exc_o_mem_data, exc_o_mem_en, exc_o_mem_we)
    begin
        -- This is necessary for the testbench to work: we swap the memory
        -- signals from the component to the testbench when needed.
 
        tb_o_mem_addr <= init_o_mem_addr;
        tb_o_mem_data <= init_o_mem_data;
        tb_o_mem_en   <= init_o_mem_en;
        tb_o_mem_we   <= init_o_mem_we;
 
        if memory_control = '1' then
            tb_o_mem_addr <= exc_o_mem_addr;
            tb_o_mem_data <= exc_o_mem_data;
            tb_o_mem_en   <= exc_o_mem_en;
            tb_o_mem_we   <= exc_o_mem_we;
        end if;
    end process;
 
    -- This process provides the correct scenario on the signal controlled by the TB
    create_scenario : process
        -- Helper procedure to load a scenario into memory
        procedure load_scenario(
            address : in integer;
            config : in scenario_config_type;
            input : in scenario_type;
            length : in integer
        ) is
        begin
            -- Load configuration
            for i in 0 to 16 loop
                init_o_mem_addr <= std_logic_vector(to_unsigned(address + i, 16));
                init_o_mem_data <= std_logic_vector(to_signed(config(i), 8));
                init_o_mem_en   <= '1';
                init_o_mem_we   <= '1';
                wait until rising_edge(tb_clk);   
            end loop;
            
            -- Load input data
            for i in 0 to length-1 loop
                init_o_mem_addr <= std_logic_vector(to_unsigned(address + 17 + i, 16));
                init_o_mem_data <= std_logic_vector(to_signed(input(i), 8));
                init_o_mem_en   <= '1';
                init_o_mem_we   <= '1';
                wait until rising_edge(tb_clk);   
            end loop;
        end procedure;
        
        -- Helper procedure to run a scenario and wait for completion
        procedure run_scenario(address : in integer) is
        begin
            memory_control <= '1';  -- Memory controlled by the component
            tb_add <= std_logic_vector(to_unsigned(address, 16));
            tb_start <= '1';
            
            wait until tb_done = '1';
            wait for 5 ns;
            tb_start <= '0';
            
            wait until tb_done = '0';
            wait for 5 ns;
        end procedure;
        
        -- Helper procedure to verify a scenario's output
        procedure verify_scenario(
            address : in integer;
            output : in scenario_type;
            length : in integer;
            scenario_num : in integer
        ) is
        begin
            for i in 0 to length-1 loop
                assert RAM(address + 17 + length + i) = std_logic_vector(to_signed(output(i), 8)) 
                    report "Scenario " & integer'image(scenario_num) & " TEST FAILED @ OFFSET=" & 
                           integer'image(i) & " expected=" & integer'image(output(i)) & 
                           " actual=" & integer'image(to_integer(signed(RAM(address + 17 + length + i)))) 
                    severity failure;
            end loop;
            report "Scenario " & integer'image(scenario_num) & " TEST PASSED";
        end procedure;
        
    begin
        wait for 50 ns;
 
        -- Signal initialization and reset of the component
        tb_start <= '0';
        tb_add <= (others=>'0');
        tb_rst <= '1';
 
        -- Wait some time for the component to reset...
        wait for 50 ns;
 
        tb_rst <= '0';
        memory_control <= '0';  -- Memory controlled by the testbench
 
        wait until falling_edge(tb_clk); -- Skew the testbench transitions with respect to the clock
 
        -- Load all scenarios into memory
        load_scenario(SCENARIO1_ADDRESS, scenario1_config, scenario1_input, SCENARIO1_LENGTH);
        load_scenario(SCENARIO2_ADDRESS, scenario2_config, scenario2_input, SCENARIO2_LENGTH);
        load_scenario(SCENARIO3_ADDRESS, scenario3_config, scenario3_input, SCENARIO3_LENGTH);
 
        wait until falling_edge(tb_clk);
        
        -- RUN SCENARIO 1
        run_scenario(SCENARIO1_ADDRESS);
        
        -- RUN SCENARIO 2 (no reset between scenarios)
        run_scenario(SCENARIO2_ADDRESS);
        
        -- Reset before scenario 3
        tb_rst <= '1';
        wait for 50 ns;
        tb_rst <= '0';
        wait for 10 ns;
        
        -- RUN SCENARIO 3
        run_scenario(SCENARIO3_ADDRESS);
        
        -- Verify all scenarios
        memory_control <= '0';
        verify_scenario(SCENARIO1_ADDRESS, scenario1_output, SCENARIO1_LENGTH, 1);
        verify_scenario(SCENARIO2_ADDRESS, scenario2_output, SCENARIO2_LENGTH, 2);
        verify_scenario(SCENARIO3_ADDRESS, scenario3_output, SCENARIO3_LENGTH, 3);
        
        assert false report "All Back-to-Back Tests Passed!" severity failure;
        wait;
    end process;
end architecture;
