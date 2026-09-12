#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.config/omarchy/plugins/omarchy-smart-enter"
BIN_DIR="${HOME}/.local/bin"

echo "=== Installing Omarchy Smart Enter Plugin ==="

# 1. Validate manifest
if command -v omarchy >/dev/null 2>&1; then
  echo "Validating plugin manifest..."
  omarchy plugin validate "$SCRIPT_DIR"
fi

# 2. Install plugin files
mkdir -p "$TARGET_DIR"
cp -a "$SCRIPT_DIR/manifest.json" "$TARGET_DIR/"
cp -a "$SCRIPT_DIR/Service.qml" "$TARGET_DIR/"
cp -a "$SCRIPT_DIR/LockView.qml" "$TARGET_DIR/"
cp -a "$SCRIPT_DIR/Sha256.js" "$TARGET_DIR/"
echo "✓ Plugin copied to $TARGET_DIR"

# 3. Install CLI tool
mkdir -p "$BIN_DIR"
cp -a "$SCRIPT_DIR/bin/omarchy-smart-enter" "$BIN_DIR/omarchy-smart-enter"
chmod +x "$BIN_DIR/omarchy-smart-enter"
echo "✓ CLI tool installed to $BIN_DIR/omarchy-smart-enter"

# 4. Enable plugin and refresh shell
if command -v omarchy >/dev/null 2>&1; then
  echo "Enabling plugin in Omarchy..."
  omarchy-shell -q shell rescanPlugins || true
  omarchy plugin enable omarchy-smart-enter || true
  echo "Restarting Omarchy shell..."
  omarchy restart shell
fi

echo "=== Installation complete! ==="
echo "Lock your screen (Super+Esc), enter your password with Enter once to learn it,"
echo "and every subsequent unlock will happen automatically without Enter!"
