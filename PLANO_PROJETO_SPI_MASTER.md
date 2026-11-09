# Projeto acadêmico: SPI Master em VHDL

## Objetivo

Projetar, documentar e simular um mestre SPI full-duplex de 8 bits usando VHDL, Quartus II e ModelSim. O escopo atual é a validação por simulação; não há placa FPGA nem atribuição de pinos definida.

## Especificação

- **Modo SPI:** modo 3 (`CPOL=1`, `CPHA=1`). `SCLK` permanece alto em repouso. O mestre muda `MOSI` na borda de descida (leading edge) e amostra `MISO` na borda de subida (trailing edge).
- **Tamanho e ordem:** 8 bits, MSB primeiro, full-duplex.
- **Clock:** `clk` é a referência. A saída Moore `sclk` alterna a cada transição entre os estados de fase, portanto `SCLK = clk/2` durante a transferência. A preparação mantém `CS` baixo e `SCLK` alto antes da primeira descida; a 16ª transição é a subida final e encerra a transferência.
- **Seleção do escravo:** `cs_n` é ativo baixo e fica baixo durante a transferência.
- **Início e ocupação:** `start_tx` é amostrado em `clk` quando o bloco está ocioso. É esperado como pulso de um ciclo. Solicitações durante `busy='1'` são ignoradas, sem fila.
- **Conclusão:** `busy` fica alto durante a transferência e retorna a zero após a oitava amostra de `MISO`. `data_out` é atualizado nesse instante e mantém a última palavra concluída até outra conclusão ou reset.
- **Reset:** `reset_n` é assíncrono e ativo baixo. O reset coloca `sclk` alto, `cs_n` alto, `busy` baixo e limpa `data_out`.

## Interface do componente

| Direção | Sinal | Descrição |
|---|---|---|
| Entrada | `clk` | Clock de referência do sistema. |
| Entrada | `reset_n` | Reset assíncrono ativo baixo. |
| Entrada | `start_tx` | Pulso de início, aceito somente em repouso. |
| Entrada | `data_in[7:0]` | Byte a transmitir, MSB primeiro. |
| Entrada | `miso` | Bit serial recebido do escravo. |
| Saída | `sclk` | Clock SPI modo 3, frequência `clk/2`. |
| Saída | `mosi` | Bit serial enviado ao escravo. |
| Saída | `cs_n` | Chip select ativo baixo. |
| Saída | `busy` | Indica transferência em curso. |
| Saída | `data_out[7:0]` | Byte recebido, válido ao fim da transferência. |

## Máquina de estados Moore

O RTL usa dois processos nomeados. `p_state_register` registra o estado e atualiza os registradores do datapath. `p_next_state_outputs` é combinacional: calcula `next_state` e decodifica `sclk`, `cs_n` e `busy` exclusivamente a partir do estado atual. `mosi` vem do registrador de transmissão e `data_out` do registrador de recepção; esses são sinais de dados, não sinais de controle da FSM.

1. **IDLE:** `SCLK=1`, `CS_n=1`, `busy=0`. Aceita `start_tx` e captura o byte de transmissão.
2. **PREPARE:** `SCLK=1`, `CS_n=0`, `busy=1`. Mantém a seleção ativa antes da primeira borda e apresenta o MSB em `MOSI`.
3. **SCLK_FALL:** `SCLK=0`, `CS_n=0`, `busy=1`. O bit de `MOSI` fica estável; na transição para a fase alta, o datapath captura o bit de `MISO`.
4. **SCLK_RISE:** `SCLK=1`, `CS_n=0`, `busy=1`. Para bits não finais, prepara o próximo bit e retorna a `SCLK_FALL`. No oitavo bit, `SCLK_FALL` vai diretamente a `IDLE`: essa transição produz a subida final, captura o último `MISO`, publica a palavra e desativa `CS`/`busy`.

`SCLK_FALL` e `SCLK_RISE` alternam a cada borda de subida de `clk`. O MSB é carregado em `PREPARE`; depois de cada amostra não final, o registrador TX avança um bit para que o próximo valor de `MOSI` acompanhe a descida seguinte. Solicitações de início fora de `IDLE` não alteram a sequência.

## Diagramas

- [Diagrama de bloco](docs/diagrama_bloco.svg)
- [Diagrama da FSM](docs/diagrama_fsm.svg)

## Arquivos de implementação

- RTL: `src/spi_master.vhd`
- Testbench: `tb/tb_spi_master.vhd`
- Script ModelSim: `sim/run.do`
- Convenções de commit e release: [CONTRIBUTING.md](CONTRIBUTING.md)
- Versão da release corrente: `VERSION`

## Simulação no ModelSim

Abra o terminal do ModelSim no diretório raiz do projeto e execute:

```tcl
do sim/run.do
```

O script compila RTL e testbench em VHDL-93, abre a simulação, adiciona os sinais à janela de ondas, executa por 2 µs e encerra. A mensagem `All SPI master testbench checks passed` indica que as verificações passaram; qualquer `assertion failure` indica falha.

O testbench verifica reset em repouso e durante transferência, a preparação de `CS`, a relação `SCLK = clk/2`, transmissão e recepção de dois padrões, ordem MSB-first, manutenção de `data_out` durante uma transferência, duração de `busy`, seleção `cs_n` e ignorar `start_tx` durante ocupação.

## Uso no Quartus II

Adicione `src/spi_master.vhd` ao projeto Quartus como arquivo VHDL e selecione-o como entidade de topo (`spi_master`) para análise/síntese. Atribuições de pinos e configuração de dispositivo dependem da placa que vier a ser usada e não fazem parte deste projeto de simulação.
