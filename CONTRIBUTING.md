# Contribuindo com o projeto

## Formato de commit

Use o formato Conventional Commits:

```text
<tipo>[escopo opcional][!]: <descrição curta>

[corpo opcional]

[rodapé opcional, por exemplo BREAKING CHANGE: ...]
```

Tipos usados neste projeto:

- `feat`: adiciona uma capacidade observável.
- `fix`: corrige um defeito.
- `refactor`: reorganiza o código sem alterar o comportamento externo.
- `docs`: altera documentação.
- `test`: altera testbench ou validações.
- `chore`: manutenção, configuração e ferramentas do repositório.
- `build` e `ci`: alterações de compilação ou integração contínua.

Exemplos:

```text
feat: add configurable transfer length
fix: sample MISO on the mode 3 trailing edge
refactor: separate Moore state and output processes
docs: explain the SPI timing diagram
```

Use `!` no tipo/escopo ou o rodapé `BREAKING CHANGE:` para indicar uma alteração incompatível.

## Versionamento semântico

`VERSION` registra a versão da release corrente. As releases seguem `MAJOR.MINOR.PATCH`, e cada release recebe uma tag Git anotada no formato `vMAJOR.MINOR.PATCH`.

- `fix` incrementa PATCH.
- `feat` incrementa MINOR.
- Uma alteração incompatível (`!` ou `BREAKING CHANGE:`) incrementa MAJOR.
- `docs`, `test`, `refactor`, `chore`, `build` e `ci` não incrementam a versão por si só.

Ao preparar uma release, atualize `VERSION`, registre a mudança em um commit Conventional Commit apropriado e crie a tag anotada correspondente. A versão inicial do projeto é `0.1.0`; a tag baseline `v0.1.0` identifica o estado inicial versionado.
