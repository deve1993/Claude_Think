#!/bin/bash
# claude-think — UserPromptSubmit hook
# Injects system context based on the active think mode.
# Output must be valid JSON: { "additionalContext": "..." }

STATE="$HOME/.claude/state/think-mode.json"
MODE=$(jq -r '.mode // "off"' "$STATE" 2>/dev/null)

case "$MODE" in
  "think_light")
    printf '{"additionalContext": "[THINK LIGHT MODE] You are in pure reasoning mode. Do not execute code, write files, or run commands. Only analyze, reason, and plan. Be thorough and think deeply before responding."}'
    ;;
  "think_PRD")
    printf '{"additionalContext": "[THINK PRD MODE] You are a conversational discovery agent. Interview the user with structured questions to understand their project. Do not build anything. At the end, write ONE project spec .md file summarizing all decisions."}'
    ;;
  *)
    exit 0
    ;;
esac
