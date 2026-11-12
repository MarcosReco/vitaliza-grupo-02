# Personas e priorização

Registro da quarta etapa, a primeira da trilha de negócios. O código, com as saídas e os gráficos,
está em [`notebooks/04_personas.ipynb`](../notebooks/04_personas.ipynb); as tabelas, em
`dados/processados/personas_31jul.csv` e `saidas/personas/`; as decisões, no
[`decisoes.md`](../decisoes.md). O trabalho foi feito no branch `personas-v1` e entra na `main` por
pull request.

**Pergunta:** dos cinco segmentos de 31/07/2026, quais viram persona, onde cada uma fica na matriz
valor × risco e quanto do orçamento de CRM vai para cada uma?

Seguimos o roteiro da Aula 5 (prof. Fábio, 10/11) e as regras do cartão da Aula 4. Acrescentamos um
passo que o roteiro não tinha e o case pede: a análise da campanha de agosto.

---

## Passo 1 · Validar cada persona

A comparação é sempre entre quem **podia sair** na janela de 60 dias depois de 31/07: 7.089 dos
14.032 pagantes. Entre eles, a saída média foi de 20,6%.

| Segmento | n na base | % da base | n que podia sair | Saída do grupo | Saída do resto | Diferença | Cobertura |
| :-- | --: | --: | --: | --: | --: | --: | --: |
| Esporádicos | 2.858 | 20,4% | 1.037 | 51,8% | 15,2% | +36,5 pp | 36,8% |
| Parados | 835 | 6,0% | 236 | 66,9% | 19,0% | +48,0 pp | 10,8% |
| Novatos | 1.664 | 11,9% | 1.027 | 18,1% | 21,0% | −2,9 pp | 12,7% |
| Ativos ao ar livre | 4.746 | 33,8% | 2.560 | 13,0% | 24,9% | −11,9 pp | 22,8% |
| Ativos em ambiente fechado | 3.929 | 28,0% | 2.229 | 11,0% | 25,0% | −13,9 pp | 16,9% |

**Dois recortes mais finos que testamos:**

- **Novato parado há 8 dias ou mais:** 115 assinantes, saída de 27,0% contra 20,5% (+6,5 pp), só
  2,1% das saídas. Separa pouco e cobre pouco. O novato da Vitaliza não é o novato do exemplo da
  aula: ele sai menos que a média.
- **Esporádico com a renovação já desligada:** 451 assinantes, e 96,2% deles saem. Com a renovação
  ligada, a saída cai para 17,6%, abaixo da média. O aviso de renovação desligada chega antes da
  saída, então não é vazamento, mas é quase a saída anunciada: na base inteira, quem tinha a
  renovação desligada em 31/07 saiu em 96,7% dos casos, e esse grupo soma 51,9% de todas as saídas.
  Para quem paga pela loja (70% da base), o intervalo entre esse aviso e a expiração é a última
  chance de agir. **Decisão:** o aviso vira o gatilho da persona, não o critério dela.

## Passo 2 · Valor

**Critério declarado: potencial**, ou seja, o que a Vitaliza ainda pode receber se a pessoa ficar.
Usamos os critérios do roteiro (tamanho, tempo de casa, plano e indicação) e, em reais, os números do
enunciado:

- **margem de 12 meses:** receita líquida do canal de cobrança menos R$ 4,20 por mês de custo de servir;
- **valor potencial:** margem de 12 meses mais o CAC de R$ 118, o custo de repor quem sai;
- **valor perdido em 60 dias:** a soma do valor potencial de quem saiu.

| Segmento | Tempo de casa | % anual | % indicação | Valor potencial (mediana) | Valor perdido em 60 dias | Valor |
| :-- | --: | --: | --: | --: | --: | :-- |
| Esporádicos | 315 dias | 82% | 16% | R$ 323 | R$ 202 mil | alto |
| Ativos ao ar livre | 304 dias | 53% | 17% | R$ 365 | R$ 159 mil | alto |
| Ativos em ambiente fechado | 290 dias | 50% | 15% | R$ 475 | R$ 117 mil | alto |
| Novatos | 28 dias | 38% | 13% | R$ 475 | R$ 92 mil | médio |
| Parados | 506 dias | 99% | 13% | R$ 323 | R$ 53 mil | médio |

