# Análise Exploratória

Registro da segunda etapa da trilha de tecnologia. O código, com as saídas e os gráficos, está em
[`notebooks/02_analise_exploratoria.ipynb`](../notebooks/02_analise_exploratoria.ipynb); as
decisões pontuais estão no [`decisoes.md`](../decisoes.md).

**Pergunta:** quem saiu entre 01/07 e 30/09/2026 se comportava diferente de quem ficou?

---

## Passo 1 · Definir os grupos

- **Base:** quem pagava em 30/06/2026, ou seja, tinha um evento pago até essa data e nenhuma
  `assinatura_expirada` até ela.
- **Saiu:** teve `assinatura_expirada` entre 01/07 e 30/09. **Ficou:** o resto da base.

Antes de usar a regra, nós a aplicamos em três datas com número oficial no enunciado. Ela
reproduziu os três **exatamente**: 14.237 em 31/03, 14.319 em 31/08 e 14.753 em 30/09.

A versão do roteiro da aula, que conta também reembolso e chargeback como fim, errou por 3 e
por 4. Os dados explicam por quê: todo reembolso expira no mesmo dia, mas 4 chargebacks não
encerraram a assinatura. Isso respondeu a dúvida que tínhamos deixado em aberto na limpeza.

| Grupo | Assinantes |
| :-- | --: |
| Base em 30/06/2026 | 14.059 |
| Saiu até 30/09 | 2.343 (16,7%) |
| Ficou | 11.716 |

A taxa do trimestre (16,7%) fica perto de três meses de churn a 6,6% ao mês (18,5%).

**Por que 14.059 e não 14.753?** São fotos de datas diferentes: a base desta análise é quem pagava
*antes* da janela de saída. As contas fecham assim: 14.059 em 30/06 − 2.343 que saíram + 3.037 que
assinaram no trimestre e seguiam ativos = 14.753 em 30/09. Outras 171 assinaram e saíram dentro do
trimestre e não aparecem em nenhuma das duas fotos.

## Passo 2 · Conferir a qualidade dos arquivos novos

| Achado | Evidência | Decisão |
| :-- | :-- | :-- |
| O `uso_mensal` conta só os treinos do app e ignora Garmin e Apple Health (~30%) | Maio/2026: 100.371 no `uso_mensal`, 101.801 só de origem app, 146.061 no total | Treinos pelo `atividades.parquet`; do `uso_mensal`, só as aberturas do app |
| Treinos do Garmin em UTC | Pico às 9h e 5.828 treinos antes das 5h; app e Apple Health com pico às 6h | −3h nos 207.954 treinos do Garmin |
| Tipos em inglês desde 15/04/2026 | `run`, `walk`, `ride`, `strength` ao lado dos nomes em português | Traduzir (376.930 treinos) |
| Duração 0 ou acima de 4h | 3.649 e 1.597 treinos | Manter e registrar |
| `sexo` em texto livre e 606 nascimentos impossíveis | Sete grafias; datas 1900-01-01 e 2031-05-12 | Tratados na limpeza (`usuarios.csv` processado) |

**Resumo pelas cinco dimensões de qualidade vistas em aula:**

| Dimensão | O que conferimos | Resultado |
| :-- | :-- | :-- |
| Completude | Vazios nas colunas usadas | 3.298 sem nascimento e 3.140 sem sexo, mantidos; distância vazia em 46% dos treinos (sem GPS, esperado) |
| Validade | Valores possíveis | 606 nascimentos impossíveis → faltante; 3.649 treinos com duração 0 e 1.597 acima de 4h, registrados |
| Consistência | A mesma informação bate entre arquivos | `uso_mensal` ignora treinos de relógio; tipos em dois idiomas; `data_fim` bate 100% com a expiração no log |
| Unicidade | Chaves sem repetição | `user_id`, `atividade_id` e usuário+mês sem repetição; uma linha por assinante no final |
| Temporalidade | Período e fuso de cada data | Lojas e Garmin em UTC → Brasília; nenhuma variável usa dado posterior a 30/06 |

## Passo 3 · Uma linha por assinante

Todas as variáveis descrevem o assinante **até 30/06/2026**, para não vazar o futuro:

