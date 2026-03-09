#!/bin/bash
# RDF2XML converter — auto-detects Java
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-detect JAVA_HOME
find_java() {
  if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/bin/java" ]; then
    echo "$JAVA_HOME/bin/java"; return
  fi
  if command -v java &>/dev/null; then
    echo "java"; return
  fi
  for d in /c/Program\ Files/Java/jdk* /c/Program\ Files/Eclipse\ Adoptium/jdk* /c/Oracle/Middleware/Oracle_Home/oracle_common/jdk; do
    if [ -f "$d/bin/java" ] || [ -f "$d/bin/java.exe" ]; then
      echo "$d/bin/java"; return
    fi
  done
  echo ""
}

JAVA=$(find_java)
if [ -z "$JAVA" ]; then
  echo "ERROR: No se encontró Java. Instala un JDK 8+ o setea JAVA_HOME." >&2
  exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Uso: $0 <input.rdf> <output.xml>" >&2
  exit 1
fi

CP="$TOOLS_DIR/rdf2xml.jar"
for jar in "$TOOLS_DIR/lib/"*.jar; do
  CP="$CP;$jar"
done

"$JAVA" -classpath "$CP" oracle.reports.utility.Rdf2Xml "$1" "$2"
