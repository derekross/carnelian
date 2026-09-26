#!/bin/bash

# Remove the Carnelian command and its Share menu entries. Keeps ~/.config/carnelian
# (the Opal pairing) unless --purge is given.

set -euo pipefail

BIN="$HOME/.local/bin/carnelian"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
CONFIG_DIR="$HOME/.config/carnelian"

[ -L "$BIN" ] && rm -f "$BIN" && echo "Removed $BIN"

if [[ -f $MENU ]] && grep -q '"trigger.share.carnelian' "$MENU"; then
    cp "$MENU" "$MENU.bak.carnelian"
    grep -v -E '"trigger\.share\.carnelian|Carnelian: publish the Omawrite|is the focused window\. Installed by dist/install\.sh' "$MENU" >"$MENU.tmp"
    mv "$MENU.tmp" "$MENU"
    echo "Removed the Share menu entries from $MENU (backup at $MENU.bak.carnelian)"
fi

if [[ "${1:-}" == "--purge" && -d $CONFIG_DIR ]]; then
    rm -rf "$CONFIG_DIR"
    echo "Removed $CONFIG_DIR. Revoke 'Carnelian' in Opal's Apps list to finish."
fi
