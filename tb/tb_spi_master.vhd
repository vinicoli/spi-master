library ieee;
use ieee.std_logic_1164.all;

entity tb_spi_master is
end entity tb_spi_master;

architecture sim of tb_spi_master is
    signal clk      : std_logic := '0';
    signal reset_n  : std_logic := '0';
    signal start_tx : std_logic := '0';
    signal data_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal miso     : std_logic := '0';
    signal sclk     : std_logic;
    signal mosi     : std_logic;
    signal cs_n     : std_logic;
    signal busy     : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
begin
    clk <= not clk after 5 ns;

    dut : entity work.spi_master(rtl)
        port map (
            clk      => clk,
            reset_n  => reset_n,
            start_tx => start_tx,
            data_in  => data_in,
            miso     => miso,
            sclk     => sclk,
            mosi     => mosi,
            cs_n     => cs_n,
            busy     => busy,
            data_out => data_out
        );

    sclk_clock_relation : process
        variable previous_sclk : std_logic := '1';
        variable previous_cs_n : std_logic := '1';
    begin
        loop
            wait until rising_edge(clk);
            wait for 1 ns;

            if reset_n = '0' then
                previous_sclk := sclk;
                previous_cs_n := cs_n;
            else
                if previous_cs_n = '0' then
                    assert sclk /= previous_sclk
                        report "SCLK must toggle on every reference-clock edge during a transfer"
                        severity failure;
                end if;
                previous_sclk := sclk;
                previous_cs_n := cs_n;
            end if;
        end loop;
    end process sclk_clock_relation;

    stimulus : process
        variable tx_byte : std_logic_vector(7 downto 0);
        variable rx_byte : std_logic_vector(7 downto 0);
    begin
        -- Asynchronous reset and mode-3 idle levels.
        reset_n <= '0';
        wait for 20 ns;
        assert busy = '0' and cs_n = '1' and sclk = '1'
            report "Reset must leave busy low, CS inactive, and SCLK high" severity failure;
        assert data_out = x"00"
            report "Reset must clear data_out" severity failure;
        reset_n <= '1';
        wait until rising_edge(clk);

        -- Transaction 1: also pulse start_tx while busy to verify it is ignored.
        tx_byte := x"A5";
        rx_byte := x"3C";
        data_in <= tx_byte;
        wait until falling_edge(clk);
        start_tx <= '1';
        wait until rising_edge(clk);
        start_tx <= '0';
        wait until busy = '1';
        assert cs_n = '0' and sclk = '1'
            report "CS must assert while SCLK remains at its mode-3 idle level" severity failure;

        wait until falling_edge(sclk);
        miso <= rx_byte(7);
        wait for 1 ns;
        assert mosi = tx_byte(7)
            report "Transaction 1 transmitted an incorrect MSB" severity failure;

        -- A request on the following half-cycle is ignored while busy.
        wait until falling_edge(clk);
        data_in <= x"FF";
        start_tx <= '1';
        wait until rising_edge(clk);
        start_tx <= '0';
        wait for 1 ns;
        assert busy = '1' and cs_n = '0' and data_out = x"00"
            report "The busy request must be ignored without ending the active transfer" severity failure;

        for bit_index in 6 downto 0 loop
            wait until falling_edge(sclk);
            miso <= rx_byte(bit_index);
            wait for 1 ns;
            assert mosi = tx_byte(bit_index)
                report "Transaction 1 transmitted an incorrect bit" severity failure;

            wait until rising_edge(sclk);
            wait for 1 ns;
            if bit_index /= 0 then
                assert busy = '1' and cs_n = '0' and data_out = x"00"
                    report "Transfer ended or data_out changed before the final sample" severity failure;
            end if;
        end loop;

        assert busy = '0' and cs_n = '1' and sclk = '1'
            report "Transaction 1 must finish with busy low, CS inactive, and SCLK high" severity failure;
        assert data_out = rx_byte
            report "Transaction 1 received an incorrect byte" severity failure;
        wait until rising_edge(clk);
        assert busy = '0' and cs_n = '1'
            report "A start pulse while busy must not queue another transaction" severity failure;

        -- Transaction 2: distinct patterns verify shifting and data_out retention.
        tx_byte := x"96";
        rx_byte := x"C3";
        data_in <= tx_byte;
        wait until falling_edge(clk);
        start_tx <= '1';
        wait until rising_edge(clk);
        start_tx <= '0';
        wait until busy = '1';
        assert data_out = x"3C"
            report "data_out must retain the previous completed byte while busy" severity failure;

        for bit_index in 7 downto 0 loop
            wait until falling_edge(sclk);
            miso <= rx_byte(bit_index);
            wait for 1 ns;
            assert mosi = tx_byte(bit_index)
                report "Transaction 2 transmitted an incorrect bit" severity failure;

            wait until rising_edge(sclk);
            wait for 1 ns;
            if bit_index /= 0 then
                assert busy = '1' and cs_n = '0' and data_out = x"3C"
                    report "Transaction 2 ended early or changed data_out too soon" severity failure;
            end if;
        end loop;

        assert busy = '0' and cs_n = '1' and sclk = '1' and data_out = x"C3"
            report "Transaction 2 did not complete with the expected result" severity failure;

        -- Reset during a third transfer must abort it and restore idle outputs.
        data_in <= x"55";
        wait until falling_edge(clk);
        start_tx <= '1';
        wait until rising_edge(clk);
        start_tx <= '0';
        wait until busy = '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset_n <= '0';
        wait for 1 ns;
        assert busy = '0' and cs_n = '1' and sclk = '1' and mosi = '0'
            report "Reset during transfer must abort and restore idle outputs" severity failure;
        assert data_out = x"00"
            report "Asynchronous reset must clear data_out" severity failure;

        wait for 10 ns;
        reset_n <= '1';
        wait until rising_edge(clk);
        assert busy = '0' and cs_n = '1' and sclk = '1'
            report "DUT must remain idle after reset release" severity failure;

        report "All SPI master testbench checks passed" severity note;
        wait;
    end process;
end architecture sim;
