#!/bin/bash
# claude-think — mode toggle
# Cycles: off → think_light → think_PRD → off
# Saves and restores the model in ~/.claude/settings.json on each transition.

STATE="$HOME/.claude/state/think-mode.json"
SETTINGS="$HOME/.claude/settings.json"

CURRENT_MODE=$(jq -r '.mode // "off"' "$STATE" 2>/dev/null)
PREV_MODEL=$(jq -r '.previous_model // "claude-sonnet-4-6"' "$STATE" 2>/dev/null)

case "$CURRENT_MODE" in
  "off")         NEXT_MODE="think_light" ;;
  "think_light") NEXT_MODE="think_PRD"   ;;
  "think_PRD")   NEXT_MODE="off"         ;;
  *)             NEXT_MODE="think_light" ;;
esac

if [ "$NEXT_MODE" = "off" ]; then
  jq --arg model "$PREV_MODEL" '.model = $model' "$SETTINGS" > /tmp/ct-settings.json \
    && mv /tmp/ct-settings.json "$SETTINGS"
  jq '.mode = "off"' "$STATE" > /tmp/ct-state.json \
    && mv /tmp/ct-state.json "$STATE"
else
  if [ "$CURRENT_MODE" = "off" ]; then
    CURRENT_MODEL=$(jq -r '.model // "claude-sonnet-4-6"' "$SETTINGS" 2>/dev/null)
    NEW_PREV="$CURRENT_MODEL"
  else
    NEW_PREV="$PREV_MODEL"
  fi
  jq '.model = "claude-opus-4-6"' "$SETTINGS" > /tmp/ct-settings.json \
    && mv /tmp/ct-settings.json "$SETTINGS"
  jq --arg mode "$NEXT_MODE" --arg prev "$NEW_PREV" \
    '.mode = $mode | .previous_model = $prev' "$STATE" > /tmp/ct-state.json \
    && mv /tmp/ct-state.json "$STATE"
fi

echo "think: $CURRENT_MODE → $NEXT_MODE"
