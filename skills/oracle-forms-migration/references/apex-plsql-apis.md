# APEX PL/SQL API Reference for Migration

Complete reference of APEX PL/SQL packages, organized by migration relevance.

---

## Essential for Migration (Detailed)

### APEX_APPLICATION — Global Variables & Engine Control

Replaces Forms system variables and global variables.

```sql
-- Current session info (replaces :SYSTEM.CURRENT_FORM, :GLOBAL.*)
apex_application.g_user              -- current user (VARCHAR2)
apex_application.g_flow_id           -- current app ID (NUMBER)
apex_application.g_flow_step_id      -- current page ID (NUMBER)
apex_application.g_instance          -- session ID (NUMBER)
apex_application.g_request           -- button/request name (VARCHAR2)

-- AJAX parameters (from apex.server.process)
apex_application.g_x01 .. g_x20     -- scalar params (VARCHAR2)
apex_application.g_clob_01           -- large text param (CLOB)
apex_application.g_f01 .. g_f50      -- array params (wwv_flow_global.vc_arr2)

-- Success message (replaces Forms MESSAGE())
apex_application.g_print_success_message := 'Guardado correctamente.';

-- Stop page processing (replaces RAISE FORM_TRIGGER_FAILURE partially)
apex_application.stop_apex_engine;
```

### APEX_JSON — JSON I/O

Replaces Forms data exchange. CRITICAL for AJAX callbacks.

```sql
-- OUTPUT: Generate JSON response
apex_json.initialize_output;
apex_json.open_object;                           -- {
apex_json.write('status', 'OK');                 -- "status":"OK"
apex_json.write('count', l_count);               -- "count":5
apex_json.write('total', l_total);               -- numbers
apex_json.write('active', TRUE);                 -- booleans
apex_json.open_array('items');                   -- "items":[
  apex_json.open_object;                         --   {
  apex_json.write('id', 1);
  apex_json.write('name', 'Test');
  apex_json.close_object;                        --   }
apex_json.close_array;                           -- ]
apex_json.close_object;                          -- }

-- Write CLOB value (19 overloads total)
apex_json.write('data', l_clob_value);           -- CLOB overload

-- ** CRITICAL: NEVER use apex_json.stringify() for large CLOBs **
-- It truncates at 32K. Use apex_json.write() with CLOB overload instead.

-- INPUT: Parse JSON from CLOB
apex_json.parse(l_json_clob);
l_val := apex_json.get_varchar2(p_path => 'status');
l_num := apex_json.get_number(p_path => 'items[1].id');
l_cnt := apex_json.get_count(p_path => 'items');       -- array length
```

### APEX_ERROR — Error Handling

Replaces Forms ON-ERROR trigger and RAISE FORM_TRIGGER_FAILURE.

```sql
-- 5 signatures — most common:

-- 1. Simple error on page
apex_error.add_error(
    p_message          => 'El campo es obligatorio.',
    p_display_location => apex_error.c_inline_in_notification
);

-- 2. Error on specific item (replaces Forms SET_ITEM_PROPERTY VISUAL_ATTRIBUTE)
apex_error.add_error(
    p_message          => 'Valor fuera de rango.',
    p_display_location => apex_error.c_inline_with_field_and_notif,
    p_page_item_name   => 'P10_MONTO'
);

-- 3. Error on tabular form / IG column+row
apex_error.add_error(
    p_message          => 'Duplicado.',
    p_display_location => apex_error.c_inline_with_field_and_notif,
    p_region_id        => l_region_id,
    p_column_alias     => 'CODIGO',
    p_row_num          => l_row
);

-- Display locations:
-- apex_error.c_inline_in_notification          (banner only)
-- apex_error.c_inline_with_field               (next to item only)
-- apex_error.c_inline_with_field_and_notif     (both)
-- apex_error.c_on_error_page                   (full error page)
```

### APEX_ESCAPE — Output Escaping

Replaces Forms validation and display formatting for web output.

```sql
apex_escape.html(l_text)           -- HTML entity encoding (<>&"')
apex_escape.html_attribute(l_text) -- for use inside HTML attributes
apex_escape.js_literal(l_text)     -- JavaScript string escaping
apex_escape.json(l_text)           -- JSON string escaping (not for full JSON generation)
apex_escape.ldap_dn(l_text)       -- LDAP distinguished name
apex_escape.ldap_search_filter(l_text)  -- LDAP filter
```

