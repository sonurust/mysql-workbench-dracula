# MySQL Workbench one-line installer (Windows) with theme support.
#   irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
#   $env:THEME="dracula"; irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
$ErrorActionPreference = "Stop"

$RepoRaw = if ($env:REPO_RAW) { $env:REPO_RAW } else { "https://raw.githubusercontent.com/sonurust/mysql-workbench/master" }
$Theme   = if ($env:THEME)    { $env:THEME }    else { "dark" }

# Editing Program Files needs admin; relaunch elevated if needed.
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Please run PowerShell as Administrator and re-run this command." -ForegroundColor Yellow
    return
}

Write-Host "==> Installing/upgrading MySQL Workbench (winget)" -ForegroundColor Cyan
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from the Microsoft Store."
}
winget install -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    winget upgrade -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
}

$dataDir = Get-ChildItem "C:\Program Files\MySQL\MySQL Workbench*\data" -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dataDir) { Write-Host "Workbench data folder not found; skipping theme." -ForegroundColor Yellow; return }

$target = Join-Path $dataDir.FullName "code_editor.xml"
$url    = "$RepoRaw/themes/$Theme/code_editor.xml"
try {
    $tmp = New-TemporaryFile
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp
    if (-not (Test-Path "$target.orig")) { Copy-Item $target "$target.orig" }
    Copy-Item $tmp $target -Force
    Write-Host "==> Applied editor theme: $Theme" -ForegroundColor Cyan
} catch {
    Write-Host "Theme '$Theme' not found at $url" -ForegroundColor Yellow
}
Write-Host "Done. Restart MySQL Workbench."
