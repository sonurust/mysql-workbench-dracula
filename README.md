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

Available: `dark`, `dracula`, `monokai`, `nord`

```bash
curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | THEME=dracula bash
```
```powershell
$env:THEME="dracula"; irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
```

Themes recolor the SQL editor's **dark-mode** syntax colors, so Workbench must be in its dark mode.
Re-run the installer after a Workbench upgrade (the MSI replaces the patched file).

## Add a theme

Copy `themes/dark.json` to `themes/<name>.json`, change the hex colors, push. Done.
Keys: default, comment, variable, sysvar, number, string, keyword, function, operator,
identifier, quotedIdentifier, delimiter, hiddenBackground.

## Restore original

Copy `code_editor.xml.orig` over `code_editor.xml` in the Workbench `data` folder.

## Layout
```
install.sh  install.ps1
tools/apply_theme.py      (used by install.sh on macOS)
themes/*.json
```
