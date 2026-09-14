#!/bin/bash
set -euo pipefail

TARGET_DIR="${HOME}/.config/omarchy/plugins/omarchy-smart-enter"
LEGACY_DIR="${HOME}/.config/omarchy/plugins/rbm.lock"
BIN_FILE="${HOME}/.local/bin/omarchy-smart-enter"
CONFIG_FILE="${HOME}/.config/omarchy/smart_enter.json"
LEGACY_CONFIG="${HOME}/.config/omarchy/lock_hash.json"

echo "=== Uninstalling Omarchy Smart Enter Plugin ==="

# 1. Disable plugin and restore default lock
if command -v omarchy >/dev/null 2>&1; then
  echo "Disabling plugin in Omarchy..."
  omarchy plugin disable omarchy-smart-enter 2>/dev/null || true
  omarchy plugin disable rbm.lock 2>/dev/null || true
  omarchy plugin enable omarchy.lock 2>/dev/null || true
fi

# 2. Remove plugin files
if [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
  echo "✓ Removed $TARGET_DIR"
fi

if [ -d "$LEGACY_DIR" ]; then
  rm -rf "$LEGACY_DIR"
  echo "✓ Removed $LEGACY_DIR"
fi

# 3. Remove CLI binary
if [ -f "$BIN_FILE" ]; then
  rm -f "$BIN_FILE"
  echo "✓ Removed $BIN_FILE"
fi

# 4. Remove configuration
rm -f "$CONFIG_FILE" "$LEGACY_CONFIG"
echo "✓ Removed configuration files"

# 5. Clear kernel keyring session entry
if command -v keyctl >/dev/null 2>&1; then
  KEY_ID=$(keyctl search @s user omarchy:smart_enter 2>/dev/null || true)
  if [ -n "$KEY_ID" ]; then
    keyctl unlink "$KEY_ID" @s >/dev/null 2>&1 || true
    echo "✓ Purged session keyring"
  fi
fi

# 6. Rescan plugins and restart shell
if command -v omarchy >/dev/null 2>&1; then
  echo "Restarting Omarchy shell..."
  omarchy-shell -q shell rescanPlugins 2>/dev/null || true
  omarchy restart shell 2>/dev/null || true
fi

echo "=== Uninstallation complete! ==="
