#!/bin/bash
# claude-think — installer
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/claude-think"
STATE_DIR="$HOME/.claude/state"
SETTINGS="$HOME/.claude/settings.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo "  🧠 claude-think installer"
echo "  ──────────────────────────"
echo ""

# --- Prerequisites ---
command -v jq  >/dev/null 2>&1 || fail "jq is required. Install with: brew install jq"
command -v python3 >/dev/null 2>&1 || fail "python3 is required."
[ -f "$SETTINGS" ] || fail "~/.claude/settings.json not found. Is Claude Code installed?"

# --- Copy scripts ---
info "Installing scripts to $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
cp "$REPO_DIR/scripts/think-toggle.sh" "$CONFIG_DIR/"
cp "$REPO_DIR/scripts/think-hook.sh"   "$CONFIG_DIR/"
cp "$REPO_DIR/scripts/statusline.sh"   "$CONFIG_DIR/"
chmod +x "$CONFIG_DIR"/*.sh
ok "Scripts installed"

# --- State file ---
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE_DIR/think-mode.json" ]; then
  CURRENT_MODEL=$(jq -r '.model // "claude-sonnet-4-6"' "$SETTINGS" 2>/dev/null)
  echo "{\"mode\":\"off\",\"previous_model\":\"$CURRENT_MODEL\"}" > "$STATE_DIR/think-mode.json"
  ok "State file created"
else
  warn "State file already exists — skipped"
fi

# --- think command ---
THINK_BIN=""
for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
  if [ -d "$dir" ] && [ -w "$dir" ]; then
    THINK_BIN="$dir/think"
    break
  fi
done

if [ -n "$THINK_BIN" ]; then
  cat > "$THINK_BIN" << EOF
#!/bin/bash
bash "$CONFIG_DIR/think-toggle.sh"
EOF
  chmod +x "$THINK_BIN"
  ok "Command installed: $THINK_BIN"
else
  mkdir -p "$HOME/.local/bin"
  THINK_BIN="$HOME/.local/bin/think"
  cat > "$THINK_BIN" << EOF
#!/bin/bash
bash "$CONFIG_DIR/think-toggle.sh"
EOF
  chmod +x "$THINK_BIN"
  warn "Installed to ~/.local/bin/think — add to PATH if needed:"
  warn "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
fi

# --- Patch settings.json ---
info "Patching ~/.claude/settings.json"

python3 - "$SETTINGS" "$CONFIG_DIR" << 'PY'
import json, sys

settings_path = sys.argv[1]
config_dir    = sys.argv[2]

with open(settings_path) as f:
    d = json.load(f)

# statusLine
if 'statusLine' not in d:
    d['statusLine'] = {
        "type": "command",
        "command": f"bash {config_dir}/statusline.sh",
        "padding": 0
    }
    print("  ✓ statusLine added")
else:
    print("  ! statusLine already set — skipped (edit manually if needed)")

# hooks.UserPromptSubmit
hooks = d.setdefault('hooks', {})
ups   = hooks.setdefault('UserPromptSubmit', [])

hook_cmd = f"bash {config_dir}/think-hook.sh"
already  = any(
    any(h.get('command') == hook_cmd for h in e.get('hooks', []))
    for e in ups
)
if not already:
    ups.append({"hooks": [{"type": "command", "command": hook_cmd}]})
    print("  ✓ UserPromptSubmit hook added")
else:
    print("  ! UserPromptSubmit hook already present — skipped")

with open(settings_path, 'w') as f:
    json.dump(d, f, indent=2)
PY

ok "settings.json patched"

echo ""
echo "  ✅ Done! Restart Claude Code to activate."
echo ""
echo "  Usage (in Claude Code prompt):"
echo "    !think          cycle mode: off → think_light → think_PRD → off"
echo ""
echo "  Statusline:"
echo "    ○ think         reasoning off"
echo "    ⚡ think_light   deep reasoning, no tool use"
echo "    ◉ think_PRD     structured discovery interview"
echo ""
