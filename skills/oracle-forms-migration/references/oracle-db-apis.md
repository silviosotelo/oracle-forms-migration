# Oracle DB APIs for Forms-to-APEX Migration

Key Oracle database packages and features used during migration.

---

## DBMS_LOB — BLOB/CLOB Handling

Replaces Forms OLE2 and BLOB item manipulation.

```sql
-- Read CLOB length
l_len := DBMS_LOB.getlength(l_clob);

-- Substring (replaces Forms SUBSTR on LOBs)
l_chunk := DBMS_LOB.substr(l_clob, p_amount => 4000, p_offset => 1);

-- Append
DBMS_LOB.append(l_dest_clob, l_source_clob);

-- Write to CLOB
DBMS_LOB.createtemporary(l_clob, TRUE);
DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);

-- Copy BLOB
DBMS_LOB.createtemporary(l_dest_blob, TRUE);
DBMS_LOB.copy(l_dest_blob, l_source_blob, DBMS_LOB.getlength(l_source_blob));

-- Convert CLOB <-> BLOB
l_blob := UTL_RAW.cast_to_raw(DBMS_LOB.substr(l_clob, 32767));  -- small only
-- For large CLOBs:
DBMS_LOB.converttoblob(l_blob, l_clob, DBMS_LOB.lobmaxsize, l_dest_off, l_src_off, 
                        DBMS_LOB.default_csid, l_lang_ctx, l_warning);

-- Free temporary LOB
DBMS_LOB.freetemporary(l_clob);

-- Check if LOB is temporary
IF DBMS_LOB.istemporary(l_blob) = 1 THEN ...

-- Compare
IF DBMS_LOB.compare(l_blob1, l_blob2) = 0 THEN -- equal

-- File operations (BFILE)
l_bfile := BFILENAME('MY_DIR', 'file.pdf');
DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
DBMS_LOB.loadfromfile(l_blob, l_bfile, DBMS_LOB.getlength(l_bfile));
DBMS_LOB.fileclose(l_bfile);
```

---

## DBMS_METADATA — DDL Extraction

Essential during migration analysis to extract object definitions.

```sql
-- Get table DDL (for understanding Forms data sources)
SELECT DBMS_METADATA.get_ddl('TABLE', 'MY_TABLE', 'SCHEMA') FROM DUAL;

-- Get view DDL
SELECT DBMS_METADATA.get_ddl('VIEW', 'MY_VIEW', 'SCHEMA') FROM DUAL;

-- Get package spec + body
SELECT DBMS_METADATA.get_ddl('PACKAGE', 'PKG_MY_PKG', 'SCHEMA') FROM DUAL;
SELECT DBMS_METADATA.get_ddl('PACKAGE_BODY', 'PKG_MY_PKG', 'SCHEMA') FROM DUAL;

-- Get trigger (migrating Forms database triggers)
SELECT DBMS_METADATA.get_ddl('TRIGGER', 'TRG_MY_TRIGGER', 'SCHEMA') FROM DUAL;

-- Get index definitions
SELECT DBMS_METADATA.get_ddl('INDEX', index_name, 'SCHEMA')
FROM all_indexes WHERE table_name = 'MY_TABLE' AND owner = 'SCHEMA';

-- Get dependent DDL (constraints, grants, etc.)
SELECT DBMS_METADATA.get_dependent_ddl('CONSTRAINT', 'MY_TABLE', 'SCHEMA') FROM DUAL;
SELECT DBMS_METADATA.get_dependent_ddl('INDEX', 'MY_TABLE', 'SCHEMA') FROM DUAL;

-- Control output format
DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform, 'SQLTERMINATOR', TRUE);
DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform, 'STORAGE', FALSE);
DBMS_METADATA.set_transform_param(DBMS_METADATA.session_transform, 'TABLESPACE', FALSE);
```

---

## DBMS_SCHEDULER — Job Scheduling

Replaces Forms WHEN-TIMER-EXPIRED triggers and HOST() for background processes.

