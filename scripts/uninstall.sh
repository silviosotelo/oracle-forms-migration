#!/bin/bash
# Desinstalar el skill
SKILL_DIR="$HOME/.claude/skills/oracle-forms-migration"

if [ -d "$SKILL_DIR" ]; then
  rm -rf "$SKILL_DIR"
  echo "Skill oracle-forms-migration desinstalado."
else
  echo "Skill no encontrado en $SKILL_DIR"
fi
