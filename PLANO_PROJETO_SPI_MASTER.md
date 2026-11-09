# Projeto acadêmico: SPI Master em VHDL

## Objetivo

Projetar, documentar e simular um mestre SPI full-duplex de 8 bits usando VHDL, Quartus II e ModelSim. O escopo atual é a validação por simulação; não há placa FPGA nem atribuição de pinos definida.

## Especificação

- **Modo SPI:** modo 3 (`CPOL=1`, `CPHA=1`). `SCLK` permanece alto em repouso. O mestre muda `MOSI` na borda de descida (leading edge) e amostra `MISO` na borda de subida (trailing edge).
- **Tamanho e ordem:** 8 bits, MSB primeiro, full-duplex.
- **Clock:** `clk` é a referência. O registrador de saída alterna `sclk` a cada borda de subida de `clk`, portanto `SCLK = clk/2`. Uma palavra exige 16 ciclos de referência ativos, além dos ciclos de preparação e encerramento.
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

## Máquina de estados

O RTL usa dois estados:

1. **IDLE:** mantém `SCLK` alto, `CS` inativo e `busy` baixo. Ao aceitar `start_tx`, captura `data_in`, prepara o bit mais significativo, zera o registrador de recepção, ativa `CS` e inicia a contagem.
2. **TRANSFER:** alterna `SCLK` em cada borda de subida de `clk`. Nas descidas de `SCLK`, avança `MOSI` para o próximo bit; nas subidas, desloca `MISO` para o registrador de recepção. Na oitava subida, publica `data_out`, desativa `CS` e limpa `busy`.

O contador de bordas percorre 16 transições: oito descidas para apresentar os bits e oito subidas para amostrá-los. A primeira borda de descida mantém o MSB apresentado durante a preparação, evitando descartar o primeiro bit.

## Diagramas

- [Diagrama de bloco](docs/diagrama_bloco.svg)
- [Diagrama da FSM](docs/diagrama_fsm.svg)

## Arquivos de implementação

- RTL: `src/spi_master.vhd`
- Testbench: `tb/tb_spi_master.vhd`
- Script ModelSim: `sim/run.do`

## Simulação no ModelSim

Abra o terminal do ModelSim no diretório raiz do projeto e execute:

```tcl
do sim/run.do
```

O script compila RTL e testbench em VHDL-93, abre a simulação, adiciona os sinais à janela de ondas, executa por 2 µs e encerra. A mensagem `All SPI master testbench checks passed` indica que as verificações passaram; qualquer `assertion failure` indica falha.

O testbench verifica reset em repouso e durante transferência, níveis de repouso do modo 3, transmissão e recepção de dois padrões, ordem MSB-first, manutenção de `data_out` durante uma transferência, duração de `busy`, seleção `cs_n` e ignorar `start_tx` durante ocupação.

## Uso no Quartus II

Adicione `src/spi_master.vhd` ao projeto Quartus como arquivo VHDL e selecione-o como entidade de topo (`spi_master`) para análise/síntese. Atribuições de pinos e configuração de dispositivo dependem da placa que vier a ser usada e não fazem parte deste projeto de simulação.
