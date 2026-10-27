# Publica o projeto Vitaliza num repositorio privado do GitHub.
# O token e lido do .env direto para a memoria e nunca e exibido nem gravado no log.
$ErrorActionPreference = 'Continue'
$RAIZ = $PSScriptRoot
Set-Location -LiteralPath $RAIZ
$LOG = Join-Path $RAIZ 'publicar_github_log.txt'
$REPO = 'vitaliza-grupo-02'
"Log da publicacao no GitHub - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" | Out-File -FilePath $LOG -Encoding utf8

function Log([string]$m) { $m | Out-File -FilePath $LOG -Append -Encoding utf8; Write-Host $m }
function Run([string]$exe, [string[]]$a) {
    $out = & $exe @a 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    foreach ($l in $out) { Log $l }
    return $code
}
function Parar([string]$m) {
    Log "PAROU: $m"
    Log 'FIM_COM_ERRO'
    Write-Host ''
    Read-Host 'Nada mais foi feito. Aperte Enter para fechar e avise o Claude no chat'
    exit 1
}
function Achar([string]$nome, [string]$padrao) {
    $c = Get-Command $nome -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    if (Test-Path -LiteralPath $padrao) { return $padrao }
    return $null
}

# ---- Passo 0: ajustes de seguranca ----
Log '== [0] Ajustes de seguranca =='
$envTxt = Join-Path $RAIZ '.env.txt'
$envOk  = Join-Path $RAIZ '.env'
if ((Test-Path -LiteralPath $envTxt) -and -not (Test-Path -LiteralPath $envOk)) {
    Rename-Item -LiteralPath $envTxt -NewName '.env'
    Log '.env.txt renomeado para .env'
}
if (-not (Test-Path -LiteralPath $envOk)) { Parar 'arquivo .env nao encontrado' }
if (Test-Path -LiteralPath $envTxt) { Parar 'existem .env e .env.txt ao mesmo tempo; resolva manualmente' }

# ---- Passo 1: Git e GitHub CLI ----
Log '== [1] Git e GitHub CLI =='
$git = Achar 'git' "$env:ProgramFiles\Git\cmd\git.exe"
$gh  = Achar 'gh'  "$env:ProgramFiles\GitHub CLI\gh.exe"
if (-not $git -or -not $gh) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Parar 'winget nao encontrado para instalar Git/gh' }
    if (-not $git) { Log 'Instalando Git (winget)...'; winget install --id Git.Git -e }
    if (-not $gh)  { Log 'Instalando GitHub CLI (winget)...'; winget install --id GitHub.cli -e }
    $git = Achar 'git' "$env:ProgramFiles\Git\cmd\git.exe"
    $gh  = Achar 'gh'  "$env:ProgramFiles\GitHub CLI\gh.exe"
}
if (-not $git) { Parar 'Git nao instalado' }
if (-not $gh)  { Parar 'GitHub CLI nao instalado' }
[void](Run $git @('--version'))
[void](Run $gh @('--version'))

# ---- Passo 2: login com o token do .env (sem exibir) ----
Log '== [2] Login no gh =='
$linha = Get-Content -LiteralPath $envOk | Where-Object { $_ -match '^\s*(export\s+)?GITHUB_TOKEN\s*=' } | Select-Object -First 1
if (-not $linha) { Parar 'GITHUB_TOKEN nao encontrado no .env' }
$tok = ($linha -split '=', 2)[1].Trim().Trim('"').Trim("'")
$linha = $null
if (-not $tok) { $tok = $null; Parar 'GITHUB_TOKEN esta vazio no .env' }
# O token classico nao tem o escopo read:org exigido por "gh auth login",
# entao ele e usado so nesta execucao, pela variavel de ambiente GH_TOKEN
# (vale apenas para esta janela e some quando ela fecha; nada e gravado).
$env:GH_TOKEN = $tok
# O git push se autentica com o mesmo token, tambem so nesta execucao
# (configuracao via variaveis de ambiente; nada vai para o .gitconfig).
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$tok"))
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'http.https://github.com/.extraheader'
$env:GIT_CONFIG_VALUE_0 = "Authorization: Basic $b64"
$tok = $null; $b64 = $null
Log 'Token carregado do .env para esta execucao (GH_TOKEN), sem exibir.'
$login = (& $gh api user --jq .login 2>$null)
$uid   = (& $gh api user --jq .id 2>$null)
if (-not $login) { Parar 'nao consegui ler o usuario do GitHub' }
Log "Logado como: $login"

# ---- Passo 3: git init ----
Log '== [3] git init =='
if (-not (Test-Path -LiteralPath (Join-Path $RAIZ '.git'))) {
    if ((Run $git @('init', '-b', 'main')) -ne 0) { Parar 'git init falhou' }
} else { Log 'Ja existe .git; mantido.' }
$nome  = (& $git config user.name 2>$null)
$email = (& $git config user.email 2>$null)
if (-not $nome)  { [void](Run $git @('config', 'user.name', $login)); Log "user.name (so neste projeto) = $login" }
if (-not $email) { [void](Run $git @('config', 'user.email', "$uid+$login@users.noreply.github.com")); Log 'user.email (so neste projeto) = e-mail noreply do GitHub' }

# ---- Passo 4: provar que dados/, .venv/ e .env estao ignorados ----
Log '== [4] git check-ignore -v =='
foreach ($p in @('dados/', '.venv/', '.env', 'docs/atividades.parquet')) {
    if ((Run $git @('check-ignore', '-v', $p)) -ne 0) { Parar "$p NAO esta sendo ignorado" }
}

# ---- Passo 5: commit ----
Log '== [5] git add + conferencia + commit =='
if ((Run $git @('add', '.')) -ne 0) { Parar 'git add falhou' }
$staged = & $git diff --cached --name-only 2>$null
$proibidos = $staged | Where-Object { $_ -match '^(dados/|\.venv/)' -or $_ -match '(^|/)\.env' -or $_ -match '\.parquet$' }
if ($proibidos) { foreach ($p in $proibidos) { Log "PROIBIDO NO COMMIT: $p" }; Parar 'arquivo proibido entrou no commit' }
Log "Arquivos no commit: $(@($staged).Count)"
if ((Run $git @('commit', '-m', 'Estrutura do projeto Vitaliza')) -ne 0) { Parar 'commit falhou' }

# ---- Passo 6: criar repositorio privado e enviar ----
Log '== [6] gh repo create + push =='
if ((Run $gh @('repo', 'create', $REPO, '--private', '--source', '.', '--remote', 'origin', '--push')) -ne 0) { Parar 'criacao do repositorio ou push falhou' }

# ---- Passo 7: resultado ----
Log '== [7] Resultado =='
$url = (& $gh repo view $REPO --json url --jq .url 2>$null)
$vis = (& $gh repo view $REPO --json visibility --jq .visibility 2>$null)
Log "URL: $url"
Log "VISIBILIDADE: $vis"
Log '-- Arquivos no repositorio (git ls-files) --'
& $git ls-files 2>$null | ForEach-Object { Log $_ }
Log 'FIM_OK'
Write-Host ''
Read-Host 'Pronto. Aperte Enter para fechar e avise o Claude no chat'
