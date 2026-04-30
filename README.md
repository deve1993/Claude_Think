<div align="center">

# 🧠 claude-think

**Reasoning modes + live statusline for [Claude Code](https://claude.ai/code)**

Switch Claude into deep reasoning or structured discovery mode with a single command.  
Always know your context at a glance.

---

```
MASTER_Fullstack (main) | Sonnet 4.6 | ctx:8% | ○ think
MASTER_Fullstack (main) | Opus 4.6   | ctx:8% | ⚡ think_light
MASTER_Fullstack (main) | Opus 4.6   | ctx:8% | ◉ think_PRD
```

</div>

---

## What it does

**claude-think** adds two things to Claude Code:

### 1 — Reasoning modes

Three states, cycled with `!think`:

| Mode | Symbol | Model | Behaviour |
|------|--------|-------|-----------|
| `off` | `○` | your default | Normal Claude Code |
| `think_light` | `⚡` | Opus (auto) | Reasoning only — no code execution, no file writes |
| `think_PRD` | `◉` | Opus (auto) | Structured discovery interview → writes one spec `.md` |

The model switches **automatically** when you activate a mode and **restores** when you return to `off`. No manual model switching needed.

### 2 — Live statusline

A persistent status bar showing:

```
project (branch) | Model | ctx:N% | [rate limits] | think mode
```

Always visible. Updates after every message.

---

## Install

**Prerequisites:** `jq`, `python3`, Claude Code with `~/.claude/settings.json`

```bash
git clone https://github.com/YOUR_USERNAME/claude-think.git
cd claude-think
bash install.sh
```

Restart Claude Code. Done.

> The installer patches `~/.claude/settings.json` to add the statusline and the prompt hook.  
> Your existing settings are preserved — it only adds what's missing.

---

## Usage

Type this in the Claude Code prompt:

```
!think
```

Each call advances the cycle:

```
!think   →  off → think_light    (switches to Opus, enables reasoning mode)
!think   →  think_light → think_PRD   (stays on Opus, enables PRD mode)
!think   →  think_PRD → off      (restores your original model)
```

The statusline updates immediately after your next message.

---

## How it works

```
~/.config/claude-think/
├── think-toggle.sh    ← cycles mode, patches ~/.claude/settings.json model field
├── think-hook.sh      ← UserPromptSubmit hook — injects system context per mode
└── statusline.sh      ← reads Claude Code JSON from stdin, renders status bar

~/.claude/state/
└── think-mode.json    ← { "mode": "off", "previous_model": "sonnet" }
```

### Mode injection

When a mode is active, every prompt you send is prefixed with a hidden system message:

**think_light:**
```
[THINK LIGHT MODE] You are in pure reasoning mode. Do not execute code,
write files, or run commands. Only analyze, reason, and plan deeply.
```

**think_PRD:**
```
[THINK PRD MODE] You are a conversational discovery agent. Interview the
user with structured questions. Do not build anything. Write ONE spec .md
file at the end.
```

This is done via the `UserPromptSubmit` hook in `~/.claude/settings.json` — Claude Code calls the hook script before each message and injects the output as additional context.

### Model switching

`think-toggle.sh` directly edits the `model` field in `~/.claude/settings.json`:

- **Activating** a mode → saves your current model, writes `claude-opus-4-6`
- **Returning to off** → restores the saved model

Claude Code re-reads `settings.json` on every request, so the switch is instant — no session restart needed.

---

## Statusline fields

| Field | Source |
|-------|--------|
| `project (branch)` | `cwd` basename + `git rev-parse HEAD` |
| `Model X.Y` | `model.display_name` from Claude Code JSON |
| `ctx:N%` | `context_window.used_percentage` — turns `(!)` above 80% |
| `5h:N% 7d:N%` | Rate limit usage (hidden if not available) |
| `○ / ⚡ / ◉` | `~/.claude/state/think-mode.json` |

---

## Customisation

### Change the PRD prompt

Edit `~/.config/claude-think/think-hook.sh` and replace the `think_PRD` context string with your own discovery flow.

### Change the Opus model

Edit `~/.config/claude-think/think-toggle.sh` and replace `claude-opus-4-6` with any model ID supported by your Claude Code subscription.

### Add more modes

The cycle is defined in the `case` block inside `think-toggle.sh`. Add a new state between `think_PRD` and `off`, then add its label in `statusline.sh` and its injected context in `think-hook.sh`.

---

## Uninstall

```bash
# Remove scripts
rm -rf ~/.config/claude-think

# Remove think command
rm -f /opt/homebrew/bin/think   # or wherever it was installed

# Remove state
rm -f ~/.claude/state/think-mode.json

# Remove from settings.json
# Edit ~/.claude/settings.json and remove:
#   - statusLine key (if added by claude-think)
#   - the UserPromptSubmit hook entry pointing to think-hook.sh
```

---

## Requirements

- [Claude Code](https://claude.ai/code) (any plan)
- `jq` — `brew install jq`
- `python3` — comes with macOS
- macOS (Linux support: swap `/opt/homebrew/bin` for `/usr/local/bin` in install.sh)

---

<div align="center">

Made for Claude Code power users who think before they build.

</div>
