# Segmentação

Registro da terceira etapa da trilha de tecnologia. O código, com as saídas e os gráficos, está em
[`notebooks/03_segmentacao.ipynb`](../notebooks/03_segmentacao.ipynb); o resumo dos perfis, em
[`saidas/perfis.md`](../saidas/perfis.md); as decisões, no [`decisoes.md`](../decisoes.md). O
trabalho foi feito no branch `cluster-v1` e entra na `main` por pull request.

**Pergunta:** entre os pagantes ativos em 31/07/2026, em quantos grupos os assinantes se dividem,
o que distingue cada grupo e o que a Vitaliza faria diferente com cada um?

---

## Passo 1 · População

São 14.032 pagantes ativos em 31/07/2026, pela mesma regra que reproduz os números oficiais do
enunciado. O slide da aula fala em "perto de 11.700 linhas", mas na aula de 05/11 esse número
apareceu como o tamanho de um grupo, não como a população.

## Passo 2 · Variáveis e escala

| Variável | Origem | Por que entra |
| :-- | :-- | :-- |
| Treinos por semana (12 semanas até 31/07) | Aula | Frequência |
| Dias desde o último treino | Aula | Variável que mais separou na EDA |
| Tempo de casa | Aula | Maturidade do assinante |
| % de treinos ao ar livre | Aula | Tipo de uso |
| Aberturas do app por mês | Grupo | Separou na EDA e não depende de relógio |
| Minutos por treino | Grupo | Separa intensidade de frequência |

Plano e canal ficam fora porque são categorias, não distâncias; a idade foi testada à parte. A
escala segue a aula de 05/11: log nas variáveis assimétricas, corte nos percentis 1 e 99 e
z-score.

## Passo 3 · Escolher o k pelas quatro lentes

| k | Silhueta | Queda da inércia | Rand (mínimo) |
| --: | --: | --: | --: |
| 2 | 0,55 | — | 1,00 |
| 3 | 0,28 | 26% | 0,94 |
| 4 | 0,27 | 17% | 0,97 |
| **5** | **0,29** | **17%** | **0,97** |
| 6 | 0,28 | 10% | 0,96 |
| 7 | 0,27 | 10% | 0,95 |
| 8 | 0,26 | 6% | 0,62 |

- **Silhueta:** o k = 2 tem a maior, mas só separa os 6% que não treinaram nada. Entre k = 3 e 7,
  o k = 5 tem a maior.
- **Inércia:** a queda passa de 17% para 10% depois do k = 5. É o cotovelo.
- **Estabilidade:** o k = 5 se repete nas reamostras, e com outra semente o Rand é de 1,000.
- **Negócio:** começamos pelo k = 3, como na aula. O k = 4 separa os ativos ao ar livre dos de
  ambiente fechado. O k = 5 separa ainda os novatos, que pedem boas-vindas, dos esporádicos, que
  pedem reativação antes da renovação.

**Decisão: k = 5.**

## Passo 4 · Os cinco segmentos

| Segmento | % da base | Treinos/semana | Dias sem treino | Tempo de casa | % mensal | Saída 60d | Saída 60d, quem podia sair | % das saídas |
| :-- | --: | --: | --: | --: | --: | --: | --: | --: |
| Ativos ao ar livre | 34% | 2,5 | 1 | 304 dias | 47% | 7,0% | 13,0% | 22,7% |
| Ativos em ambiente fechado | 28% | 2,3 | 2 | 290 dias | 50% | 6,3% | 11,0% | 16,7% |
| Novatos | 12% | 0,9 | 2 | 28 dias | 62% | 11,4% | 18,1% | 12,9% |
| Esporádicos | 20% | 0,5 | 20 | 315 dias | 18% | 18,8% | 51,8% | 36,6% |
| Parados | 6% | 0 | 167 | 506 dias | 1% | 19,4% | 66,9% | 11,0% |

Saída em 60 dias = `assinatura_expirada` entre 01/08 e 29/09/2026. "Quem podia sair" exclui os
anuais sem renovação na janela, a mesma correção da análise exploratória.

| Segmento | O que a Vitaliza faria diferente |
| :-- | :-- |
| Ativos ao ar livre | Manter o engajamento com desafios e metas de corrida |
| Ativos em ambiente fechado | Manter com conteúdo novo de força, funcional e yoga |
| Novatos | Boas-vindas e primeiro plano de treino |
| Esporádicos | **Prioridade:** agir antes da renovação, a partir de 8 dias sem treino |
| Parados | Testar com cuidado: o contato pode lembrar que pagam por algo que não usam |

**Idade:** não separa os grupos. Com a idade como sétima variável, a silhueta cai de 0,295 para
0,234 e os grupos quase não mudam (Rand de 0,985); a mediana é de 46–47 anos em todos eles. Fica só
como descrição.

## Passo 5 · Conferência

- Outra semente (7) gera os mesmos grupos (Rand de 1,000).
- Três assinantes sorteados foram abertos à mão, e o segmento confere com o histórico de treinos.
- Os cinco segmentos somam 14.032.

## O que concluímos

1. A base se divide em cinco grupos de comportamento, estáveis e com o k defendido pelas quatro
   lentes.
2. Os **esporádicos** são o alvo principal: 20% da base e 37% das saídas, com 52% de saída entre
   quem podia sair. São assinantes antigos, quase todos do anual, que foram parando de treinar.
3. O agrupamento descreve, não prevê: um ativo pode sair e um parado pode renovar. Prever a saída
   de cada pessoa é o trabalho das aulas 6 a 8.

**Limites:** silhueta de 0,29 (estrutura fraca, com grupos que se tocam nas bordas); variáveis
medidas em 12 semanas; plano fora do agrupamento.
