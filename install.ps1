# MySQL Workbench one-line installer (Windows) with themes.
#   irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
#   $env:THEME="dracula"; irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
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

# 2. Locate code_editor.xml
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

# 3. Download theme
$url = "$RepoRaw/themes/$Theme.json"
try { $t = (Invoke-WebRequest -UseBasicParsing -Uri $url).Content | ConvertFrom-Json }
catch { Write-Host "Theme '$Theme' not found: $url" -ForegroundColor Yellow; return }

# 4. Patch dark colors of the SQL editor, always starting from the pristine backup
$orig = "$target.orig"
if (-not (Test-Path $orig)) { Copy-Item $target $orig }

$map = @{
  default=@(0); comment=@(1,2,65,66); variable=@(3,67); sysvar=@(4,5,68,69); number=@(6,70)
  string=@(12,13,76,77); keyword=@(7,8,71,72); function=@(15,10,79,74); operator=@(14,78)
  identifier=@(16,80); quotedIdentifier=@(17,81); delimiter=@(18,82)
}
$hiddenIds = 21,65,66,67,68,69,70,71,72,74,76,77,78,79,80,81,82

$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true
$xml.Load($orig)
$lang = $xml.SelectSingleNode("//language[@name='SCLEX_MYSQL']")
if (-not $lang) { Write-Host "SCLEX_MYSQL section not found; file format differs." -ForegroundColor Yellow; return }

foreach ($key in $map.Keys) {
    $color = $t.$key
    if (-not $color) { continue }
    foreach ($id in $map[$key]) {
        $node = $lang.SelectSingleNode("style[@id='$id']")
        if ($node) { $node.SetAttribute("fore-color-dark", $color) }
    }
}
if ($t.hiddenBackground) {
    foreach ($id in $hiddenIds) {
        $node = $lang.SelectSingleNode("style[@id='$id']")
        if ($node -and $node.HasAttribute("back-color-dark")) { $node.SetAttribute("back-color-dark", $t.hiddenBackground) }
    }
}

$sw = New-Object System.IO.StreamWriter($target, $false, (New-Object System.Text.UTF8Encoding($false)))
$xml.Save($sw); $sw.Close()
Write-Host "==> Applied theme '$Theme'. Restart MySQL Workbench (use its dark mode for the colors to show)." -ForegroundColor Green
