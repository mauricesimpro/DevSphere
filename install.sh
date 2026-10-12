#!/usr/bin/env bash
#
# install.sh — build DevSphere (release) and install it as a native Linux app.
#
# Usage:
#   ./install.sh              Build + install (or update an existing install)
#   ./install.sh --uninstall  Remove the installed app, icon, and launcher
#
# User-level install under ~/.local — no sudo required.

set -euo pipefail

APP_ID="devsphere"
APP_NAME="DevSphere"

# Resolve the repo root (directory containing this script) so it works from anywhere.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEST="$HOME/.local/lib/$APP_ID"
APPS_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP_FILE="$APPS_DIR/$APP_ID.desktop"

refresh_caches() {
  update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
}

uninstall() {
  echo "Removing $APP_NAME..."
  rm -rf "$DEST"
  rm -f "$DESKTOP_FILE"
  rm -f "$ICON_DIR/$APP_ID.svg"
  refresh_caches
  echo "Done. $APP_NAME has been uninstalled."
  echo "(Your saved config/preferences were left untouched.)"
}

install() {
  command -v flutter >/dev/null 2>&1 || {
    echo "Error: 'flutter' is not on your PATH." >&2
    exit 1
  }

  echo "==> Building $APP_NAME (release)..."
  (cd "$REPO_DIR" && flutter build linux --release)

  local bundle="$REPO_DIR/build/linux/x64/release/bundle"
  [ -d "$bundle" ] || {
    echo "Error: build bundle not found at $bundle" >&2
    exit 1
  }

  echo "==> Installing app bundle to $DEST"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  cp -r "$bundle/." "$DEST/"

  echo "==> Installing icon"
  mkdir -p "$ICON_DIR"
  cp "$REPO_DIR/resources/$APP_ID.svg" "$ICON_DIR/$APP_ID.svg"

  echo "==> Creating launcher entry"
  mkdir -p "$APPS_DIR"
  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$APP_NAME (version 10-26)
Exec=$DEST/$APP_ID
Icon=$APP_ID
Terminal=false
Categories=Development;
StartupWMClass=$APP_ID
EOF
  chmod +x "$DESKTOP_FILE"

  refresh_caches

  echo ""
  echo "✓ $APP_NAME installed."
  echo "  Launch it from your apps menu (search \"$APP_NAME\"),"
  echo "  or run directly: $DEST/$APP_ID"
}

case "${1:-}" in
  --uninstall|-u) uninstall ;;
  "" ) install ;;
  * ) echo "Usage: $0 [--uninstall]" >&2; exit 2 ;;
esac
