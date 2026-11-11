# Limpeza de Base

Registro do processo de limpeza da base da Vitaliza, em ordem cronológica. O objetivo é deixar
claro **por que** cada passo foi dado, e não só o que foi feito. As decisões pontuais (motivo,
critério e número de linhas) ficam também no [`decisoes.md`](../decisoes.md).

---

## Etapa 1 · Partir da pergunta de negócio

**Pergunta.** A limpeza atende ao objetivo 1 do enunciado, *contar e medir a base*: quantos
assinantes pagantes ativos a Vitaliza tinha no corte (30/09/2026), quanto ela perde por mês e
como isso varia por plano e por canal.

**Princípio adotado.** Limpar não significa deixar a base "bonita". Significa deixá-la capaz de
responder a essa pergunta. Cada correção, remoção ou marcação precisa se justificar pelo efeito
na contagem de assinantes ou na medida de churn.

**Referência para conferir o resultado.** O enunciado traz os números oficiais, que servem de
teste para a limpeza:

| Indicador | Valor no enunciado |
| :-- | --: |
| Assinantes pagantes ativos em 30/09/2026 | 14.753 |
| Churn médio mensal em 2025 | 5,6% |
| Churn médio mensal jan–set/2026 | 6,6% |
| Abril/2026 (pior mês) | 1.154 perdas ÷ 14.237 ativos = 8,1% |

Se a base limpa não reproduzir esses números, alguma regra está errada.

---

## Etapa 2 · Definir os conceitos antes de abrir os dados

Antes de qualquer código, o grupo escreveu a definição operacional dos dois conceitos da
pergunta. A primeira versão foi revisada contra o enunciado e o dicionário de dados.

### "Assinante pagante ativo na data X"

| Primeira versão | Problema | Versão final |
| :-- | :-- | :-- |
| Não desligou a renovação, não está no teste de 7 dias e não usa a versão grátis | O enunciado diz que, entre o aviso "renovação desligada" e o aviso "expirou", a pessoa **continua assinante**: já pagou pelo período. Excluí-la subestima a base | Tem um período **pago** (não teste) que cobre a data X, com ou sem renovação automática ligada |

### "Churn do mês"

| Primeira versão | Problema | Versão final |
| :-- | :-- | :-- |
| A data em que a pessoa clica em cancelar | Contradiz a definição do enunciado (assinaturas *perdidas*); para 70% da base (lojas) a Vitaliza nem vê o clique; o cancelamento pode ser desfeito; no plano anual anteciparia a perda em até 11 meses | O período pago terminou dentro do mês e não foi renovado (evento `assinatura_expirada`) |

### Teste de estresse do conceito

O grupo questionou por que uma assinatura cancelada e ainda não expirada conta como ativa.
Argumentos a favor:

1. **A receita do período já entrou**; a empresa ainda não perdeu nada (e continua pagando o
   custo de servir, R$ 4,20/mês).
2. **O cancelamento é reversível**: existe o evento `renovacao_automatica_religada`.
3. **O plano anual distorceria a série**: a perda cairia meses antes de acontecer.
4. **É a definição usada no enunciado.**

O contra-argumento é legítimo e foi mantido: para **agir**, o clique é o momento que importa.
Por isso o grupo trabalha com dois conceitos, que não devem ser misturados na mesma conta:

| | Churn efetivo | Intenção de cancelar |
| :-- | :-- | :-- |
| Evento | `assinatura_expirada` | `renovacao_automatica_desligada` / `cancelamento_web` |
| Natureza | Indicador atrasado (o fato) | Indicador antecipado (o sinal) |
| Uso no case | Objetivo 1: medir a base | Objetivos 4 e 6: prever e agir |

**Confirmação no dicionário.** A seção 11 registra 289 respostas à pesquisa de saída de pessoas
que cancelaram pelo site e *seguiam ativas* em 30/09/2026, porque o período pago terminava depois
do corte. O acesso até o fim do período vale, portanto, para os dois canais. O dicionário também
informa que a série mensal de churn conta **só quem estava ativo no início do mês**.

**Pontos em aberto** (o dicionário não detalha; a decidir na etapa de contagem):
- `reembolso` e `chargeback`: o acesso termina na hora ou no fim do período?
- `periodo_carencia`: a pessoa conta como ativa durante a nova tentativa de cobrança?

---

## Etapa 3 · Escolher os arquivos

A pergunta pede só dois dos 12 arquivos do data room (o `AGENTS.md` do grupo proíbe processar o
data room inteiro de uma vez):

| Arquivo | O que é | Por que sozinho não basta |
| :-- | :-- | :-- |
| `assinaturas.csv` | Retrato de 01/10/2026, uma linha por assinatura; cada mudança sobrescreve a anterior | Mostra a situação em 01/10, não em qualquer data passada |
| `eventos_assinatura.csv` | Log com um evento por linha, desde 01/07/2024 | Não enxerga assinaturas iniciadas antes de 07/2024, que só aparecem no retrato |

Conclusão: os dois precisam ser **integrados** pelo `user_id`. Para estar ativa numa data, a
assinatura precisa ter **entrado** (`assinatura_iniciada`, ou `inicio` no retrato para as
anteriores a 07/2024) e **ainda não ter saído** (`assinatura_expirada`). O evento de expiração
sozinho diz quem saiu, não quem está dentro.

---

## Etapa 4 · Diagnóstico de qualidade (antes de mudar qualquer coisa)

Os dois arquivos foram inspecionados em modo só leitura.

