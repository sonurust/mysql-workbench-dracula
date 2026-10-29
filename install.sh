#!/usr/bin/env bash
# MySQL Workbench one-line installer (macOS + Linux) with theme support.
#   curl -fsSL https://raw.githubusercontent.com/sonurust/mysql-workbench/master/install.sh | bash
#   curl -fsSL .../install.sh | THEME=dracula bash
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/sonurust/mysql-workbench/master}"
THEME="${THEME:-dark}"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Check if MySQL Workbench is already installed
check_installed_mac() {
  [ -d "/Applications/MySQLWorkbench.app" ]
}

check_installed_linux() {
  flatpak list --app 2>/dev/null | grep -q "com.mysql.Workbench"
}

# Check if theme is already applied
check_theme_applied_mac() {
  local data="/Applications/MySQLWorkbench.app/Contents/Resources/data"
  [ -f "$data/code_editor.xml" ] || return 1
  # Check if .orig exists (meaning we've applied a theme before)
  [ -f "$data/code_editor.xml.orig" ] || return 1
  # Could also compare checksums, but .orig existence is a good indicator
  return 0
}

check_theme_applied_linux() {
  # For Flatpak, we check if GTK_THEME override is already set
  flatpak override --user --show 2>/dev/null | grep -q "GTK_THEME=Adwaita:dark"
}

install_mac() {
  if check_installed_mac; then
    say "MySQL Workbench already installed. Checking for updates..."
    brew upgrade --cask mysqlworkbench || true
  else
    have brew || { say "Installing Homebrew"; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }
    say "Installing MySQL Workbench"
    brew install --cask mysqlworkbench
  fi
}

install_linux() {
  if check_installed_linux; then
    say "MySQL Workbench already installed (Flatpak). Checking for updates..."
    flatpak update -y com.mysql.Workbench
  else
    if ! have flatpak; then
      say "Installing Flatpak"
      if   have apt-get; then $SUDO apt-get update && $SUDO apt-get install -y flatpak
      elif have dnf;     then $SUDO dnf install -y flatpak
      elif have pacman;  then $SUDO pacman -S --noconfirm flatpak
      elif have zypper;  then $SUDO zypper install -y flatpak
      else echo "Install flatpak manually, then re-run."; exit 1; fi
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    say "Installing MySQL Workbench (Flathub)"
    flatpak install -y flathub com.mysql.Workbench
  fi
}

apply_theme_mac() {
  local data="/Applications/MySQLWorkbench.app/Contents/Resources/data"
  [ -d "$data" ] || { say "Workbench data dir not found, skipping editor theme"; return; }

  if check_theme_applied_mac; then
    say "Theme already applied (found code_editor.xml.orig). Skipping."
    say "To re-apply, remove $data/code_editor.xml.orig and re-run."
    return
  fi

  fetch_theme "$data"
}

apply_theme_linux() {
  if check_theme_applied_linux; then
    say "GTK_THEME=Adwaita:dark already set via flatpak override. Skipping."
    return
  fi

  # Flatpak is read-only, so use the GTK dark variant for the UI.
  flatpak override --user --env=GTK_THEME=Adwaita:dark com.mysql.Workbench
  say "UI set to dark via GTK_THEME (Flatpak override)"
}

fetch_theme() {  # $1 = Workbench data dir
  local data="$1" url="$REPO_RAW/themes/$THEME/code_editor.xml" tmp
  tmp="$(mktemp)"
  if curl -fsSL "$url" -o "$tmp"; then
    [ -f "$data/code_editor.xml.orig" ] || $SUDO cp "$data/code_editor.xml" "$data/code_editor.xml.orig"
    $SUDO cp "$tmp" "$data/code_editor.xml"
    say "Applied editor theme: $THEME"
  else
    say "Theme '$THEME' not found at $url"
  fi
  rm -f "$tmp"
}

case "$(uname -s)" in
  Darwin) install_mac;   apply_theme_mac ;;
  Linux)  install_linux; apply_theme_linux ;;
  *) echo "Unsupported OS. On Windows run install.ps1"; exit 1 ;;
esac
say "Done. Restart MySQL Workbench."