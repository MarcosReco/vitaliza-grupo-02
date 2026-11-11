"""Etapa 1 da limpeza: assinaturas.csv e eventos_assinatura.csv.

O que faz:
  1. Lê os dois arquivos de dados/brutos/ (nunca os altera).
  2. Remove as assinaturas de cortesia (plano 'cortesia', canal 'interno'): não pagam,
     portanto não entram na contagem de pagantes nem no churn.
  3. Normaliza as datas para o horário de Brasília (America/Sao_Paulo):
       - eventos de loja (terminados em 'Z') estão em UTC -> convertidos;
       - eventos do site já estão em Brasília -> mantidos;
       - assinaturas.csv tem só datas (sem hora), já no dia de Brasília -> mantidas.
     Datas em branco ficam em branco (a linha é mantida).
  4. usuarios.csv: remove as mesmas 60 contas de teste (e-mail @vitaliza.com.br), calcula a
     idade em anos completos em 30/09/2026 e trata como faltante a data de nascimento
     impossível (datas padrão do sistema, 1900-01-01 e 2031-05-12); padroniza o sexo
     (sete grafias -> F/M). Nenhuma conta real é removida por ter campo vazio.
  5. Grava o resultado em dados/processados/ e imprime as contagens de cada passo.

Rodar na pasta do projeto:  .venv\\Scripts\\python src\\normaliza_datas.py
"""
from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
BRUTOS = RAIZ / "dados" / "brutos"
PROCESSADOS = RAIZ / "dados" / "processados"
FUSO = "America/Sao_Paulo"
CORTE_INICIO = pd.Timestamp("2026-10-01")  # tudo deve ser anterior a 01/10/2026 00:00 BRT


def limpa_assinaturas() -> pd.DataFrame:
    df = pd.read_csv(BRUTOS / "assinaturas.csv", dtype=str, keep_default_na=False)
    print(f"[assinaturas] linhas lidas: {len(df):,}")

    cortesia = df["plano_atual"].eq("cortesia")
    print(f"[assinaturas] cortesia removidas: {cortesia.sum():,}")
    df = df.loc[~cortesia].copy()

    for col in ["inicio", "data_fim"]:
        df[col] = pd.to_datetime(df[col].replace("", pd.NA), format="%Y-%m-%d").dt.date
        print(f"[assinaturas] {col}: {df[col].isna().sum():,} em branco (mantidas)")

    print(f"[assinaturas] linhas gravadas: {len(df):,}  |  ativas: {(df['status_atual'] == 'ativa').sum():,}")
    return df


def limpa_eventos() -> pd.DataFrame:
    df = pd.read_csv(BRUTOS / "eventos_assinatura.csv", dtype=str, keep_default_na=False)
    print(f"[eventos] linhas lidas: {len(df):,}")

    utc = df["data_hora"].str.endswith("Z")
    df["origem_fuso"] = utc.map({True: "UTC", False: "BRT"})
    print(f"[eventos] em UTC (lojas): {utc.sum():,}  |  em BRT (site): {(~utc).sum():,}")

    convertido = pd.Series(pd.NaT, index=df.index, dtype="datetime64[ns]")
    convertido[utc] = (
        pd.to_datetime(df.loc[utc, "data_hora"], format="%Y-%m-%dT%H:%M:%SZ", utc=True)
        .dt.tz_convert(FUSO)
        .dt.tz_localize(None)
    )
    convertido[~utc] = pd.to_datetime(df.loc[~utc, "data_hora"], format="%Y-%m-%d %H:%M:%S")
    df["data_hora_brt"] = convertido

    pareciam_pos_corte = (df["data_hora"] >= "2026-10-01").sum()
    pos_corte = (df["data_hora_brt"] >= CORTE_INICIO).sum()
    print(f"[eventos] lidos como texto, pareciam após o corte: {pareciam_pos_corte:,}")
    print(f"[eventos] após o corte em horário de Brasília: {pos_corte:,}")
    print(f"[eventos] intervalo BRT: {df['data_hora_brt'].min()} a {df['data_hora_brt'].max()}")

    df = df[["user_id", "data_hora", "origem_fuso", "data_hora_brt", "evento",
             "plano", "canal_cobranca", "detalhe"]]
    print(f"[eventos] linhas gravadas: {len(df):,}")
    return df


DATA_IDADE = pd.Timestamp("2026-09-30")
SEXO = {"F": "F", "Fem": "F", "feminino": "F", "M": "M", "Masc": "M", "masculino": "M"}


def limpa_usuarios() -> pd.DataFrame:
    df = pd.read_csv(BRUTOS / "usuarios.csv", dtype=str, keep_default_na=False)
    print(f"[usuarios] linhas lidas: {len(df):,}")

    teste = df["email"].str.endswith("@vitaliza.com.br")
    print(f"[usuarios] contas de teste removidas: {teste.sum():,}")
    df = df.loc[~teste].copy()

    nasc = pd.to_datetime(df["data_nascimento"].replace("", pd.NA), format="%Y-%m-%d")
    idade = (DATA_IDADE.year - nasc.dt.year
             - ((nasc.dt.month > DATA_IDADE.month)
                | ((nasc.dt.month == DATA_IDADE.month) & (nasc.dt.day > DATA_IDADE.day))).astype("Int64"))
    invalida = nasc.notna() & ~idade.between(10, 100)
    print(f"[usuarios] nascimento em branco: {nasc.isna().sum():,} | impossível (idade fora de 10–100): {invalida.sum():,}")
    print(f"[usuarios]   datas impossíveis mais comuns: {df.loc[invalida, 'data_nascimento'].value_counts().head(3).to_dict()}")
    df["nascimento_invalido"] = invalida
    df["idade"] = idade.where(~invalida)
    df["faixa_etaria"] = pd.cut(df["idade"], [9, 24, 34, 44, 54, 64, 100],
                                labels=["até 24", "25–34", "35–44", "45–54", "55–64", "65+"]).astype(str).replace("nan", "")

    df["sexo_original"] = df["sexo"]
    df["sexo"] = df["sexo"].map(SEXO).fillna("")
    print(f"[usuarios] sexo padronizado: {df['sexo'].value_counts().to_dict()}")
    print(f"[usuarios] linhas gravadas: {len(df):,}")
    return df


def main() -> None:
    PROCESSADOS.mkdir(parents=True, exist_ok=True)
    assinaturas = limpa_assinaturas()
    eventos = limpa_eventos()
    usuarios = limpa_usuarios()
    usuarios.to_csv(PROCESSADOS / "usuarios.csv", index=False)

    sem_assinatura = ~eventos["user_id"].isin(assinaturas["user_id"])
    print(f"[checagem] eventos de contas sem assinatura (só teste grátis): {sem_assinatura.sum():,}")

    assinaturas.to_csv(PROCESSADOS / "assinaturas.csv", index=False)
    eventos.to_csv(PROCESSADOS / "eventos_assinatura.csv", index=False,
                   date_format="%Y-%m-%d %H:%M:%S")
    print(f"Gravado em {PROCESSADOS}")


if __name__ == "__main__":
    main()