| Verificação | Resultado |
| :-- | :-- |
| Linhas | `assinaturas` 32.643 · `eventos` 275.565 |
| Duplicatas (linha inteira e `assinatura_id`) | Nenhuma |
| `data_fim` anterior a `inicio` | Nenhuma |
| Formato de data em `assinaturas` | Só data (`AAAA-MM-DD`), sem hora nem fuso |
| Formato de data em `eventos` | Lojas: `AAAA-MM-DDTHH:MM:SSZ` (UTC) · Site: `AAAA-MM-DD HH:MM:SS` (Brasília) |
| Status em 01/10/2026 | 14.813 ativas · 17.758 expiradas · 72 reembolsadas |
| Planos | mensal 19.556 · anual 13.027 · **cortesia 60** |
| Assinaturas por pessoa | Exatamente 1. O dicionário diz que a pessoa pode sair e voltar, mas na base isso não ocorre |
| Contas só nos eventos | 19.613 (testes grátis que nunca viraram assinatura; esperado) |
| Coerência entre arquivos | Toda `data_fim` tem um `assinatura_expirada` correspondente, e vice-versa; nenhuma assinatura "ativa" tem expiração nos eventos |

**Achados que exigiram decisão:**

1. **60 assinaturas de cortesia** (canal `interno`), todas ativas e sem eventos. Não pagam.
   Sem elas, os ativos caem de 14.813 para **14.753, exatamente o número do enunciado**. Este
   foi o primeiro teste de consistência da limpeza.
2. **Dois fusos no log de eventos.** Lido como texto, 44 eventos pareciam posteriores ao corte
   (`2026-10-01T01:59:33Z`), mas em Brasília aconteceram em 30/09/2026 às 22h59. Sem a conversão,
   eles seriam descartados por engano ou cairiam no mês errado.
3. **As datas de `assinaturas.csv` já estão no dia de Brasília.** Conferidas contra os eventos de
   expiração: as 17.830 batem com a data em Brasília, e 1.406 não bateriam com a data em UTC.
   Não precisam de conversão.
4. **Horário de verão.** O Brasil o aboliu em 2019, e os eventos começam em 2024: não se aplica.
   A conversão usa o fuso `America/Sao_Paulo`, que trataria o horário de verão automaticamente
   se ele existisse no período.
5. **Datas em branco.** As 14.753 assinaturas ativas não têm `data_fim`. "Ignorar datas em
   branco" foi interpretado como **manter a linha com a data vazia**: apagar essas linhas
   apagaria todos os ativos.
6. **`plano` vazio em 6.734 eventos `renovacao_automatica_desligada`.** Registrado, não
   preenchido.

**Cadastro (`usuarios.csv`), incluído em 11/11** depois de revisarmos as aulas: a segmentação vai
usar a idade, e a aula de 29/10 mostrou que o cadastro tem datas de nascimento impossíveis.

7. **606 datas de nascimento impossíveis:** 412 em 1900-01-01 e 194 em 2031-05-12, ou seja, datas
   padrão do sistema para campo não preenchido. Viram faltante.
8. **`sexo` com sete grafias** (F, Fem, feminino, M, Masc, masculino) para dois valores.
   Padronizado em F/M.
9. **Campos vazios:** 3.298 contas sem nascimento e 3.140 sem sexo. Diferente da base master da
   aula, **mantivemos essas contas**: idade e sexo descrevem o assinante, mas não decidem a saída,
   e removê-las tiraria pagantes reais da contagem.

---

## Etapa 5 · Execução da limpeza

**Regras do grupo seguidas:** os arquivos de `dados/brutos/` nunca são alterados; o resultado vai
para `dados/processados/`; a lógica fica num script que qualquer integrante pode rodar de novo.

**Script:** [`src/normaliza_datas.py`](../src/normaliza_datas.py)

```
.venv\Scripts\python src\normaliza_datas.py
```

**O que o script faz e o que ele mostrou na execução:**

| Passo | Antes | Depois |
| :-- | --: | --: |
| `assinaturas`: remover cortesia | 32.643 | 32.583 (−60) |
| `assinaturas`: ativas | 14.813 | **14.753** ✓ enunciado |
| `assinaturas`: `data_fim` em branco | mantidas | 14.753 |
| `eventos`: converter UTC → Brasília | 186.323 linhas de loja | coluna `data_hora_brt` |
| `eventos`: linhas do site | 89.242 já em Brasília | mantidas |
| `eventos`: após o corte | 44 (texto UTC) | **0** (Brasília) |
| `eventos`: intervalo | — | 01/07/2024 06:11 a 30/09/2026 22:59 |
| `eventos`: total de linhas | 275.565 | 275.565 (nenhuma removida) |
| `usuarios`: remover contas de teste | 64.948 | 64.888 (−60) |
| `usuarios`: nascimento impossível → faltante | 606 | coluna `idade` vazia + `nascimento_invalido` |
| `usuarios`: sexo padronizado | 7 grafias | F/M (24.803 regrafadas) |

**Saídas** (fora do Git, como todo o `dados/`):
- `dados/processados/assinaturas.csv`
- `dados/processados/usuarios.csv`: acrescenta `idade` (anos completos em 30/09/2026),
  `faixa_etaria`, `nascimento_invalido` e `sexo_original`.
- `dados/processados/eventos_assinatura.csv`: mantém a `data_hora` original e acrescenta
  `origem_fuso` (UTC ou BRT) e `data_hora_brt`, para que qualquer conversão possa ser auditada.

---

## Próximos passos

- ~~Decidir o tratamento de `reembolso`, `chargeback` e `periodo_carencia`.~~ Resolvido na análise
  exploratória: só `assinatura_expirada` encerra a assinatura (ver `02_Analise Exploratoria.md`).
- Reconstruir a situação de cada assinante mês a mês e reproduzir o churn do enunciado (5,6% em
  2025, 6,6% em jan–set/2026, 8,1% em abril/2026).