```sql
-- Create job (replaces Forms timer trigger)
DBMS_SCHEDULER.create_job(
    job_name        => 'JOB_PROCESS_QUEUE',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[
        BEGIN
            apex_session.attach(p_app_id => 200, p_page_id => 1, p_session_id => :session_id);
            pkg_queue.process_pending;
            apex_session.detach;
        EXCEPTION WHEN OTHERS THEN
            apex_session.detach;
            RAISE;
        END;
    ]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Process pending queue every 5 minutes'
);

-- One-time immediate job
DBMS_SCHEDULER.create_job(
    job_name   => 'JOB_ONETIME_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF'),
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN pkg_report.generate(' || l_id || '); END;',
    start_date => SYSTIMESTAMP,
    enabled    => TRUE,
    auto_drop  => TRUE
);

-- Manage jobs
DBMS_SCHEDULER.run_job('JOB_PROCESS_QUEUE');
DBMS_SCHEDULER.stop_job('JOB_PROCESS_QUEUE');
DBMS_SCHEDULER.drop_job('JOB_PROCESS_QUEUE');
DBMS_SCHEDULER.disable('JOB_PROCESS_QUEUE');
DBMS_SCHEDULER.enable('JOB_PROCESS_QUEUE');

-- Check job status
SELECT job_name, state, last_start_date, next_run_date, run_count, failure_count
FROM user_scheduler_jobs;

SELECT log_date, status, error#, additional_info
FROM user_scheduler_job_run_details
WHERE job_name = 'JOB_PROCESS_QUEUE'
ORDER BY log_date DESC;
```

---

## DBMS_CRYPTO — Encryption/Hashing

For security in new APEX applications.

```sql
-- Hash (SHA-256)
l_hash := DBMS_CRYPTO.hash(
    src => UTL_RAW.cast_to_raw(l_text),
    typ => DBMS_CRYPTO.hash_sh256
);

-- HMAC
l_hmac := DBMS_CRYPTO.mac(
    src => UTL_RAW.cast_to_raw(l_message),
    typ => DBMS_CRYPTO.hmac_sh256,
    key => UTL_RAW.cast_to_raw(l_secret)
);

-- Encrypt (AES-256-CBC)
l_encrypted := DBMS_CRYPTO.encrypt(
    src => UTL_RAW.cast_to_raw(l_plaintext),
    typ => DBMS_CRYPTO.encrypt_aes256 + DBMS_CRYPTO.chain_cbc + DBMS_CRYPTO.pad_pkcs5,
    key => l_key_raw,
    iv  => l_iv_raw
);

-- Decrypt
l_decrypted := DBMS_CRYPTO.decrypt(
    src => l_encrypted,
    typ => DBMS_CRYPTO.encrypt_aes256 + DBMS_CRYPTO.chain_cbc + DBMS_CRYPTO.pad_pkcs5,
    key => l_key_raw,
    iv  => l_iv_raw
);
l_plaintext := UTL_RAW.cast_to_varchar2(l_decrypted);

-- Hash types: hash_md5, hash_sh1, hash_sh256, hash_sh384, hash_sh512
```

---

## UTL_RAW / UTL_ENCODE — Base64 & Raw Conversion

For file handling in APEX (file upload/download, inline images).

```sql
-- Base64 encode BLOB (for inline images, data URIs)
l_base64_raw := UTL_ENCODE.base64_encode(l_raw_data);
l_base64_str := UTL_RAW.cast_to_varchar2(l_base64_raw);

-- Base64 decode (receiving files from JavaScript)
l_raw_data := UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(l_base64_str));

-- For large BLOBs, process in chunks (avoids 32K VARCHAR2 limit):
DECLARE
    l_step   PLS_INTEGER := 22500;  -- must be multiple of 3 for Base64
    l_offset PLS_INTEGER := 1;
    l_len    PLS_INTEGER := DBMS_LOB.getlength(l_blob);
    l_chunk  RAW(32767);
    l_result CLOB;
BEGIN
    DBMS_LOB.createtemporary(l_result, TRUE);
    WHILE l_offset <= l_len LOOP
        l_chunk := DBMS_LOB.substr(l_blob, l_step, l_offset);
        DBMS_LOB.writeappend(l_result, 
            LENGTH(UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(l_chunk))),
            UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(l_chunk)));
        l_offset := l_offset + l_step;
    END LOOP;
END;

-- Raw conversions
UTL_RAW.cast_to_varchar2(l_raw)    -- RAW -> VARCHAR2
UTL_RAW.cast_to_raw(l_varchar)     -- VARCHAR2 -> RAW
UTL_RAW.cast_to_number(l_raw)      -- RAW -> NUMBER
UTL_RAW.concat(l_raw1, l_raw2)     -- concatenate RAW values
UTL_RAW.length(l_raw)              -- length in bytes
```

---

## UTL_HTTP — HTTP Requests (Basic)

For simple HTTP needs. Prefer APEX_WEB_SERVICE in APEX context.

```sql
-- Simple GET
l_response := UTL_HTTP.request('https://api.example.com/data');

-- Full request with headers
l_req := UTL_HTTP.begin_request('https://api.example.com/data', 'POST');
UTL_HTTP.set_header(l_req, 'Content-Type', 'application/json');
UTL_HTTP.set_header(l_req, 'Authorization', 'Bearer ' || l_token);
UTL_HTTP.set_header(l_req, 'Content-Length', LENGTH(l_body));
UTL_HTTP.write_text(l_req, l_body);

l_resp := UTL_HTTP.get_response(l_req);
UTL_HTTP.read_text(l_resp, l_response, 32767);
UTL_HTTP.end_response(l_resp);

-- SSL wallet (required for HTTPS)
UTL_HTTP.set_wallet('file:/path/to/wallet', 'wallet_password');
```

