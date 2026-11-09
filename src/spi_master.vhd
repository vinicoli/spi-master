library ieee;
use ieee.std_logic_1164.all;

entity spi_master is
    port (
        clk      : in  std_logic;
        reset_n  : in  std_logic;
        start_tx : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        miso     : in  std_logic;
        sclk     : out std_logic;
        mosi     : out std_logic;
        cs_n     : out std_logic;
        busy     : out std_logic;
        data_out : out std_logic_vector(7 downto 0)
    );
end entity spi_master;

architecture rtl of spi_master is
    type state_t is (IDLE, PREPARE, SCLK_FALL, SCLK_RISE);

    signal state         : state_t := IDLE;
    signal tx_shift      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_shift      : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count     : integer range 0 to 7 := 0;
    signal sclk_control  : std_logic := '1';
    signal cs_n_control  : std_logic := '1';
    signal busy_control  : std_logic := '0';
begin
    sclk     <= sclk_control;
    mosi     <= tx_shift(7);
    cs_n     <= cs_n_control;
    busy     <= busy_control;
    data_out <= data_out_reg;

    p_state_register : process (clk, reset_n)
    begin
        if reset_n = '0' then
            state        <= IDLE;
            tx_shift     <= (others => '0');
            rx_shift     <= (others => '0');
            data_out_reg <= (others => '0');
            bit_count    <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start_tx = '1' then
                        state     <= PREPARE;
                        tx_shift  <= data_in;
                        rx_shift  <= (others => '0');
                        bit_count <= 0;
                    end if;

                when PREPARE =>
                    state <= SCLK_FALL;

                when SCLK_FALL =>
                    -- MISO is sampled as the FSM leaves SCLK_FALL; the
                    -- Moore decode raises SCLK in the destination state.
                    rx_shift <= rx_shift(6 downto 0) & miso;
                    if bit_count = 7 then
                        data_out_reg <= rx_shift(6 downto 0) & miso;
                        state        <= IDLE;
                    else
                        state <= SCLK_RISE;
                    end if;

                when SCLK_RISE =>
                    if bit_count < 7 then
                        tx_shift  <= tx_shift(6 downto 0) & '0';
                        bit_count <= bit_count + 1;
                        state     <= SCLK_FALL;
                    else
                        -- Defensive recovery for an inconsistent phase/count.
                        state     <= IDLE;
                        tx_shift  <= (others => '0');
                        rx_shift  <= (others => '0');
                        bit_count <= 0;
                    end if;

                when others =>
                    -- Abort an invalid state and return the datapath to idle.
                    state     <= IDLE;
                    tx_shift  <= (others => '0');
                    rx_shift  <= (others => '0');
                    bit_count <= 0;
            end case;
        end if;
    end process p_state_register;

    p_output_logic : process (state)
    begin
        -- Safe Moore defaults are the IDLE output levels.
        sclk_control <= '1';
        cs_n_control <= '1';
        busy_control <= '0';

        case state is
            when IDLE =>
                sclk_control <= '1'; -- CPOL=1: SCLK rests high in mode 3.
                cs_n_control <= '1';
                busy_control <= '0';

            when PREPARE =>
                cs_n_control <= '0';
                busy_control <= '1';

            when SCLK_FALL =>
                sclk_control <= '0';
                cs_n_control <= '0';
                busy_control <= '1';

            when SCLK_RISE =>
                cs_n_control <= '0';
                busy_control <= '1';

            when others =>
                -- Keep the external control pins at their idle levels.
                sclk_control <= '1';
                cs_n_control <= '1';
                busy_control <= '0';
        end case;
    end process p_output_logic;
end architecture rtl;
