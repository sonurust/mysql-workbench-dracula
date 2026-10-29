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

# Check if MySQL Workbench is already installed via winget
$installed = winget list --id Oracle.MySQLWorkbench 2>$null | Where-Object { $_ -match "Oracle.MySQLWorkbench" }

if ($installed) {
    Write-Host "==> MySQL Workbench already installed. Checking for updates..." -ForegroundColor Cyan
    winget upgrade -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "==> Installing MySQL Workbench (winget)" -ForegroundColor Cyan
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found. Install 'App Installer' from the Microsoft Store."
    }
    winget install -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
}

# Find MySQL Workbench installation directory (handles versions like "8.0 CE", "8.0", etc.)
$wbDir = Get-ChildItem "C:\Program Files\MySQL" -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "MySQL Workbench*" } |
    Select-Object -First 1

if (-not $wbDir) { Write-Host "MySQL Workbench folder not found in C:\Program Files\MySQL; skipping theme." -ForegroundColor Yellow; return }

$dataDir = Get-ChildItem (Join-Path $wbDir.FullName "data") -Directory -ErrorAction SilentlyContinue
if (-not $dataDir) { Write-Host "Workbench data folder not found at $($wbDir.FullName)\data; skipping theme." -ForegroundColor Yellow; return }

$target = Join-Path $dataDir.FullName "code_editor.xml"
$url    = "$RepoRaw/themes/$Theme/code_editor.xml"

# Check if theme already applied (by checking for .orig backup)
if (Test-Path "$target.orig") {
    Write-Host "==> Theme already applied (found code_editor.xml.orig). Skipping." -ForegroundColor Cyan
    Write-Host "    To re-apply, remove $target.orig and re-run." -ForegroundColor Gray
} else {
    try {
        $tmp = New-TemporaryFile
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp
        Copy-Item $target "$target.orig"
        Copy-Item $tmp $target -Force
        Write-Host "==> Applied editor theme: $Theme" -ForegroundColor Cyan
    } catch {
        Write-Host "Theme '$Theme' not found at $url" -ForegroundColor Yellow
    }
}
Write-Host "Done. Restart MySQL Workbench."