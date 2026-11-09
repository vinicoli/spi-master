# Instruções para agentes de código

- Trate SemVer e Conventional Commits como convenções obrigatórias deste projeto.
- Antes de alterar a versão, leia `VERSION` e `CONTRIBUTING.md`. `fix` incrementa PATCH, `feat` incrementa MINOR e uma mudança incompatível incrementa MAJOR. Alterações `docs`, `test`, `refactor` e `chore` não incrementam versão por si só.
- Ao criar commits, mantenha o prefixo Conventional Commit no início e coloque um emoji depois dos dois-pontos, por exemplo: `refactor: 🔧 make IDLE outputs explicit`.
- Atualize `VERSION` e crie uma tag anotada `vMAJOR.MINOR.PATCH` somente ao preparar uma release. Nunca mova uma tag existente sem solicitação explícita.
- Preserve a interface SPI e os pressupostos funcionais documentados em `README.md` e `PLANO_PROJETO_SPI_MASTER.md`, salvo quando o pedido solicitar mudança.
- Em VHDL, nomeie processos e use encerramentos nomeados para entidade, arquitetura e processo.
