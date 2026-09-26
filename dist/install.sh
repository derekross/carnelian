#!/bin/bash

# Install Carnelian for the current user: the command on PATH and the entries
# in the Omarchy Share menu. Safe to rerun.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
BIN_DIR="$HOME/.local/bin"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

missing=()
for cmd in nak jq python3 hyprctl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing: ${missing[*]}"
    [[ " ${missing[*]} " == *" nak "* ]] && echo "Install nak with: omarchy pkg aur add nak-bin"
    exit 1
fi
python3 -c 'import yaml' 2>/dev/null || { echo "Missing python-yaml. Install with: omarchy pkg add python-yaml"; exit 1; }

mkdir -p "$BIN_DIR"
ln -sfn "$ROOT/carnelian" "$BIN_DIR/carnelian"
chmod +x "$ROOT/carnelian"
echo "Linked $BIN_DIR/carnelian -> $ROOT/carnelian"

# Share menu entries. The menu file is JSONC with comments, so the entries
# are inserted as text before the closing brace, once.
if [[ -f $MENU ]] && grep -q '"trigger.share.carnelian"' "$MENU"; then
    echo "Share menu entries already present in $MENU"
elif [[ -f $MENU ]]; then
    cp "$MENU" "$MENU.bak.carnelian"
    python3 - "$MENU" dist/omarchy-menu.jsonc <<'PY'
import sys
menu, snippet = sys.argv[1], sys.argv[2]
text = open(menu).read()
entries = open(snippet).read()
end = text.rstrip().rfind("}")
if end < 0:
    sys.exit("menu file has no closing brace")
head = text[:end].rstrip()
if head.endswith("{") or head.endswith(","):
    body = head + "\n"
else:
    body = head + ",\n"
open(menu, "w").write(body + entries + text[end:])
PY
    echo "Added Publish to Nostr to the Share menu ($MENU, backup at $MENU.bak.carnelian)"
else
    mkdir -p "$(dirname "$MENU")"
    { echo "{"; cat dist/omarchy-menu.jsonc; echo "}"; } >"$MENU"
    echo "Created $MENU with the Share menu entries"
fi

echo ""
if command -v opal >/dev/null 2>&1; then
    echo "Next: carnelian setup    (pairs with Opal so publishing needs no key prompt)"
else
    echo "Next: set NOSTR_SECRET_KEY, or let nak prompt for a key on each publish."
fi
echo "Then, from Omawrite: Super + Ctrl + S -> Publish to Nostr."
