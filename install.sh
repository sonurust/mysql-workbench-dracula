#!/usr/bin/env bash
# MySQL Workbench one-line installer (macOS + Linux) with themes.
#   curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | bash
#   curl -fsSL .../install.sh | THEME=dracula bash
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/sonurust/mysql-workbench/master}"
THEME="${THEME:-dark}"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

install_mac() {
  have brew || { say "Installing Homebrew"; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }
  say "Installing/upgrading MySQL Workbench"
  brew install --cask mysqlworkbench || brew upgrade --cask mysqlworkbench || true
}

install_linux() {
  if ! have flatpak; then
    say "Installing Flatpak"
    if   have apt-get; then $SUDO apt-get update && $SUDO apt-get install -y flatpak
    elif have dnf;     then $SUDO dnf install -y flatpak
    elif have pacman;  then $SUDO pacman -S --noconfirm flatpak
    elif have zypper;  then $SUDO zypper install -y flatpak
    else echo "Install flatpak manually, then re-run."; exit 1; fi
  fi
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  say "Installing/updating MySQL Workbench (Flathub)"
  flatpak install -y flathub com.mysql.Workbench || flatpak update -y com.mysql.Workbench
  # Flatpak files are read-only: dark window via GTK, editor colors not patchable here.
  flatpak override --user --env=GTK_THEME=Adwaita:dark com.mysql.Workbench
  say "Window set to dark (GTK_THEME override)"
}

theme_mac() {
  have python3 || { say "python3 not found; skipping editor theme"; return; }
  local xml; xml="$(find /Applications/MySQLWorkbench.app -name code_editor.xml 2>/dev/null | head -1)"
  [ -n "$xml" ] || { say "code_editor.xml not found; skipping editor theme"; return; }
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "$REPO_RAW/tools/apply_theme.py" -o "$tmp/apply_theme.py"
  curl -fsSL "$REPO_RAW/themes/$THEME.json"   -o "$tmp/theme.json" || { say "Theme '$THEME' not found"; return; }
  [ -f "$xml.orig" ] || $SUDO cp "$xml" "$xml.orig"
  $SUDO python3 "$tmp/apply_theme.py" "$xml" "$tmp/theme.json"
  rm -rf "$tmp"
}

case "$(uname -s)" in
  Darwin) install_mac;   theme_mac ;;
  Linux)  install_linux ;;
  *) echo "Unsupported OS. On Windows run install.ps1"; exit 1 ;;
esac
say "Done. Restart MySQL Workbench."