### APEX_COLLECTION — Session-State Collections

Replaces Forms Record Groups and global record sets. 50 VARCHAR2 cols (C001-C050), 5 NUMBER (N001-N005), 5 DATE (D001-D005), 1 CLOB, 1 BLOB, 1 XMLTYPE.

```sql
-- Create (replaces Forms CREATE_GROUP / POPULATE_GROUP)
apex_collection.create_collection(p_collection_name => 'MY_COLL');
apex_collection.create_or_truncate_collection('MY_COLL');

-- Create from query
apex_collection.create_collection_from_query(
    p_collection_name => 'MY_COLL',
    p_query           => 'SELECT id, name, amount FROM my_table WHERE status = :b1',
    p_names           => apex_string.string_to_table('b1'),
    p_values          => apex_string.string_to_table(:P1_STATUS)
);

-- Add member (replaces Forms ADD_GROUP_ROW)
apex_collection.add_member(
    p_collection_name => 'MY_COLL',
    p_c001 => l_id, p_c002 => l_name, p_n001 => l_amount
);

-- Update member
apex_collection.update_member_attribute(
    p_collection_name => 'MY_COLL',
    p_seq => l_seq, p_attr_number => 2, p_attr_value => 'new_name'
);

-- Query (replaces Forms GET_GROUP_ROW_COUNT / GET_GROUP_CHAR_CELL)
SELECT seq_id, c001 AS id, c002 AS name, n001 AS amount
FROM apex_collections WHERE collection_name = 'MY_COLL';

-- Delete
apex_collection.delete_collection('MY_COLL');
apex_collection.delete_member(p_collection_name => 'MY_COLL', p_seq => l_seq);

-- Check existence
IF apex_collection.collection_exists('MY_COLL') THEN ...
```

### APEX_UTIL — Utilities

Replaces Forms global variables, user management, and various built-ins.

```sql
-- Session state (replaces :GLOBAL.variable)
apex_util.set_session_state('P1_ITEM', 'value');
l_val := v('P1_ITEM');           -- shorthand for session state read
l_val := nv('P1_NUMERIC_ITEM');  -- numeric session state

-- User info
l_email := apex_util.get_email(p_username => :APP_USER);

-- Preferences (persistent across sessions — replaces Forms global vars)
apex_util.set_preference(
    p_preference => 'LAST_EMPRESA',
    p_value      => :P0_EMPRESA,
    p_user       => :APP_USER
);
l_val := apex_util.get_preference('LAST_EMPRESA', :APP_USER);

-- Cache control
apex_util.clear_page_cache(p_page_id => 10);
apex_util.clear_app_cache(p_app_id => apex_application.g_flow_id);

-- URL generation (simple)
l_url := apex_util.prepare_url('f?p=' || :APP_ID || ':10:' || :APP_SESSION || ':::P10_ID:' || l_id);

-- Count clicks / page views
apex_util.count_click(p_url => l_url, p_cat => 'DOWNLOAD', p_id => l_id);
```

### APEX_PAGE — Page Navigation

Replaces Forms CALL_FORM, NEW_FORM, OPEN_FORM.

```sql
-- Modern URL generation (APEX 20.1+) — preferred over apex_util.prepare_url
l_url := apex_page.get_url(
    p_page        => 15,
    p_clear_cache => '15',
    p_items       => 'P15_ID,P15_MODE',
    p_values      => l_id || ',EDIT',
    p_request     => 'EDIT'
);
-- Generates checksum-protected URL automatically
```

### APEX_SESSION — Session Management

Replaces Forms timer triggers when used with DBMS_SCHEDULER.

```sql
-- Attach to existing session (for background jobs)
apex_session.attach(
    p_app_id     => 200,
    p_page_id    => 1,
    p_session_id => l_session_id
);

-- Do APEX work (session state, collections, etc.)
apex_util.set_session_state('P1_STATUS', 'PROCESSED');

-- Detach when done
apex_session.detach;

-- Create new session (for API/integration use)
apex_session.create_session(
    p_app_id   => 200,
    p_page_id  => 1,
    p_username => 'SYSTEM_JOB'
);
-- ... do work ...
apex_session.delete_session;
```