---

## JSON_OBJECT_T / JSON_ARRAY_T — Modern JSON (12c+)

For AJAX callback processing in PL/SQL. More efficient than APEX_JSON for parsing.

```sql
-- Parse JSON from CLOB
l_json := JSON_OBJECT_T.parse(l_clob);
l_name := l_json.get_string('name');
l_id   := l_json.get_number('id');
l_arr  := l_json.get_array('items');

-- Iterate array
FOR i IN 0 .. l_arr.get_size - 1 LOOP
    l_item := JSON_OBJECT_T(l_arr.get(i));
    l_val  := l_item.get_string('code');
END LOOP;

-- Build JSON
l_json := JSON_OBJECT_T();
l_json.put('status', 'OK');
l_json.put('count', l_count);
l_json.put('active', TRUE);

l_arr := JSON_ARRAY_T();
l_arr.append(JSON_OBJECT_T('{"id":1,"name":"test"}'));
l_json.put('items', l_arr);

l_clob := l_json.to_clob;

-- JSON in SQL (12c+)
SELECT JSON_OBJECT(
    'id' VALUE id,
    'name' VALUE name,
    'items' VALUE JSON_ARRAYAGG(
        JSON_OBJECT('code' VALUE code, 'desc' VALUE description)
    )
) AS json_result
FROM my_table
GROUP BY id, name;

-- JSON_TABLE (parse JSON in SQL)
SELECT jt.*
FROM my_table t,
     JSON_TABLE(t.json_col, '$'
        COLUMNS (
            status VARCHAR2(20) PATH '$.status',
            amount NUMBER PATH '$.amount',
            NESTED PATH '$.items[*]'
                COLUMNS (
                    item_id NUMBER PATH '$.id',
                    item_name VARCHAR2(100) PATH '$.name'
                )
        )
     ) jt;
```

---

## REGEXP Functions — Data Validation

Replaces Forms built-in validation triggers (WHEN-VALIDATE-ITEM format masks).

```sql
-- Validate email (replaces Forms format mask validation)
IF NOT REGEXP_LIKE(l_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    apex_error.add_error(p_message => 'Email invalido.', 
                         p_display_location => apex_error.c_inline_with_field_and_notif,
                         p_page_item_name => 'P1_EMAIL');
END IF;

-- Validate phone
IF NOT REGEXP_LIKE(l_phone, '^\+?[0-9]{8,15}$') THEN ...

-- Validate CUIT/CUIL (Argentina)
IF NOT REGEXP_LIKE(l_cuit, '^\d{2}-?\d{8}-?\d{1}$') THEN ...

-- Extract parts
l_domain := REGEXP_SUBSTR(l_email, '@(.+)$', 1, 1, NULL, 1);

-- Replace (clean input)
l_clean := REGEXP_REPLACE(l_input, '[^0-9]', '');  -- digits only

-- Count matches
l_count := REGEXP_COUNT(l_text, '\b\w+\b');  -- word count

-- REGEXP in SQL WHERE (for IR source queries)
SELECT * FROM clients
WHERE REGEXP_LIKE(phone, '^\+54');

-- REGEXP_INSTR (find position)
l_pos := REGEXP_INSTR(l_text, '[0-9]{4}-[0-9]{4}');
```

---

## Analytic Functions — Report Enhancement

For complex reports replacing Forms summary items, calculated fields.

