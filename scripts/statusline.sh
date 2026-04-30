#!/bin/bash
# claude-think — Claude Code statusline renderer
# Receives JSON from Claude Code via stdin, prints a formatted status line.
#
# Output format:
#   project (branch) | Model X.Y | ctx:N% | ○ think
#   project (branch) | Model X.Y | ctx:N% | ⚡ think_light
#   project (branch) | Model X.Y | ctx:N% | ◉ think_PRD

THINK_STATE="$HOME/.claude/state/think-mode.json"

python3 - "$THINK_STATE" <<'PY' 2>/dev/null || printf ' ready'
import json, sys, os, subprocess

THINK_STATE_PATH = sys.argv[1] if len(sys.argv) > 1 else ''

try:
    raw = sys.stdin.read()
    d = json.loads(raw) if raw.strip() else {}
except Exception:
    d = {}

# --- Working directory ---
cwd = d.get('workspace', {}).get('current_dir') or d.get('cwd', '') or ''
dir_name = os.path.basename(cwd) if cwd else ''

# --- Git branch ---
branch = ''
if cwd and os.path.isdir(cwd):
    try:
        r = subprocess.run(
            ['git', '-C', cwd, '--no-optional-locks', 'rev-parse', '--abbrev-ref', 'HEAD'],
            capture_output=True, text=True, timeout=1
        )
        branch = r.stdout.strip() if r.returncode == 0 else ''
    except Exception:
        branch = ''

# --- Model ---
model_name = d.get('model', {}).get('display_name', '') or ''
if model_name.startswith('Claude '):
    model_name = model_name[len('Claude '):]

# --- Context window ---
ctx = d.get('context_window', {})
used_pct = ctx.get('used_percentage')
ctx_str = ''
if used_pct is not None:
    u = round(used_pct)
    ctx_str = f'ctx:{u}%' + (' (!)' if u >= 80 else '')

# --- Rate limits ---
rate_parts = []
rl = d.get('rate_limits', {})
five = rl.get('five_hour', {})
week = rl.get('seven_day', {})
if five.get('used_percentage') is not None:
    rate_parts.append(f"5h:{round(five['used_percentage'])}%")
if week.get('used_percentage') is not None:
    rate_parts.append(f"7d:{round(week['used_percentage'])}%")

# --- Think mode ---
think_label = '○ think'
if THINK_STATE_PATH and os.path.isfile(THINK_STATE_PATH):
    try:
        ts = json.load(open(THINK_STATE_PATH))
        m = ts.get('mode', 'off')
        if m == 'think_light':
            think_label = '⚡ think_light'
        elif m == 'think_PRD':
            think_label = '◉ think_PRD'
    except Exception:
        pass

# --- Assemble ---
parts = []
if dir_name:
    loc = dir_name
    if branch and branch != 'HEAD':
        loc += f' ({branch})'
    parts.append(loc)
if model_name:
    parts.append(model_name)
if ctx_str:
    parts.append(ctx_str)
if rate_parts:
    parts.append(' '.join(rate_parts))
parts.append(think_label)

print(' | '.join(parts) if parts else 'ready', end='')
PY