### APEX_MAIL — Email

Replaces Forms HOST('mailx ...') or OLE2 email automation.

```sql
-- Send email
l_mail_id := apex_mail.send(
    p_to   => 'user@example.com',
    p_from => 'noreply@example.com',
    p_subj => 'Subject',
    p_body => 'Plain text body',
    p_body_html => '<h1>HTML body</h1>'
);

-- Add attachment
apex_mail.add_attachment(
    p_mail_id    => l_mail_id,
    p_attachment  => l_blob,
    p_filename    => 'report.pdf',
    p_mime_type   => 'application/pdf'
);

-- Push mail queue (required!)
apex_mail.push_queue;
```

### APEX_WEB_SERVICE — REST/SOAP Calls

Replaces Forms HOST for external API calls, UTL_HTTP usage.

```sql
-- REST GET
l_response := apex_web_service.make_rest_request(
    p_url         => 'https://api.example.com/data',
    p_http_method => 'GET',
    p_parm_name   => apex_util.string_to_table('param1:param2'),
    p_parm_value  => apex_util.string_to_table('val1:val2')
);

-- REST POST with JSON body
l_response := apex_web_service.make_rest_request(
    p_url         => 'https://api.example.com/data',
    p_http_method => 'POST',
    p_body        => '{"key":"value"}',
    p_http_headers => apex_web_service.g_request_headers
);

-- Set headers before call
apex_web_service.g_request_headers.delete;
apex_web_service.g_request_headers(1).name  := 'Content-Type';
apex_web_service.g_request_headers(1).value := 'application/json';
apex_web_service.g_request_headers(2).name  := 'Authorization';
apex_web_service.g_request_headers(2).value := 'Bearer ' || l_token;

-- Response headers
l_status := apex_web_service.g_status_code;  -- HTTP status
```

### APEX_DEBUG — Debug/Logging

Replaces Forms DBMS_OUTPUT and debug messages.

```sql
apex_debug.error('Critical: %s', l_error_msg);    -- level 1
apex_debug.warn('Warning: %s', l_warning);         -- level 2
apex_debug.info('Info: %s = %s', 'param', l_val);  -- level 4
apex_debug.trace('Trace: entering %s', l_proc);    -- level 6

-- Enable debug in URL: &DEBUG.=YES or &DEBUG.=LEVEL9
```

---

## Standard AJAX Callback Pattern

This is the most common pattern replacing Forms triggers that interact with the database. Used extensively in migration.

### PL/SQL Process (On Demand / AJAX Callback)
```sql
-- Page process: Type = PL/SQL, Point = On Demand, Name = MY_ACTION
DECLARE
    l_id    NUMBER := TO_NUMBER(apex_application.g_x01);
    l_mode  VARCHAR2(20) := apex_application.g_x02;
    l_data  CLOB := apex_application.g_clob_01;
    l_result CLOB;
BEGIN
    -- Business logic
    pkg_entity.do_something(
        p_id     => l_id,
        p_mode   => l_mode,
        p_data   => l_data,
        p_result => l_result
    );

    -- Return JSON
    apex_json.initialize_output;
    apex_json.open_object;
    apex_json.write('status', 'OK');
    apex_json.write('data', l_result);  -- CLOB overload
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.initialize_output;
        apex_json.open_object;
        apex_json.write('status', 'ERROR');
        apex_json.write('message', SQLERRM);
        apex_json.close_object;
END;
```

### JavaScript Caller
```javascript
apex.server.process('MY_ACTION', {
    x01: itemId,
    x02: 'UPDATE',
    f01: arrayData,           // optional array
    pageItems: '#P1_ITEM1,#P1_ITEM2'  // sends session state
}, {
    dataType: 'json',
    success: function(data) {
        if (data.status === 'OK') {
            apex.message.showPageSuccess('Operacion exitosa.');
        } else {
            apex.message.showErrors([{
                type: 'error',
                location: 'page',
                message: data.message
            }]);
        }
    },
    error: function(xhr, status, error) {
        apex.message.showErrors([{
            type: 'error', location: 'page',
            message: 'Error de servidor: ' + error
        }]);
    }
});
```

---

## Useful for Migration

