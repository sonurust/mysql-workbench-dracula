# MySQL Workbench – easy install + themes

## Install (latest version)

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | bash
```

**Windows (PowerShell as Administrator)**
```powershell
irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
```

## Pick a theme

```bash
curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | THEME=dracula bash
```
```powershell
$env:THEME="dracula"; irm https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.ps1 | iex
```

Default theme is `dark`.

## Add a new theme

1. Create `themes/<name>/code_editor.xml` (copy the original from your Workbench
   `data/` folder, then change the colors).
2. Commit and push. Users run the install command with `THEME=<name>`.

## Restore the original

The installer saves `code_editor.xml.orig` next to the file it replaces. Copy it back to undo.

## Layout

```
install.sh
install.ps1
themes/
  dark/code_editor.xml
  dracula/code_editor.xml
  ...
```
