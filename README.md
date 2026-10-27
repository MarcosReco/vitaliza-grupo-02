# Projeto Vitaliza · grupo 02

A Vitaliza é um app de assinatura para quem treina. Este projeto estuda a saída de
assinantes (churn): quem sai, por quê e em quem vale a pena agir.
Data de corte da análise: 30/09/2026.

## Pastas

| Pasta | Conteúdo |
|-------|----------|
| `docs/` | Enunciado do case e dicionário de dados. |
| `dados/brutos/` | Arquivos originais do data room. Não alterar, mover ou apagar. |
| `dados/processados/` | Tabelas intermediárias geradas pela limpeza e pelas junções. |
| `notebooks/` | Notebooks de exploração e análise. |
| `src/` | Código Python reutilizável (funções de leitura, limpeza etc.). |
| `saidas/` | Resultados finais: tabelas, gráficos e relatórios. |

A pasta `dados/` não vai para o Git (ver `.gitignore`). Cada integrante guarda os
arquivos localmente.

## Arquivos na raiz

- `AGENTS.md`: regras do projeto para agentes de IA (e para o grupo).
- `CLAUDE.md`: aponta para o `AGENTS.md`.
- `decisoes.md`: registro de toda decisão de limpeza, com motivo, critério e linhas afetadas.
- `.gitignore`: o que fica fora do repositório (dados, `.env`, ambiente virtual, caches).
