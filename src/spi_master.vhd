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
    type state_t is (IDLE, TRANSFER);

    signal state       : state_t := IDLE;
    signal tx_shift    : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_shift    : std_logic_vector(7 downto 0) := (others => '0');
    signal sclk_reg    : std_logic := '1';
    signal mosi_reg    : std_logic := '0';
    signal cs_n_reg    : std_logic := '1';
    signal busy_reg    : std_logic := '0';
    signal data_out_reg: std_logic_vector(7 downto 0) := (others => '0');
    signal edge_count  : integer range 0 to 15 := 0;
begin
    sclk     <= sclk_reg;
    mosi     <= mosi_reg;
    cs_n     <= cs_n_reg;
    busy     <= busy_reg;
    data_out <= data_out_reg;

    process (clk, reset_n)
    begin
        if reset_n = '0' then
            state        <= IDLE;
            tx_shift     <= (others => '0');
            rx_shift     <= (others => '0');
            sclk_reg     <= '1'; -- CPOL=1: SCLK idles high in mode 3.
            mosi_reg     <= '0';
            cs_n_reg     <= '1';
            busy_reg     <= '0';
            data_out_reg <= (others => '0');
            edge_count   <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    sclk_reg <= '1';
                    cs_n_reg <= '1';
                    busy_reg <= '0';

                    if start_tx = '1' then
                        tx_shift   <= data_in;
                        rx_shift   <= (others => '0');
                        mosi_reg   <= data_in(7);
                        cs_n_reg   <= '0';
                        busy_reg   <= '1';
                        edge_count <= 0;
                        state      <= TRANSFER;
                    end if;

                when TRANSFER =>
                    if (edge_count mod 2) = 0 then
                        -- Mode 3 leading edge: falling SCLK. Data changes here.
                        sclk_reg <= '0';

                        -- The first bit is loaded before transfer. Shift only
                        -- after the first leading edge so bit 7 is not skipped.
                        if edge_count /= 0 then
                            tx_shift <= tx_shift(6 downto 0) & '0';
                            mosi_reg <= tx_shift(6);
                        end if;

                        edge_count <= edge_count + 1;
                    else
                        -- Mode 3 trailing edge: rising SCLK. Sample MISO here.
                        sclk_reg <= '1';
                        rx_shift <= rx_shift(6 downto 0) & miso;

                        if edge_count = 15 then
                            data_out_reg <= rx_shift(6 downto 0) & miso;
                            cs_n_reg     <= '1';
                            busy_reg     <= '0';
                            edge_count   <= 0;
                            state        <= IDLE;
                        else
                            edge_count <= edge_count + 1;
                        end if;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
