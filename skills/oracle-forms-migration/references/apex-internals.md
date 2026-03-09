# APEX 20.2 Internal Tables (wwv_flow_*)

## ID Generation
```sql
SELECT wwv_flow_id.next_val INTO v_id FROM DUAL;
```
Nunca inline en VALUES. Nunca hardcodear IDs de JSON (precision loss con 18+ dígitos).

## Workspace Context
```sql
apex_util.set_security_group_id(<workspace_id>);
```
Siempre antes de cualquier operación.

## UPDATE/DELETE seguro
Usar `WHERE page_id=X AND plug_source_type='Y'` — nunca `WHERE id=<big_number>`.

## wwv_flow_steps (Pages)

| Column | Valor | Notas |
|--------|-------|-------|
| user_interface_id | (resolver dinámicamente) | **SIN ESTO LA PÁGINA ES INVISIBLE** |
| page_component_map | '18' / '02' / '03' | IR / Form-Modal / Blank |
| step_title | 'Título' | Mismo que name |
| alias | 'PAGE-ALIAS' | Kebab-case, SIEMPRE setear |
| page_mode | 'NORMAL' / 'MODAL' | |
| step_template | NULL / (modal dialog tmpl) | NULL normal, template para modal |
| include_apex_css_js_yn | 'Y' | |
| first_item | 'NO_FIRST_ITEM' | |
| reload_on_submit | 'S' | |
| warn_on_unsaved_changes | 'Y' | |
| autocomplete_on_off | 'OFF' | |
| css_file_urls | '#WORKSPACE_IMAGES#template-floating-minimalista.css' | |

## wwv_flow_page_plugs (Regions)

**NOT NULL obligatorios:**
- `translate_title`: 'Y'
- `include_in_reg_disp_sel_yn`: 'Y' o 'N'
- `plug_customized`: 0
- `plug_caching`: 'NOCACHE'
- `security_group_id`: workspace ID

**Region Types (plug_source_type):**
- `NATIVE_STATIC` = Static Content (Filtros, Botones, Title Bar)
- `NATIVE_IR` = Interactive Report
- `NATIVE_FORM` = Form Region (DML)
- `NATIVE_BREADCRUMB` = Breadcrumb (necesita menu_id!)
- **NUNCA** `NATIVE_DISPLAY_STATIC` — causa ORA-01403

**NATIVE_STATIC attributes:**
- attribute_01 = 'N', attribute_02 = 'TEXT', attribute_03 = 'Y'

**NATIVE_FORM DEBE tener:**
- query_type = 'TABLE', query_table = 'TABLE_NAME', is_editable = 'Y'
- attribute_01 a attribute_05 = NULL
- plug_query_options = NULL

**Dialog Footer (para botones en modal):**
- plug_display_point = 'REGION_POSITION_03'

## wwv_flow_step_items (Page Items)

**NOT NULL obligatorios:**
- `data_type`: 'VARCHAR' (NO 'VARCHAR2')
- `is_primary_key`: 'Y' o 'N'
- `is_query_only`: 'N'
- `protection_level`: 'N'

**Para items en NATIVE_FORM:**
- `item_source_plug_id` DEBE apuntar al region ID del NATIVE_FORM
  - Sin esto -> NO_PRIMARY_KEY_ITEM error
- `source`: nombre de columna en la tabla
- `source_data_type`: tipo Oracle (NUMBER, VARCHAR2, DATE)
- `item_field_template`: (resolver Optional-Floating dinámicamente)
- `prompt`: SIEMPRE setear para items visibles

## wwv_flow_worksheets (IR)

- FK a region via `region_id`
- `detail_link`: URL con `#COLUMN#` substitutions
- `detail_link_text`: `<img src="#IMAGE_PREFIX#app_ui/img/icons/apex-edit-pencil.png" class="apex-edit-pencil" alt="">`
- **NUNCA** insertar `UNIQUELY_IDENTIFY_ROWS_BY` — es columna virtual (ORA-54013)

**detail_link format:**
```
f?p=&APP_ID.:<form_page>:&SESSION.::&DEBUG.:RP,<form_page>:P<form_page>_<PK>:#PK_COLUMN#
```

## wwv_flow_worksheet_columns

- `db_column_name`: DEBE coincidir EXACTO con alias SQL (case-sensitive)
- `column_type`: 'NUMBER', 'STRING' (para TO_CHAR), 'DATE'
- `display_as`: 'TEXT'
- `display_text_as`: 'ESCAPE_SC' o 'WITHOUT_MODIFICATION' (para HTML)
- `lov_display_null`: 'YES'/'NO' (NO 'Y'/'N')
- **Cantidad de columnas DEBE coincidir EXACTO con el SELECT** — mismatch = ORA-01403
- **NUNCA** crear columna 'LINK' — usar native detail_link

## wwv_flow_worksheet_rpts (Default Reports)
- `application_user = 'APXWS_DEFAULT'`, `is_default = 'Y'`
- `report_columns`: colon-separated

## wwv_flow_step_processing (Processes)

| Tipo | process_point | attribute_01 | region_id |
|------|--------------|--------------|-----------|
| NATIVE_FORM_INIT | BEFORE_HEADER | NULL | form region |
| NATIVE_FORM_DML | AFTER_SUBMIT | 'REGION_SOURCE' | form region |
| NATIVE_CLOSE_WINDOW | AFTER_SUBMIT | 'REQUEST' | NULL |

## wwv_flow_page_da_events (Dynamic Actions)
- `bind_type = 'bind'` (NOT NULL obligatorio)
- `triggering_element_type`: 'BUTTON', 'JQUERY_SELECTOR', 'ITEM', 'REGION'

## wwv_flow_page_da_actions
- `event_result = 'TRUE'` (NOT NULL obligatorio)

## Template IDs
Resolver dinámicamente con:
```sql
SELECT template_id, template_name FROM apex_application_templates
WHERE application_id = :app_id AND template_type = 'Region';
```

## IR Programático — Checklist
Crear IR requiere los 4 componentes o da ORA-01403:
1. Region (wwv_flow_page_plugs, plug_source_type = 'NATIVE_IR')
2. Worksheet (wwv_flow_worksheets, FK region_id)
3. Worksheet columns (wwv_flow_worksheet_columns, FK worksheet_id) — cantidad = columnas SQL
4. Default report (wwv_flow_worksheet_rpts, application_user = 'APXWS_DEFAULT')

## Errores Comunes

| Error | Causa | Fix |
|-------|-------|-----|
| ORA-01403 WWV_FLOW_PLUGIN | plug_source_type inválido | Usar NATIVE_STATIC, no NATIVE_DISPLAY_STATIC |
| ORA-01403 IR page | Worksheet columns != SQL columns | Cantidad y nombres deben coincidir |
| NO_PRIMARY_KEY_ITEM | item_source_plug_id NULL | Setear al ID del region NATIVE_FORM |
| Buttons no aparecen | security_group_id falta | Llamar apex_util.set_security_group_id |
| Items sin estilo | item_field_template incorrecto | Usar Optional-Floating |
| Página "unknown" | user_interface_id falta | Setear al Desktop UI ID |
| DA INSERT falla | bind_type o event_result NULL | bind_type='bind', event_result='TRUE' |
| ORA-54013 | INSERT en columna virtual | No insertar UNIQUELY_IDENTIFY_ROWS_BY |
