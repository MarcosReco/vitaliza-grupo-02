"""Teste do ambiente: lê dois arquivos brutos e mostra quantas linhas tem cada um.

Somente leitura: nada em dados/brutos/ é alterado.
Uso (com o ambiente ativado):  python src/teste_ambiente.py
"""
from pathlib import Path
import sys

import matplotlib
import pandas as pd
import pyarrow

RAIZ = Path(__file__).resolve().parents[1]
BRUTOS = RAIZ / "dados" / "brutos"

print(f"Python {sys.version.split()[0]} | pandas {pd.__version__} | "
      f"pyarrow {pyarrow.__version__} | matplotlib {matplotlib.__version__}")

atividades = pd.read_parquet(BRUTOS / "atividades.parquet", engine="pyarrow")
print(f"atividades.parquet: {len(atividades):,} linhas x {atividades.shape[1]} colunas".replace(",", "."))

usuarios = pd.read_csv(BRUTOS / "usuarios.csv", encoding="utf-8")
print(f"usuarios.csv: {len(usuarios):,} linhas x {usuarios.shape[1]} colunas".replace(",", "."))

print("OK: ambiente funcionando.")
