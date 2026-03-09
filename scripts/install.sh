#!/bin/bash
# =============================================================================
# Oracle Forms Migration Skill — Installer
# Copia el skill a ~/.claude/skills/ para que esté disponible en Claude Code
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SRC="$REPO_DIR/skills/oracle-forms-migration"
SKILL_DST="$HOME/.claude/skills/oracle-forms-migration"

echo "=== Oracle Forms Migration Skill — Instalador ==="
echo ""

# 1. Verificar Java
echo "[1/4] Verificando Java..."
JAVA_CMD=""
if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/java" ]; then
  JAVA_CMD="$JAVA_HOME/bin/java"
elif command -v java &>/dev/null; then
  JAVA_CMD="java"
else
  # Buscar en paths comunes
  for d in \
    "/c/Program Files/Java/jdk"*/bin \
    "/c/Program Files/Eclipse Adoptium/jdk"*/bin \
    "/c/Oracle/Middleware/Oracle_Home/oracle_common/jdk/bin" \
    "/usr/lib/jvm/java-"*/bin \
    "/usr/local/opt/openjdk/bin"; do
    if [ -f "$d/java" ] || [ -f "$d/java.exe" ]; then
      JAVA_CMD="$d/java"
      break
    fi
  done
fi

if [ -z "$JAVA_CMD" ]; then
  echo "  ADVERTENCIA: Java no encontrado."
  echo "  frmf2xml y rdf2xml requieren Java 8+."
  echo "  Opciones:"
  echo "    - Instalar: https://adoptium.net/temurin/releases/"
  echo "    - O setear JAVA_HOME antes de usar los conversores"
  echo ""
else
  JAVA_VER=$("$JAVA_CMD" -version 2>&1 | head -1)
  echo "  OK: $JAVA_VER"
fi

# 2. Verificar Claude Code
echo "[2/4] Verificando Claude Code..."
if [ -d "$HOME/.claude" ]; then
  echo "  OK: ~/.claude encontrado"
else
  echo "  ERROR: ~/.claude no existe. Instalá Claude Code primero:"
  echo "  https://docs.anthropic.com/en/docs/claude-code/getting-started"
  exit 1
fi

# 3. Instalar skill
echo "[3/4] Instalando skill en $SKILL_DST..."
mkdir -p "$SKILL_DST"

# Copiar todo
cp -r "$SKILL_SRC/"* "$SKILL_DST/"

# Hacer ejecutables los scripts
chmod +x "$SKILL_DST/tools/frmf2xml/convert.sh" 2>/dev/null || true
chmod +x "$SKILL_DST/tools/rdf2xml/convert.sh" 2>/dev/null || true

echo "  OK: Skill instalado"

# 4. Verificar
echo "[4/4] Verificando instalación..."
ERRORS=0

if [ ! -f "$SKILL_DST/SKILL.md" ]; then
  echo "  ERROR: SKILL.md no encontrado"; ERRORS=$((ERRORS+1))
fi
if [ ! -f "$SKILL_DST/tools/frmf2xml/frmxmltools.jar" ]; then
  echo "  ERROR: frmxmltools.jar no encontrado"; ERRORS=$((ERRORS+1))
fi
if [ ! -f "$SKILL_DST/tools/rdf2xml/rdf2xml.jar" ]; then
  echo "  ERROR: rdf2xml.jar no encontrado"; ERRORS=$((ERRORS+1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "  OK: Todo verificado"
else
  echo "  ADVERTENCIA: $ERRORS errores encontrados"
fi

echo ""
echo "=== Instalación completada ==="
echo ""
echo "Uso:"
echo "  1. Abrí Claude Code en cualquier proyecto"
echo "  2. Escribí: /oracle-forms-migration"
echo "  3. Seguí las instrucciones del agente"
echo ""
echo "Prerequisitos para conversión:"
echo "  - Java 8+ instalado (para frmf2xml y rdf2xml)"
echo "  - Oracle APEX MCP Server configurado (para operaciones DB/APEX)"
echo "    Ver: https://github.com/silviosotelo/oracle-apex-mcp-server"