### APEX_EXEC — Execute Queries Programmatically
```sql
-- Open a query context (useful in PL/SQL regions, plugins)
l_context := apex_exec.open_query_context(
    p_location  => apex_exec.c_location_local_db,
    p_sql_query => 'SELECT id, name FROM my_table WHERE status = :status',
    p_sql_parameters => l_params
);
WHILE apex_exec.next_row(p_context => l_context) LOOP
    l_id   := apex_exec.get_number(l_context, 1);
    l_name := apex_exec.get_varchar2(l_context, 2);
END LOOP;
apex_exec.close(l_context);

-- Execute DML
apex_exec.execute_plsql(p_plsql_code => 'BEGIN pkg.proc(:val); END;');
```

### APEX_STRING — String Utilities
```sql
apex_string.split(p_str => 'A,B,C', p_sep => ',')    -- returns apex_t_varchar2
apex_string.join(l_arr, ':')                            -- join array
apex_string.format('Hello %s, you have %s items', l_name, l_count)
apex_string.string_to_table('A:B:C', ':')              -- legacy vc_arr2
apex_string.push(l_arr, 'new_element')
apex_string.shuffle(l_arr)
```

### APEX_ITEM — Generate Form Elements in SQL
```sql
-- In IR/Classic Report SQL (replaces Forms displayed items in tabular forms)
SELECT apex_item.hidden(1, id) ||
       apex_item.text(2, name, 30) ||
       apex_item.select_list_from_lov(3, status, 'LV_STATUS') ||
       apex_item.checkbox2(4, id)
FROM my_table;
-- Values accessible in PL/SQL as apex_application.g_f01, g_f02, etc.
```

### APEX_JAVASCRIPT — JS Generation from PL/SQL
```sql
apex_javascript.add_onload_code(p_code => 'initMyWidget();');
apex_javascript.add_inline_code(p_code => 'var x = ' || apex_javascript.add_value(l_val) || ';');
apex_javascript.escape(l_text);  -- escape for JS string
```

### APEX_CSS — CSS Generation from PL/SQL
```sql
apex_css.add(p_css => '.my-class { color: red; }');
apex_css.add_file(p_name => 'my-styles', p_directory => '#WORKSPACE_IMAGES#');
```

### APEX_IG — Interactive Grid Programmatic Control
```sql
-- Get selected rows
l_context := apex_ig.get_selected_rows(
    p_region_static_id => 'my_ig',
    p_page_id          => :APP_PAGE_ID
);
```

### APEX_IR — Interactive Report Programmatic Control
```sql
-- Clear IR filters
apex_ir.clear_report(
    p_page_id   => 10,
    p_region_id => l_region_id
);
-- Add filter
apex_ir.add_filter(
    p_page_id       => 10,
    p_region_id     => l_region_id,
    p_column_name   => 'STATUS',
    p_filter_value  => 'ACTIVE',
    p_operator_abbr => 'EQ'
);
```

### APEX_REGION
```sql
apex_region.open_query_context(p_page_id => 10, p_region_id => l_id);
apex_region.purge_cache(p_page_id => 10, p_region_id => l_id);
```

### APEX_THEME
```sql
-- Get current theme info
l_theme_id := apex_theme.get_theme_id;
```

### APEX_ZIP — ZIP File Handling
```sql
-- Create ZIP
apex_zip.add_file(p_zipped_blob => l_zip, p_file_name => 'data.csv', p_content => l_blob);
apex_zip.finish(p_zipped_blob => l_zip);

-- Extract ZIP
apex_zip.get_files(p_zipped_blob => l_zip);  -- returns file list
apex_zip.get_file_content(p_zipped_blob => l_zip, p_file_name => 'data.csv');
```

### APEX_AUTHENTICATION / APEX_AUTHORIZATION / APEX_ACL
```sql
-- Authentication
apex_authentication.login(p_username => l_user, p_password => l_pass);
apex_authentication.logout(p_app_id => :APP_ID, p_session_id => :APP_SESSION);
apex_authentication.post_login(p_username => l_user, p_session_id => :APP_SESSION);

-- Authorization (check scheme)
IF apex_authorization.is_authorized(p_authorization_name => 'ADMIN_ROLE') THEN ...

-- ACL (Access Control List)
apex_acl.add_user_role(p_application_id => :APP_ID, p_user_name => l_user, p_role_static_id => 'ADMIN');
apex_acl.has_user_role(p_application_id => :APP_ID, p_user_name => :APP_USER, p_role_static_id => 'ADMIN');
```

