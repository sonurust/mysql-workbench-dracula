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

# 4. Patch the SQL editor colors (light + dark + background), always from the pristine backup
$orig = "$target.orig"
if (-not (Test-Path $orig)) { Copy-Item $target $orig }

# Applied in order: later keys override earlier ones (majorKeyword after keyword).
$fore = [ordered]@{
    default          = @(0, 32)
    comment          = @(1, 2, 65, 66)
    variable         = @(3, 67)
    sysvar           = @(4, 5, 68, 69)
    number           = @(6, 70)
    string           = @(11, 12, 13, 75, 76, 77)
    keyword          = @(7, 8, 71, 72)
    majorKeyword     = @(7, 71)
    function         = @(9, 10, 15, 73, 74, 79)
    operator         = @(14, 78)
    identifier       = @(16, 80)
    quotedIdentifier = @(17, 81)
    delimiter        = @(18, 19, 20, 82, 83, 84)
}
$mainIds   = (0..20) + 32
$hiddenIds = @(21, 22) + (65..86)

$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true
$xml.Load($orig)
$lang = $xml.SelectSingleNode("//language[@name='SCLEX_MYSQL']")
if (-not $lang) { Write-Host "SCLEX_MYSQL section not found; file format differs." -ForegroundColor Yellow; return }

function Set-Style($doc, $parent, $id, $attrs) {
    $node = $parent.SelectSingleNode("style[@id='$id']")
    if (-not $node) {
        $node = $doc.CreateElement("style")
        $node.SetAttribute("id", "$id")
        [void]$parent.AppendChild($node)
    }
    foreach ($k in $attrs.Keys) { $node.SetAttribute($k, $attrs[$k]) }
}

foreach ($key in $fore.Keys) {
    $c = $t.$key
    if (-not $c) { continue }
    foreach ($id in $fore[$key]) {
        Set-Style $xml $lang $id @{ "fore-color-light" = $c; "fore-color-dark" = $c }
    }
}
$bg = $t.background
if ($bg) {
    foreach ($id in $mainIds) { Set-Style $xml $lang $id @{ "back-color-light" = $bg; "back-color-dark" = $bg } }
}
$hb = if ($t.hiddenBackground) { $t.hiddenBackground } else { $bg }
if ($hb) {
    foreach ($id in $hiddenIds) { Set-Style $xml $lang $id @{ "back-color-light" = $hb; "back-color-dark" = $hb } }
}
if ($t.lineNumber) {
    $ln = @{ "fore-color-light" = $t.lineNumber; "fore-color-dark" = $t.lineNumber }
    if ($bg) { $ln["back-color-light"] = $bg; $ln["back-color-dark"] = $bg }
    Set-Style $xml $lang 33 $ln
}

$sw = New-Object System.IO.StreamWriter($target, $false, (New-Object System.Text.UTF8Encoding($false)))
$xml.Save($sw); $sw.Close()
Write-Host "==> Applied theme '$Theme'. Restart MySQL Workbench." -ForegroundColor Green
