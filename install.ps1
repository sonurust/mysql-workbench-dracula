# MySQL Workbench one-line installer (Windows) with theme support.
#   irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
#   $env:THEME="dracula"; irm .../install.ps1 | iex
$ErrorActionPreference = "Stop"

$RepoRaw = if ($env:REPO_RAW) { $env:REPO_RAW } else { "https://raw.githubusercontent.com/sonurust/mysql-workbench/master" }
$Theme   = if ($env:THEME)    { $env:THEME }    else { "dark" }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host "Run PowerShell as Administrator and re-run." -ForegroundColor Yellow; return }

# 1. Install / upgrade
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget not found. Install 'App Installer' from the Microsoft Store." }
Write-Host "==> Installing/upgrading MySQL Workbench" -ForegroundColor Cyan
winget install -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) {
    winget upgrade -e --id Oracle.MySQLWorkbench --accept-package-agreements --accept-source-agreements
}

# 2. Find where Workbench really is
$roots = @()
$uninstall = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
             "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
foreach ($app in (Get-ItemProperty $uninstall -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "MySQL Workbench*" })) {
    if ($app.InstallLocation) { $roots += $app.InstallLocation }
}
$roots += Get-ChildItem $env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs" -Directory -Filter "MySQL*" -ErrorAction SilentlyContinue |
          ForEach-Object { $_.FullName }
$roots = $roots | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$target = $null
foreach ($r in $roots) {
    $hit = Get-ChildItem $r -Recurse -Filter code_editor.xml -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $target = $hit.FullName; break }
}
if (-not $target) {
    Write-Host "Could not find code_editor.xml. Searched:" -ForegroundColor Yellow
    $roots | ForEach-Object { Write-Host "  $_" }
    return
}
Write-Host "==> Found: $target" -ForegroundColor Cyan

# 3. Apply theme
$url = "$RepoRaw/themes/$Theme/code_editor.xml"
$tmp = New-TemporaryFile
try { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp }
catch { Write-Host "Theme '$Theme' is not in the repo yet: $url" -ForegroundColor Yellow; return }

if (-not (Test-Path "$target.orig")) { Copy-Item $target "$target.orig" }
Copy-Item $tmp $target -Force
Write-Host "==> Applied theme: $Theme. Restart MySQL Workbench." -ForegroundColor Green