@echo off
chcp 65001 >nul
cd /d "%~dp0"
set "LOG=%~dp0criar_ambiente_log.txt"
echo Log da criacao do ambiente - %date% %time% > "%LOG%"

echo [0/4] Conferindo o Python...
set "PY="
py -3 --version >nul 2>&1 && set "PY=py -3"
if not defined PY (
    python --version >nul 2>&1 && set "PY=python"
)
if not defined PY (
    echo PYTHON_NAO_ENCONTRADO >> "%LOG%"
    echo.
    echo Python nao encontrado neste computador. Nada foi instalado.
    echo Volte ao chat do Claude para ver como instalar.
    pause
    exit /b 1
)
%PY% --version >> "%LOG%" 2>&1
%PY% --version

echo [1/4] Criando o ambiente em .venv ...
if not exist ".venv\Scripts\python.exe" (
    %PY% -m venv .venv >> "%LOG%" 2>&1
)
if not exist ".venv\Scripts\python.exe" (
    echo ERRO_VENV >> "%LOG%"
    echo Erro ao criar o .venv. Veja criar_ambiente_log.txt
    pause
    exit /b 1
)

echo [2/4] Instalando pandas, pyarrow, matplotlib e jupyterlab (pode levar alguns minutos)...
".venv\Scripts\python.exe" -m pip install --upgrade pip >> "%LOG%" 2>&1
".venv\Scripts\python.exe" -m pip install pandas "pyarrow>=21" matplotlib jupyterlab >> "%LOG%" 2>&1
if errorlevel 1 (
    echo ERRO_INSTALACAO >> "%LOG%"
    echo Erro na instalacao. Veja criar_ambiente_log.txt
    pause
    exit /b 1
)

echo [3/4] Gravando as versoes em requirements.txt ...
".venv\Scripts\python.exe" -m pip freeze > requirements.txt

echo [4/4] Testando a leitura dos dados...
echo ===== TESTE ===== >> "%LOG%"
".venv\Scripts\python.exe" src\teste_ambiente.py >> "%LOG%" 2>&1
type "%LOG%" | findstr /C:"linhas" /C:"pandas" /C:"OK:" /C:"Error"

echo FIM >> "%LOG%"
echo.
echo Pronto. Pode fechar esta janela e avisar o Claude no chat.
pause