### APEX_CREDENTIAL
```sql
apex_credential.set_persistent_credentials(
    p_credential_static_id => 'MY_API_CRED',
    p_client_id            => l_client_id,
    p_client_secret        => l_client_secret
);
```

### APEX_LANG — Multi-Language
```sql
apex_lang.message('MY_MSG_KEY')                     -- get translated message
apex_lang.message('HELLO_USER', l_username)         -- with substitution
apex_lang.emit_language_selector_list               -- language selector HTML
```

### APEX_SPATIAL — Map Regions
```sql
apex_spatial.point(p_x => l_lon, p_y => l_lat);
```

### APEX_DATA_PARSER — Parse CSV/XLSX/JSON/XML
```sql
-- Parse uploaded file (replaces Forms file import logic)
SELECT line_number, col001, col002, col003
FROM TABLE(apex_data_parser.parse(
    p_content   => l_blob,
    p_file_name => 'data.xlsx'
));
```

### APEX_EXPORT / APEX_APPLICATION_INSTALL
```sql
-- Export application
l_files := apex_export.get_application(p_application_id => 200);

-- Install
apex_application_install.set_workspace_id(l_ws_id);
apex_application_install.set_application_id(200);
```

### APEX_INSTANCE_ADMIN / APEX_APP_SETTING
```sql
-- Instance-level settings
l_val := apex_instance_admin.get_parameter('MAX_FILE_SIZE');

-- App-level settings (replaces Forms module parameters)
l_val := apex_app_setting.get_value('MY_SETTING');
apex_app_setting.set_value('MY_SETTING', 'new_value');
```

### APEX_PLUGIN / APEX_PLUGIN_UTIL
```sql
-- For custom plugin development
apex_plugin_util.get_data(
    p_sql_statement => l_sql,
    p_min_columns   => 2,
    p_max_columns   => 4
);
```

### APEX_JWT — JSON Web Tokens
```sql
l_token := apex_jwt.encode(
    p_iss       => 'my-app',
    p_sub       => :APP_USER,
    p_aud       => 'api',
    p_iat_ts    => SYSTIMESTAMP,
    p_exp_sec   => 3600,
    p_signature_key => l_key
);
```

### APEX_STRING_UTIL
```sql
apex_string_util.to_slug('Hello World')    -- 'hello-world'
apex_string_util.get_slug(l_text)
```

### APEX_UI_DEFAULT_UPDATE
```sql
-- Update UI defaults for a table (affects form/report generation)
apex_ui_default_update.upd_column(
    p_table_name  => 'MY_TABLE',
    p_column_name => 'STATUS',
    p_label       => 'Estado',
    p_format_mask => NULL,
    p_lov_query   => 'SELECT name d, code r FROM status_types'
);
```

---

## Quick Reference: Forms Built-in to APEX Package Mapping

| Forms Built-in | APEX Replacement |
|---|---|
| MESSAGE() | apex_application.g_print_success_message |
| RAISE FORM_TRIGGER_FAILURE | apex_error.add_error() |
| SET_ITEM_PROPERTY(.., VISIBLE) | Client-side: apex.item('X').show/hide |
| GET_ITEM_PROPERTY(.., VALUE) | v('P1_ITEM') or :P1_ITEM |
| SET_ITEM_PROPERTY(.., VALUE) | apex_util.set_session_state() |
| CALL_FORM / NEW_FORM | apex_page.get_url() + redirect |
| CREATE_GROUP / POPULATE_GROUP | apex_collection.create_collection_from_query() |
| HOST() for email | apex_mail.send() |
| HOST() for OS commands | DBMS_SCHEDULER |
| WEB.SHOW_DOCUMENT | apex_page.get_url() or htp.p redirect |
| DBMS_OUTPUT (debug) | apex_debug.info/warn/error |
| Timer triggers | DBMS_SCHEDULER + apex_session.attach |
| Global variables | apex_util.set/get_preference or app items |
| OLE2 (Excel export) | apex_data_export or APEX IR download |
