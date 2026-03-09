# Oracle Forms to APEX Migration Skill

Skill de [Claude Code](https://docs.anthropic.com/en/docs/claude-code) para migración autónoma de Oracle Forms 6i a Oracle APEX, con soporte para Oracle Reports via JasperReports Server.

Se invoca con `/oracle-forms-migration` dentro de Claude Code y el agente se encarga del resto.

## Qué hace

- **Convierte .fmb a XML** usando frmf2xml (JARs bundled, no necesita Oracle Forms instalado)
- **Convierte .rdf a XML** usando rdf2xml (JAR + dependencias bundled)
- **Analiza el XML** y extrae bloques, items, triggers, LOVs, program units
- **Descubre tablas reales** en la base de datos (los schemas legacy usan nombres abreviados)
- **Genera paquetes PL/SQL** — un solo PKG_\<ENTITY\> por entidad, con BULK operations
- **Crea páginas APEX programáticamente** — IR (listado con filtros) + Form (modal CRUD)
- **Genera JRXML** para JasperReports Server desde Oracle Reports
- **Integra reportes en APEX** via AJAX callbacks

## Requisitos

| Requisito | Para qué | Cómo instalar |
|-----------|----------|---------------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Runtime del skill | `npm install -g @anthropic-ai/claude-code` |
| Java 8+ | Conversión .fmb y .rdf | [Eclipse Temurin](https://adoptium.net/temurin/releases/) |
| [Oracle APEX MCP Server](https://github.com/silviosotelo/oracle-apex-mcp-server) | Operaciones DB + APEX | Ver su README |

> **Nota**: Los JARs de frmf2xml y rdf2xml ya están incluidos en el skill. No necesitás tener Oracle Forms ni Oracle Reports instalados.

## Instalación

### Opción 1: Script automático (recomendado)

```bash
git clone https://github.com/silviosotelo/oracle-forms-migration.git
cd oracle-forms-migration

# Linux/Mac/Git Bash
bash scripts/install.sh

# Windows CMD
scripts\install.bat
```

El instalador:
1. Verifica que Java esté disponible
2. Verifica que Claude Code esté instalado
3. Copia el skill a `~/.claude/skills/oracle-forms-migration/`
4. Verifica que todo esté en su lugar

### Opción 2: Manual

```bash
git clone https://github.com/silviosotelo/oracle-forms-migration.git
mkdir -p ~/.claude/skills
cp -r oracle-forms-migration/skills/oracle-forms-migration ~/.claude/skills/
```

### Opción 3: One-liner

```bash
git clone https://github.com/silviosotelo/oracle-forms-migration.git && bash oracle-forms-migration/scripts/install.sh
```

## Uso

### 1. Configurar el MCP Server

El skill usa el [Oracle APEX MCP Server](https://github.com/silviosotelo/oracle-apex-mcp-server) para conectarse a la base de datos y operar sobre APEX. Configurá el MCP en tu `~/.claude/mcp.json`:

```json
{
  "mcpServers": {
    "oracle-apex": {
      "command": "node",
      "args": ["/ruta/a/oracle-apex-mcp-server/dist/index.js"],
      "env": {
        "ORACLE_CLIENT_LIB_DIR": "/ruta/a/instantclient",
        "TNS_ADMIN": "/ruta/a/tns/admin"
      }
    }
  }
}
```

### 2. Invocar el skill

Abrí Claude Code en cualquier directorio y escribí:

```
/oracle-forms-migration
```

El agente te va a guiar. Ejemplos de lo que podés pedirle:

```
Migrá el formulario FORMA_827.fmb que está en C:\Forms\

Analizá el XML de FORMA_6201.xml y decime qué bloques y triggers tiene

Convertí el reporte REP_ORDEN_PAGO.rdf a JasperReports

Creá la página APEX para la tabla ORDEN_PAGO con IR + Form modal
```

### 3. Workflow típico de migración

El agente sigue estos pasos automáticamente:

1. **Convertir**: `.fmb` → XML usando frmf2xml bundled
2. **Analizar**: Extraer metadata del XML (bloques, items, triggers, LOVs)
3. **Descubrir**: Verificar tablas/columnas reales en la base de datos via MCP
4. **Generar PL/SQL**: Crear `PKG_<ENTITY>` con queries, DML, validaciones
5. **Crear páginas**: IR (listado) + Form (modal CRUD) programáticamente via MCP
6. **Verificar**: Confirmar que todo se creó correctamente

## Estructura del skill

```
skills/oracle-forms-migration/
├── SKILL.md                          # Instrucciones principales del agente
├── references/
│   ├── apex-internals.md             # Tablas wwv_flow_*, errores comunes
│   ├── forms-mapping.md              # Mapeo completo Forms -> APEX
│   └── jasperreports.md              # Integración JasperReports + APEX
├── templates/
│   └── package-template.sql          # Template de paquete PL/SQL
└── tools/
    ├── frmf2xml/                     # Forms2XML (bundled)
    │   ├── convert.sh                # Script con auto-detección de Java
    │   ├── frmxmltools.jar
    │   ├── frmjdapi.jar
    │   └── xmlparserv2.jar
    └── rdf2xml/                      # RDF2XML (bundled)
        ├── convert.sh
        ├── rdf2xml.jar
        └── lib/                      # 16 dependencias
```

## Patrones de migración

### Arquitectura de páginas (obligatorio)
- **Siempre** IR (listado con filtros) → Form (modal para CRUD)
- **Nunca** Form como página principal

### Paquetes PL/SQL
- **Un solo paquete por entidad** (`PKG_ORDEN_PAGO`, no `PKG_ORD_PAGO_LECTURA` + `PKG_ORD_PAGO_ESCRITURA`)
- Queries + DML + validaciones + lógica de negocio en el mismo paquete
- BULK operations (FORALL, BULK COLLECT) — nunca row-by-row loops
- Sin COMMIT interno — APEX controla la transacción

### Estilo visual
- Regions con borde: `region-con-bordes borde-primario`
- Items: template Optional-Floating
- CSS: `#WORKSPACE_IMAGES#template-floating-minimalista.css`
- Montos: `TO_CHAR(col, 'FM999G999G999G990D00')`

## Versiones soportadas

| APEX | DB Oracle | Notas |
|------|-----------|-------|
| 19.2 | 11.2+ | Base |
| 20.2 | 11.2+ | Recomendada para migraciones conservadoras |
| 21.2 | 12.1+ | Cards, Friendly URLs |
| 22.2 | 12.1+ | Approvals, Map |
| 23.2 | 19c+ | Workflow, PWA |
| 24.2 | 19c+ | AI Assistant |

## Desinstalación

```bash
bash scripts/uninstall.sh
# O manual:
rm -rf ~/.claude/skills/oracle-forms-migration
```

## Contribuir

1. Fork del repo
2. Crear branch (`git checkout -b feature/mi-mejora`)
3. Commit (`git commit -m 'Agrega soporte para X'`)
4. Push (`git push origin feature/mi-mejora`)
5. Pull Request

## Licencia

MIT

## Links

- [Oracle APEX MCP Server](https://github.com/silviosotelo/oracle-apex-mcp-server) — MCP server para operaciones DB + APEX
- [Oracle APEX Skills](https://github.com/silviosotelo/oracle-apex-skills) — Skills de desarrollo APEX (complementario)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Documentación oficial
- [Eclipse Temurin JDK](https://adoptium.net/temurin/releases/) — JDK recomendado
