# SPI Master in VHDL / SPI Master em VHDL

## English

An academic project implementing an 8-bit full-duplex SPI master in VHDL. It is organized to study the interface, Moore state machine, and testbench-based validation.

Author: [Vinícius Oliveira](https://github.com/vinicoli).

| Protocol | Word | FSM | Version |
|---|---:|---|---:|
| SPI mode 3 (`CPOL=1`, `CPHA=1`) | 8 bits, MSB first | Moore, 4 states | `0.1.0` |

> The testbench is included; functional execution still needs confirmation in a compatible ModelSim environment.

### What this project demonstrates

- Simultaneous transmission and reception of one byte.
- `SCLK` generation from the reference clock without a divider input: `SCLK = clk/2` during a transfer.
- Active-low slave selection through `cs_n`.
- A Moore FSM with one state signal and two processes: one sequential process for state/datapath and one combinational process for control-output decoding.
- A testbench with a simulated SPI slave to check serial sequencing and control cases.

### Architecture

#### Block diagram

![SPI Master block diagram](docs/diagrama_bloco.svg)

#### Interface

| Direction | Signal | Description |
|---|---|---|
| Input | `clk` | System reference clock. |
| Input | `reset_n` | Active-low asynchronous reset. |
| Input | `start_tx` | One-cycle pulse to start a transfer; accepted only when `busy='0'`. |
| Input | `data_in[7:0]` | Byte to transmit, MSB first. |
| Input | `miso` | Serial bit received from the slave. |
| Output | `sclk` | SPI mode 3 clock; idles high. |
| Output | `mosi` | Serial bit sent to the slave. |
| Output | `cs_n` | Active-low chip select. |
| Output | `busy` | Indicates that a transfer is in progress. |
| Output | `data_out[7:0]` | Received byte; updated when the transfer completes. |

There is no `done` signal: completion is indicated when `busy` returns to zero. `data_out` holds the last completed byte until the next transfer or reset. A `start_tx` request while `busy='1'` is ignored; commands are not queued.

#### SPI timing

In mode 3, `SCLK` idles high (`CPOL=1`) and data is sampled on the rising edge (`CPHA=1`). The master presents/advances `MOSI` on the falling edge and samples `MISO` on the rising edge. `cs_n` is asserted before the first falling edge and deasserted with the final rising edge.

#### Moore state machine

![SPI Master Moore FSM](docs/diagrama_fsm.svg)

| State | `sclk` | `cs_n` | `busy` | Action |
|---|---:|---:|---:|---|
| `IDLE` | 1 | 1 | 0 | Waits for `start_tx` and captures `data_in`. |
| `PREPARE` | 1 | 0 | 1 | Selects the slave and prepares the first bit. |
| `SCLK_FALL` | 0 | 0 | 1 | Presents the transmit bit; captures `miso` on transition to the high phase. |
| `SCLK_RISE` | 1 | 0 | 1 | Holds the high phase and prepares the next bit, when present. |

The control signals `sclk`, `cs_n`, and `busy` are decoded only from the current state. `mosi` and `data_out` belong to the datapath and come from shift registers.

### Repository layout

```text
.
├── AGENTS.md                   # persistent instructions for coding agents
├── src/spi_master.vhd          # SPI master entity and RTL
├── tb/tb_spi_master.vhd        # testbench with simulated SPI slave
├── sim/run.do                  # ModelSim compile and run script
├── docs/diagrama_bloco.svg     # interface and internal blocks
├── docs/diagrama_fsm.svg       # states and transitions
├── PLANO_PROJETO_SPI_MASTER.md # detailed project specification
├── CONTRIBUTING.md             # Conventional Commits and SemVer
└── VERSION                     # current version: 0.1.0
```

### ModelSim simulation

The script compiles the RTL and testbench as VHDL-93, loads the simulation, adds signals to the wave window, and runs for 2 µs. From the project root, in the ModelSim prompt, run:

```tcl
do sim/run.do
```

The `All SPI master testbench checks passed` message indicates that the checks passed. An `assertion failure` identifies the failed check.

The testbench covers:

- Reset and idle output levels after reset, as well as reset during a transfer.
- Mode 3 idle levels and `cs_n` setup.
- `sclk` transitions relative to `clk`.
- Transmitted/received byte pairs `A5`/`3C` and `96`/`C3`, MSB first.
- `data_out` retention during a transfer.
- Ignoring `start_tx` while busy.

### Quartus II

Create a Quartus project, add `src/spi_master.vhd` as a VHDL file, and set `spi_master` as the top-level entity. FPGA device selection and pin assignments depend on the target board and are not included.

### Versioning

The project uses SemVer and Conventional Commits. The current version is `0.1.0`; rules and examples are in [CONTRIBUTING.md](CONTRIBUTING.md). Project history and the initial [`v0.1.0`](https://github.com/vinicoli/spi-master/tree/v0.1.0) tag are on GitHub.

---

## Português

Projeto acadêmico de um mestre SPI full-duplex de 8 bits, implementado em VHDL. Está organizado para estudo da interface, da máquina de estados Moore e da validação por testbench.

Autor: [Vinícius Oliveira](https://github.com/vinicoli).

| Protocolo | Palavra | FSM | Versão |
|---|---:|---|---:|
| SPI modo 3 (`CPOL=1`, `CPHA=1`) | 8 bits, MSB primeiro | Moore, 4 estados | `0.1.0` |

> O testbench está incluído; a execução funcional ainda precisa ser confirmada em um ambiente ModelSim compatível.

### O que este projeto demonstra

- Transmissão e recepção simultâneas de um byte.
- Geração de `SCLK` a partir do clock de referência, sem entrada de divisor: `SCLK = clk/2` durante uma transferência.
- Seleção do escravo ativa em nível baixo por meio de `cs_n`.
- FSM Moore com um único sinal de estado e dois processos: um sequencial para estado/datapath e um combinacional para decodificar as saídas de controle.
- Testbench com um escravo SPI simulado para conferir a sequência serial e os casos de controle.

### Arquitetura

#### Diagrama de bloco

![Diagrama de bloco do SPI Master](docs/diagrama_bloco.svg)

#### Interface

| Direção | Sinal | Descrição |
|---|---|---|
| Entrada | `clk` | Clock de referência do sistema. |
| Entrada | `reset_n` | Reset assíncrono ativo baixo. |
| Entrada | `start_tx` | Pulso de um ciclo para iniciar uma transferência; aceito somente quando `busy='0'`. |
| Entrada | `data_in[7:0]` | Byte a transmitir, MSB primeiro. |
| Entrada | `miso` | Bit serial recebido do escravo. |
| Saída | `sclk` | Clock SPI modo 3; repousa alto. |
| Saída | `mosi` | Bit serial enviado ao escravo. |
| Saída | `cs_n` | Chip Select ativo baixo. |
| Saída | `busy` | Indica que uma transferência está em andamento. |
| Saída | `data_out[7:0]` | Byte recebido; atualizado ao final da transferência. |

Não há sinal `done`: a conclusão é indicada por `busy` voltando a zero. `data_out` mantém o último byte concluído até a próxima transferência ou reset. Um pedido `start_tx` recebido enquanto `busy='1'` é ignorado; não há fila de comandos.

#### Temporização SPI

No modo 3, `SCLK` fica alto em repouso (`CPOL=1`) e os dados são amostrados na borda de subida (`CPHA=1`). O mestre apresenta/avança `MOSI` na borda de descida e amostra `MISO` na borda de subida. `cs_n` é ativado antes da primeira descida e desativado junto à subida final.

#### Máquina de estados Moore

![Diagrama da FSM Moore do SPI Master](docs/diagrama_fsm.svg)

| Estado | `sclk` | `cs_n` | `busy` | Ação |
|---|---:|---:|---:|---|
| `IDLE` | 1 | 1 | 0 | Aguarda `start_tx` e captura `data_in`. |
| `PREPARE` | 1 | 0 | 1 | Ativa o escravo e prepara o primeiro bit. |
| `SCLK_FALL` | 0 | 0 | 1 | Apresenta o bit de transmissão; captura `miso` na transição para a fase alta. |
| `SCLK_RISE` | 1 | 0 | 1 | Mantém a fase alta e prepara o próximo bit, quando houver. |

Os sinais de controle `sclk`, `cs_n` e `busy` são decodificados somente a partir do estado atual. `mosi` e `data_out` pertencem ao datapath e vêm dos registradores de deslocamento.

### Estrutura do repositório

```text
.
├── AGENTS.md                   # instruções permanentes para agentes de código
├── src/spi_master.vhd          # entidade e RTL do mestre SPI
├── tb/tb_spi_master.vhd        # testbench com escravo SPI simulado
├── sim/run.do                  # script de compilação e execução no ModelSim
├── docs/diagrama_bloco.svg     # interface e blocos internos
├── docs/diagrama_fsm.svg       # estados e transições
├── PLANO_PROJETO_SPI_MASTER.md # especificação detalhada do projeto
├── CONTRIBUTING.md             # Conventional Commits e SemVer
└── VERSION                     # versão atual: 0.1.0
```

### Simulação no ModelSim

O script compila o RTL e o testbench em VHDL-93, carrega a simulação, adiciona os sinais à janela de ondas e executa por 2 µs. A partir da raiz do projeto, no prompt do ModelSim, execute:

```tcl
do sim/run.do
```

A mensagem `All SPI master testbench checks passed` indica que as verificações passaram. Um `assertion failure` identifica a verificação que falhou.

O testbench cobre:

- Reset e níveis de repouso após reset, além de reset durante uma transferência.
- Níveis de repouso do modo 3 e preparação de `cs_n`.
- Transições de `sclk` em relação a `clk`.
- Pares de bytes transmitido/recebido `A5`/`3C` e `96`/`C3`, MSB primeiro.
- Retenção de `data_out` durante a transferência.
- Ignorar `start_tx` enquanto ocupado.

### Quartus II

Crie um projeto Quartus, adicione `src/spi_master.vhd` como arquivo VHDL e defina `spi_master` como entidade de topo. A seleção do dispositivo FPGA e as atribuições de pinos dependem da placa utilizada e não estão incluídas.

### Versionamento

O projeto usa SemVer e Conventional Commits. A versão atual é `0.1.0`; as regras e os exemplos estão em [CONTRIBUTING.md](CONTRIBUTING.md). O histórico do projeto e a tag inicial [`v0.1.0`](https://github.com/vinicoli/spi-master/tree/v0.1.0) estão no GitHub.