O anual rende menos por mês (R$ 21 líquidos pela loja, contra R$ 34 do mensal), mas trava um ano de
receita numa cobrança só. Por isso o valor por pessoa dos esporádicos é dos mais baixos e, mesmo
assim, eles são o grupo que mais leva valor embora. Indicação e seguidores quase não variam entre os
grupos e não ajudaram a separar valor.

## Passo 3 · A campanha de agosto

Em 10/08, os pagantes do dia foram sorteados em quatro grupos. Três receberam desafio, cupom ou
conteúdo, por push e e-mail; o quarto, o controle, não recebeu nada. O sorteio ficou equilibrado: cada
segmento tem a mesma proporção em todos os grupos. Medimos a saída até 29/09 entre quem podia sair,
com intervalo de confiança de 95%.

| Segmento | Desafio | Cupom | Conteúdo |
| :-- | --: | --: | --: |
| Ativos ao ar livre | −2,5 pp | **−6,0 pp** | −2,1 pp |
| Ativos em ambiente fechado | **−4,7 pp** | **−4,2 pp** | −0,1 pp |
| Novatos | **−7,4 pp** | **−7,2 pp** | −3,0 pp |
| Esporádicos | +3,3 pp | +1,8 pp | −2,0 pp |
| Parados | +9,7 pp | −0,6 pp | +17,3 pp |

Em negrito, os efeitos cujo intervalo não inclui o zero.

- **Ativos e novatos respondem ao contato.** O desafio funciona e não custa nada.
- **Esporádicos não respondem a push e e-mail.** O risco é alto, mas esses canais não mudam o desfecho.
- **Parados podem ser *sleeping dogs*:** nenhuma mensagem reduziu a saída e duas a aumentaram. Com
  cerca de 55 pessoas por grupo, o sinal é de cautela, não de prova.

**O cupom se paga?** Não nos ativos. Reter uma pessoa custa R$ 502 (ao ar livre) e R$ 726 (ambiente
fechado), mais do que ela vale (R$ 365 e R$ 475). O desconto vai sobretudo para quem ficaria de
qualquer jeito. Nos novatos, ele se paga por pouco, mas o desafio tem o mesmo efeito de graça.
**Decisão:** sem cupom em massa.

## Passo 4 · De cinco segmentos para quatro personas

O guia do aluno pede, para a semana 5, de 3 a 4 segmentos com cartões de persona. Juntamos os dois
grupos de ativos numa persona só, o **Ativo regular**: 8.675 assinantes, saída de 12,1% contra 38,3% do
resto (−26,2 pp) e 39,6% das saídas. Os dois têm risco baixo, valor alto e a mesma decisão. A diferença
entre eles fica no cartão: o cupom move mais os de ar livre, e o desafio, os de ambiente fechado. Juntos,
a campanha dá −3,4 pp para o desafio e −5,1 pp para o cupom, os dois significativos.

## Passo 5 · As personas na matriz

| Persona | Valor | Risco | Lugar | Prioridade | Frase de decisão |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Esporádico com renovação à vista | alto | alto | **Priorizar** | imediata | Esporádico com renovação à vista · Priorizar · ligação do CS entre desligar a renovação e expirar |
| Pagante parado | médio | alto | **Não acordar** | monitoramento | Pagante parado · Não acordar · fora das campanhas até um teste pequeno com controle |
| Novato recém-chegado | médio | baixo | **Manter** | monitoramento | Novato recém-chegado · Manter · push de desafio na primeira semana |
| Ativo regular | alto | baixo | **Proteger** | monitoramento | Ativo regular · Proteger · push de desafio e convite para indicar, sem cupom em massa |