```sql
-- Row numbering (replaces Forms :SYSTEM.CURSOR_RECORD)
SELECT ROW_NUMBER() OVER (ORDER BY fecha DESC) AS rn,
       id, descripcion, monto
FROM facturas;

-- Running total (replaces Forms summary items)
SELECT id, monto,
       SUM(monto) OVER (ORDER BY fecha ROWS UNBOUNDED PRECEDING) AS saldo_acumulado
FROM movimientos;

-- Previous/next row (replaces Forms POST-QUERY with :NEXT/:PREVIOUS)
SELECT id, monto,
       LAG(monto) OVER (ORDER BY fecha) AS monto_anterior,
       LEAD(monto) OVER (ORDER BY fecha) AS monto_siguiente,
       monto - LAG(monto) OVER (ORDER BY fecha) AS diferencia
FROM movimientos;

-- Ranking (replaces Forms calculated items)
SELECT id, vendedor, total,
       RANK() OVER (ORDER BY total DESC) AS ranking,
       DENSE_RANK() OVER (PARTITION BY sucursal ORDER BY total DESC) AS rank_sucursal
FROM ventas;

-- String aggregation (replaces Forms record group concatenation)
SELECT cliente_id,
       LISTAGG(telefono, ', ') WITHIN GROUP (ORDER BY tipo) AS telefonos
FROM telefonos_cliente
GROUP BY cliente_id;

-- Pivot (replaces Forms matrix reports)
SELECT * FROM (
    SELECT mes, tipo, monto FROM resumen
)
PIVOT (
    SUM(monto) FOR mes IN (1 AS ENE, 2 AS FEB, 3 AS MAR, 4 AS ABR,
                            5 AS MAY, 6 AS JUN, 7 AS JUL, 8 AS AGO,
                            9 AS SEP, 10 AS OCT, 11 AS NOV, 12 AS DIC)
);

-- NTILE (quartiles/percentiles for dashboards)
SELECT id, monto,
       NTILE(4) OVER (ORDER BY monto) AS quartile
FROM facturas;

-- First/Last in group
SELECT DISTINCT tipo,
       FIRST_VALUE(descripcion) OVER (PARTITION BY tipo ORDER BY fecha DESC) AS ultimo_desc,
       LAST_VALUE(monto) OVER (PARTITION BY tipo ORDER BY fecha 
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS ultimo_monto
FROM movimientos;
```

---

## Dictionary Views — Migration Analysis

For understanding the existing database schema during Forms migration.

```sql
-- All tables and their columns (understand Forms data blocks)
SELECT table_name, column_name, data_type, data_length, data_precision, data_scale,
       nullable, data_default
FROM all_tab_columns
WHERE owner = :schema
ORDER BY table_name, column_id;

-- Table/column comments (for APEX labels)
SELECT table_name, column_name, comments
FROM all_col_comments
WHERE owner = :schema AND comments IS NOT NULL;

-- Primary keys (for APEX form PK items)
SELECT ac.table_name, acc.column_name, acc.position
FROM all_constraints ac
JOIN all_cons_columns acc ON ac.constraint_name = acc.constraint_name AND ac.owner = acc.owner
WHERE ac.owner = :schema AND ac.constraint_type = 'P'
ORDER BY ac.table_name, acc.position;

-- Foreign keys (for LOVs and master-detail)
SELECT ac.table_name, acc.column_name,
       rc.table_name AS ref_table, rcc.column_name AS ref_column
FROM all_constraints ac
JOIN all_cons_columns acc ON ac.constraint_name = acc.constraint_name AND ac.owner = acc.owner
JOIN all_constraints rc ON ac.r_constraint_name = rc.constraint_name AND ac.r_owner = rc.owner
JOIN all_cons_columns rcc ON rc.constraint_name = rcc.constraint_name AND rc.owner = rcc.owner
WHERE ac.owner = :schema AND ac.constraint_type = 'R'
ORDER BY ac.table_name;

-- All database objects
SELECT object_name, object_type, status, created, last_ddl_time
FROM user_objects
WHERE object_type IN ('TABLE','VIEW','PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION',
                       'TRIGGER','SEQUENCE','TYPE','SYNONYM')
ORDER BY object_type, object_name;

-- Search PL/SQL source (find Forms-related logic)
SELECT name, type, line, text
FROM user_source
WHERE UPPER(text) LIKE '%' || UPPER(:search_term) || '%'
ORDER BY name, type, line;

-- Table row counts (estimate — for migration planning)
SELECT table_name, num_rows, last_analyzed
FROM all_tables
WHERE owner = :schema
ORDER BY num_rows DESC NULLS LAST;

-- Sequences (for APEX auto-increment)
SELECT sequence_name, min_value, max_value, increment_by, last_number, cache_size
FROM all_sequences WHERE sequence_owner = :schema;

-- Indexes (performance reference)
SELECT ai.index_name, ai.table_name, ai.uniqueness,
       LISTAGG(aic.column_name, ',') WITHIN GROUP (ORDER BY aic.column_position) AS columns
FROM all_indexes ai
JOIN all_ind_columns aic ON ai.index_name = aic.index_name AND ai.owner = aic.index_owner
WHERE ai.owner = :schema
GROUP BY ai.index_name, ai.table_name, ai.uniqueness;

-- Triggers (may need migration or removal)
SELECT trigger_name, table_name, trigger_type, triggering_event, status
FROM all_triggers WHERE owner = :schema;

-- Database links (Forms may use remote queries)
SELECT db_link, username, host FROM all_db_links;

-- Grants (for APEX schema access)
SELECT grantee, table_name, privilege
FROM all_tab_privs WHERE grantor = :schema;

-- Dependencies (impact analysis)
SELECT name, type, referenced_name, referenced_type
FROM all_dependencies
WHERE owner = :schema AND referenced_owner = :schema
ORDER BY name, type;
```