- plano e canal pelo último evento pago, e não pelo retrato de 01/10;
- renovação desligada;
- tempo de casa;
- treinos e minutos por semana, % ao ar livre, tendência e dias sem treino (abril a junho);
- aberturas do app;
- canal de aquisição e relógio;
- chamados ao suporte.

Nenhuma junção multiplicou linhas: foram 14.059 linhas do começo ao fim. O resultado está em
`dados/processados/assinantes_30jun.csv`.

## Passo 4 · Descrever cada variável

Em dias sem treino, a média (15,6) é cinco vezes a mediana (3), por causa de uma cauda de
assinantes parados. Por isso, comparamos por mediana e quartis.

## Passo 5 · Comparar os grupos

| Mediana (1º–3º quartil) | Saiu | Ficou |
| :-- | :-- | :-- |
| Treinos por semana | 1,3 (0,3–2,5) | 1,9 (1,1–2,8) |
| Minutos por semana | 60 (15–109) | 85 (47–131) |
| Dias sem treino em 30/06 | 6 (1–24) | 2 (1–8) |
| Aberturas do app por mês | 4,7 (2,0–10,7) | 7,0 (3,3–13,0) |

- A variável que mais separa é a **renovação desligada** (Spearman 0,30). Ela é a saída já
  anunciada, não um motivo: 94% dos anuais e 99% dos mensais que a desligaram saíram.
- Entre as variáveis de comportamento, a que mais separa é **dias sem treino** (0,15). Até 7 dias
  parado, a saída fica em 12–14%; a partir de 8 dias, dobra; entre 15 e 60 dias, passa de 30%.
- **Seis dias não é o limiar.** A mediana de quem saiu é 6 dias sem treino, mas isso descreve o
  grupo, não marca o risco. Dia a dia, de 0 a 7 dias a saída fica entre 11% e 15%, abaixo da média
  (16,7%); no 8º dia ela salta para 22%. **O limiar que os dados mostram é 8 dias.** E 40% de
  quem saiu tinha treinado nos últimos 3 dias: para esses, o uso não avisa.
- Canal de aquisição, relógio, chamados ao suporte e idade quase não separam. A idade varia de
  14,8% a 18,2% entre faixas e, como se discutiu na trilha de negócios, descreve o assinante mas
  não é gatilho de ação.

## Passo 6 · Terceira variável: o plano

À primeira vista, o anual sai menos: 10,9% contra 24,7%. Mas o anual **só pode sair na
renovação**. Entre os anuais que renovavam entre 01/07 e 30/09, **46% saíram**. A taxa baixa
vinha de três quartos deles não renovarem no trimestre.

**Tempo de casa.** Na correlação geral ele quase não aparece (−0,04), porque mistura os planos.
Aberto por plano, só entre quem podia sair: no mensal, a saída cai de 33% (até 2 meses de casa)
para 10% (mais de 2 anos); no anual, a primeira renovação é a mais crítica (52%, contra 33%
depois de 2 anos). **Limite:** a base de 30/06 não inclui quem assinou e saiu dentro do trimestre
(171 pessoas), então a saída dos primeiros meses está, se algo, subestimada.

Comparando só quem podia sair, a relação entre dias sem treino e saída se mantém nos dois
planos, e no anual é ainda mais forte: 16% de saída para quem treinou nos últimos 3 dias e mais
de 80% para quem estava parado havia 15 a 60 dias.

Dos 2.343 que saíram, **1.320 (56%) não tinham desligado a renovação antes de 01/07**. É nesse
grupo que um sinal de uso pode antecipar a saída.

## Passo 7 · Conferência à mão

Três assinantes sorteados (semente 42) tiveram o histórico aberto. O rótulo e os dias sem treino
batem com os eventos.

## Três frases

1. **O que o dado diz.** Quem saiu já treinava menos antes de sair: mediana de 6 dias sem treinar
   em 30/06, contra 2 de quem ficou. A partir de 8 dias parado, a taxa de saída dobra, e a
   relação se mantém nos dois planos.
2. **O que o dado não diz.** Não diz que parar de treinar causa a saída: o cruzamento aponta um
   suspeito, não prova causa. Também não diz que o plano anual retém mais: entre os anuais que
   renovavam no trimestre, 46% saíram, contra 25% dos mensais.
3. **A próxima pergunta.** Entre os 56% que saíram sem desligar a renovação antes, quantos dias
   sem treino bastam para antecipar a saída a tempo de agir, e isso muda por segmento?
