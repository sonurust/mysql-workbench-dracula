# MySQL Workbench – easy install + themes

## Install (latest version)

macOS / Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | bash
```
Windows (PowerShell **as Administrator**):
```powershell
irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
```

## Pick a theme (default: dark)

Available: `dark`, `dracula`, `monokai`, `nord`, `tokyonight`

```bash
curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | THEME=dracula bash
```
```powershell
$env:THEME="dracula"; irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
```

## What gets themed

The **SQL editor** (background, line numbers, syntax colors). The rest of Workbench 8.0 on Windows
(navigator, tabs, toolbars, result grid, dialogs) uses native Windows drawing and is not controlled
by `code_editor.xml`.

Re-run the installer after a Workbench upgrade (the MSI replaces the patched file).

## Add a theme

Copy `themes/dark.json` to `themes/<name>.json`, change the hex colors, push.
Keys: background, lineNumber, default, comment, variable, sysvar, number, string, keyword,
majorKeyword (optional), function, operator, identifier, quotedIdentifier, delimiter, hiddenBackground.

## Restore original

Copy `code_editor.xml.orig` over `code_editor.xml` in the Workbench `data` folder.

## Layout
```
install.sh  install.ps1
tools/apply_theme.py      (used by install.sh on macOS)
themes/*.json
```
