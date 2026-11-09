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
    signal next_state    : state_t := IDLE;
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
            state <= next_state;

            case state is
                when IDLE =>
                    if start_tx = '1' then
                        tx_shift  <= data_in;
                        rx_shift  <= (others => '0');
                        bit_count <= 0;
                    end if;

                when PREPARE =>
                    null;

                when SCLK_FALL =>
                    -- MISO is sampled as the FSM leaves SCLK_FALL and
                    -- enters SCLK_RISE (the mode-3 trailing edge).
                    rx_shift <= rx_shift(6 downto 0) & miso;
                    if bit_count = 7 then
                        data_out_reg <= rx_shift(6 downto 0) & miso;
                    end if;

                when SCLK_RISE =>
                    if bit_count < 7 then
                        tx_shift  <= tx_shift(6 downto 0) & '0';
                        bit_count <= bit_count + 1;
                    end if;
            end case;
        end if;
    end process p_state_register;

    p_next_state_outputs : process (state, start_tx, bit_count)
    begin
        next_state   <= state;
        sclk_control <= '1';
        cs_n_control <= '1';
        busy_control <= '0';

        case state is
            when IDLE =>
                if start_tx = '1' then
                    next_state <= PREPARE;
                end if;

            when PREPARE =>
                sclk_control <= '1';
                cs_n_control <= '0';
                busy_control <= '1';
                next_state   <= SCLK_FALL;

            when SCLK_FALL =>
                sclk_control <= '0';
                cs_n_control <= '0';
                busy_control <= '1';
                if bit_count = 7 then
                    next_state <= IDLE;
                else
                    next_state <= SCLK_RISE;
                end if;

            when SCLK_RISE =>
                sclk_control <= '1';
                cs_n_control <= '0';
                busy_control <= '1';
                next_state   <= SCLK_FALL;
        end case;
    end process p_next_state_outputs;
end architecture rtl;
