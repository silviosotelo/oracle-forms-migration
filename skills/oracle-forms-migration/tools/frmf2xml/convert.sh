#!/bin/bash
# Forms2XML converter — auto-detects Java
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-detect JAVA_HOME
find_java() {
  # 1. JAVA_HOME already set
  if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/java" ]; then
    echo "$JAVA_HOME/bin/java"; return
  fi
  # 2. java in PATH
  if command -v java &>/dev/null; then
    echo "java"; return
  fi
  # 3. Common Windows locations
  for d in /c/Program\ Files/Java/jdk* /c/Program\ Files/Eclipse\ Adoptium/jdk* /c/Oracle/Middleware/Oracle_Home/oracle_common/jdk; do
    if [ -f "$d/bin/java" ] || [ -f "$d/bin/java.exe" ]; then
      echo "$d/bin/java"; return
    fi
  done
  # 4. Common Linux/Mac
  for d in /usr/lib/jvm/java-*/bin /usr/local/opt/openjdk/bin; do
    if [ -f "$d/java" ]; then
      echo "$d/java"; return
    fi
  done
  echo ""
}

JAVA=$(find_java)
if [ -z "$JAVA" ]; then
  echo "ERROR: No se encontró Java. Instala un JDK 8+ o setea JAVA_HOME." >&2
  exit 1
fi

if [ -z "$1" ]; then
  echo "Uso: $0 <archivo.fmb>" >&2
  exit 1
fi

"$JAVA" -classpath "$TOOLS_DIR/frmxmltools.jar;$TOOLS_DIR/frmjdapi.jar;$TOOLS_DIR/xmlparserv2.jar" oracle.forms.util.xmltools.Forms2XML "$@"