A prioridade segue o guia: ação **imediata** ou **monitoramento**. Nenhuma persona ficou em Monitorar
(valor baixo e risco alto).

**Alternativa descartada:** pôr o novato em A validar, como o professor fez com o novato de um mês.
Descartamos porque a campanha dá a evidência que faltava: o desafio reduz a saída dele em 7,4 pp.

## Passo 6 · Hipóteses de drivers de churn

No formato da Aula 2: afirmação causal, métrica e o resultado que derruba a hipótese, definido antes.

| Persona | Hipótese | Métrica | Cai se… | Primeiro teste |
| :-- | :-- | :-- | :-- | :-- |
| Esporádico com renovação à vista | A queda de uso antes da renovação leva o assinante a não renovar | Saída na janela, por dias sem treino | Quem está há 8+ dias sem treinar sair tanto quanto quem treinou na última semana | Sobrevive: 63% contra 25% |
| Pagante parado | Pagar sem usar faz o assinante sair quando o app o lembra disso | Saída com mensagem contra o controle | A saída com mensagem não for maior | Em aberto: +8,3 pp, IC de −6,6 a +23,2 |
| Novato recém-chegado | Sem hábito no primeiro mês, o novato sai; um desafio cria o hábito | Saída com desafio contra o controle | O desafio não reduzir a saída | Sobrevive: −7,4 pp, IC de −13,9 a −0,9 |
| Ativo regular | O ativo mensal que sai sai por preço, não por falta de uso | Efeito do cupom no mensal contra o anual | O cupom reduzir a saída igualmente nos dois planos | Sobrevive: mensal −5,6 pp (IC −8,2 a −3,1); anual −1,1 pp (IC −9,0 a +6,7) |

O driver do ativo conversa com a primeira lacuna do case, a subida do churn em 2026. O reajuste do
mensal em 01/03 é um candidato a causa que a próxima etapa pode testar.

## Passo 7 · Orçamento do mês

| Persona | Ação | Contatos/mês | Custo/mês |
| :-- | :-- | --: | --: |
| Esporádico com renovação à vista | CS no intervalo entre os dois avisos | 226 | R$ 4.068 |
| Esporádico com renovação à vista | Oferta do CS: 1 mês grátis (anual) ou 30% por 3 meses (mensal), pior caso | 226 | R$ 6.065 |
| Esporádico com renovação à vista | WhatsApp: renovação ligada e 8+ dias sem treino | 176 | R$ 70 |
| Novato recém-chegado | Push de desafio na primeira semana | 1.664 | R$ 0 |
| Ativo regular | Push de desafio e e-mail de indicação | 8.675 | R$ 87 |
| Pagante parado | Nenhum contato | 0 | R$ 0 |
| **Total** | | | **R$ 10.290 de R$ 40.000** |

O teto pesa mais que o custo, como o enunciado avisa. O plano usa 226 dos 300 atendimentos do CS e só
176 dos 1.500 WhatsApps: a lista de quem precisa de contato caro é menor que o teto. Não propomos
gastar o resto em cupom, porque ele não se paga. A sobra financia os testes, que precisam de grupo
controle em toda ação nova.

## Limites

- Fora da campanha, os números mostram associação, não causa. As ações novas (CS no intervalo entre os
  avisos, WhatsApp, convite para indicar) são hipóteses a testar com grupo controle.
- A janela da segmentação contém a campanha. O efeito médio foi pequeno (−1 a −4 pp), então a ordem
  dos riscos não muda.
- Só cerca de 10% respondem à pesquisa de saída, e só quem paga pelo site. O motivo da saída não está
  na base.
- A margem de 12 meses supõe que quem fica, fica um ano. Para o mensal, isso é otimista. O número serve
  para comparar grupos, não como previsão de receita.
- Idade e gênero não entram em nenhuma decisão.
