# APEX JavaScript API Reference for Migration

Complete reference of APEX client-side APIs. Organized by namespace with Forms-to-APEX mappings.

---

## apex.env — Environment Variables

Available on every APEX page. Replaces Forms system variables.

```javascript
apex.env.APP_ID          // application ID (number)
apex.env.APP_PAGE_ID     // current page ID (number)
apex.env.APP_SESSION     // session ID (string)
apex.env.APP_USER        // current username (string)
apex.env.APP_FILES       // app static files prefix
apex.env.WORKSPACE_FILES // workspace static files prefix
```

---

## apex.server — Server Communication

Replaces Forms database triggers, WEB.SHOW_DOCUMENT for data fetching.

```javascript
// AJAX callback (most common — replaces Forms triggers that do DML)
apex.server.process('PROCESS_NAME', {
    x01: 'value1',                    // scalar params -> g_x01..g_x20
    x02: 123,
    f01: ['a','b','c'],               // array params -> g_f01
    pageItems: '#P1_ITEM1,#P1_ITEM2', // sends these items as session state
    // p_clob_01: largeString         // for CLOB -> g_clob_01
}, {
    dataType: 'json',                 // or 'text', 'html'
    async: true,                      // default true
    loadingIndicator: '#my-region',   // show spinner on element
    loadingIndicatorPosition: 'centered',
    success: function(data) { /* handle response */ },
    error: function(xhr, status, err) { /* handle error */ },
    complete: function() { /* always runs */ },
    target: this.triggeringElement     // DA context
});

// Plugin AJAX (for plugin development)
apex.server.plugin(ajaxIdentifier, {
    x01: 'value',
    pageItems: '#P1_X'
}, {
    success: function(data) { }
});

// Generate APEX URL (replaces Forms WEB.SHOW_DOCUMENT URL building)
var url = apex.server.url({
    path: 'f',
    params: { p: apex.env.APP_ID + ':15:' + apex.env.APP_SESSION + '::NO::P15_ID:' + id }
});
```

---

## apex.item — Item Manipulation

Replaces Forms SET_ITEM_PROPERTY, GET_ITEM_PROPERTY, NAME_IN, COPY.

```javascript
// Get/Set values (replaces :BLOCK.ITEM / NAME_IN / COPY)
apex.item('P1_NAME').getValue();              // returns string
apex.item('P1_NAME').setValue('New Value');
apex.item('P1_NAME').setValue('10', 'Ten');    // value + display value (for LOVs)

// Enable/Disable (replaces SET_ITEM_PROPERTY ENABLED/UPDATEABLE)
apex.item('P1_NAME').disable();
apex.item('P1_NAME').enable();
apex.item('P1_NAME').isDisabled();            // boolean

// Show/Hide (replaces SET_ITEM_PROPERTY VISIBLE)
apex.item('P1_NAME').show();
apex.item('P1_NAME').hide();

// Required validation (replaces Forms REQUIRED property)
apex.item('P1_NAME').setValidity('error');     // mark invalid
apex.item('P1_NAME').setValidity('valid');     // mark valid
apex.item('P1_NAME').getValidity();            // {valid: true/false}

// Focus (replaces GO_ITEM)
apex.item('P1_NAME').setFocus();

// Changed state (replaces :SYSTEM.FORM_STATUS)
apex.item('P1_NAME').isChanged();

// Refresh (re-execute LOV query, cascade)
apex.item('P1_NAME').refresh();

// Check if item exists on page
if (apex.item('P1_NAME').isEmpty()) { ... }

// Set style (replaces SET_ITEM_PROPERTY VISUAL_ATTRIBUTE)
apex.item('P1_NAME').element.css('background-color', '#ffcccc');

// Callbacks
apex.item('P1_NAME').callbacks = {
    setValue: function(pValue, pDisplayValue) { ... },
    nullValue: ''
};
```

---

## apex.region — Region Control

Replaces Forms GO_BLOCK, EXECUTE_QUERY, SET_BLOCK_PROPERTY.

```javascript
// Refresh region data (replaces EXECUTE_QUERY)
apex.region('my_static_id').refresh();

// Get underlying widget (IG, IR, etc.)
var ig = apex.region('my_ig').widget();       // returns jQuery widget
var igActions = ig.interactiveGrid('getActions');
var igView = ig.interactiveGrid('getViews', 'grid');
var model = igView.model;

// IR widget
var ir = apex.region('my_ir').widget();

// Region element
apex.region('my_static_id').element;           // jQuery element

// Focus region (replaces GO_BLOCK)
apex.region('my_static_id').focus();

// Alternative: jQuery selector
$('#my_static_id').trigger('apexrefresh');
```

---

## apex.page — Page Operations

Replaces Forms COMMIT_FORM, DO_KEY('COMMIT_FORM'), CLEAR_FORM.

```javascript
// Submit page (replaces COMMIT_FORM / DO_KEY)
apex.page.submit('SAVE');                      // submit with request
apex.page.submit({
    request: 'SAVE',
    showWait: true,                             // loading overlay
    set: {                                      // set items before submit
        'P1_STATUS': 'APPROVED',
        'P1_DATE': '2024-01-01'
    },
    validate: true,                             // run client validations first
    reloadOnSubmit: 'S'                         // S=smart (default), A=always
});

// Confirm before submit
apex.page.confirmAndSubmit('DELETE', 'Confirmar eliminacion?');

// Validate page (replaces Forms VALIDATE)
apex.page.validate();                           // returns true/false

// Check for unsaved changes (replaces :SYSTEM.FORM_STATUS)
apex.page.isChanged();

// Cancel dialog (modal pages)
apex.page.cancelWarnOnUnsavedChanges();
```

---

## apex.message — User Messages

Replaces Forms MESSAGE(), ALERT(), SET_ALERT_PROPERTY.

```javascript
// Success message (replaces Forms MESSAGE with acknowledge mode)
apex.message.showPageSuccess('Guardado correctamente.');

// Error messages (replaces Forms message in status bar)
apex.message.showErrors([
    {
        type: 'error',
        location: 'page',                      // 'page' and/or 'inline'
        message: 'Error general en la pagina.'
    },
    {
        type: 'error',
        location: ['page', 'inline'],
        pageItem: 'P1_MONTO',                  // highlight specific item
        message: 'Monto debe ser mayor a cero.'
    }
]);

// Clear all errors
apex.message.clearErrors();

// Alert dialog (replaces Forms ALERT with one button)
apex.message.alert('Operacion completada.', function() {
    // callback after OK
});

// Confirm dialog (replaces Forms ALERT with two buttons)
apex.message.confirm('Desea eliminar este registro?', function(okPressed) {
    if (okPressed) {
        apex.page.submit('DELETE');
    }
});
```

---

## apex.navigation — Navigation

Replaces Forms CALL_FORM, NEW_FORM, OPEN_FORM, EXIT_FORM.

```javascript
// Redirect (replaces NEW_FORM — replaces current page)
apex.navigation.redirect('f?p=200:15:' + apex.env.APP_SESSION + '::NO::P15_ID:' + id);

// Open modal dialog (replaces CALL_FORM with new window)
apex.navigation.dialog(url, {
    title: 'Editar Registro',
    height: 600,
    width: 800,
    modal: true,
    resizable: true
}, 'a]', this.triggeringElement);

// Close dialog (from inside modal — replaces EXIT_FORM)
apex.navigation.dialog.close(true);             // true = trigger apexafterclosedialog
apex.navigation.dialog.close(true, {item1: 'val1', item2: 'val2'});  // pass values back

// Popup window (replaces OPEN_FORM)
apex.navigation.popup({
    url: url,
    name: 'myPopup',
    width: 800,
    height: 600
});

// Open in new window/tab
apex.navigation.openInNewWindow(url, 'windowName');

// Back (replaces EXIT_FORM to return)
history.back();
```

---

## apex.event — Event Handling

Replaces Forms trigger system.

```javascript
// Trigger custom event (replaces Forms user-defined triggers)
apex.event.trigger('#P1_STATUS', 'change');
apex.event.trigger(document, 'myCustomEvent', {data: 'value'});

// Listen for events
$(document).on('myCustomEvent', function(e, data) { ... });

// Common APEX events to listen for:
// 'apexbeforepagesubmit'    — before page submit
// 'apexafterpagesubmit'     — after page submit (before redirect)
// 'apexafterrefresh'        — after region refresh
// 'apexbeforerefresh'       — before region refresh
// 'apexafterclosedialog'    — after modal dialog closes
// 'apexafterclosenotification' — after notification dismissed
// 'apexreadyend'            — all page JS initialized
```

---

## apex.da — Dynamic Action Control

For use within Dynamic Action JavaScript code.

```javascript
// Resume after async operation (in DA with Wait for Result = Yes)
apex.da.resume(this.resumeCallback, false);     // false = no error
apex.da.resume(this.resumeCallback, true);      // true = error, stops DA

// Cancel subsequent DA actions
apex.da.cancel();

// Access DA context
this.triggeringElement;    // the element that triggered the DA
this.affectedElements;     // jQuery set of affected elements
this.action;               // current action object
this.browserEvent;         // original browser event
this.data;                 // event data (e.g., dialog return values)
```

---

## apex.util — Utilities

General utilities for common patterns.

```javascript
// Escape HTML (security — replaces Forms DISPLAY_ITEM output)
apex.util.escapeHTML('<script>alert("xss")</script>');
// Returns: &lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;

// Show/hide spinner
var spinner = apex.util.showSpinner($('#my-region'));
// ... after async work:
spinner.remove();

// Template substitution (like APEX substitution strings)
apex.util.applyTemplate('Hello &P1_NAME.! You have &P1_COUNT. items.');

// Debounce (for search-as-you-type replacing Forms timer triggers)
var debouncedSearch = apex.util.debounce(function() {
    apex.region('results').refresh();
}, 300);
$('#P1_SEARCH').on('keyup', debouncedSearch);

// Get/set element value (works with APEX items and plain elements)
apex.util.getTopApex();   // get top-level apex object (useful in iframes)

// Escaping for CSS selectors
apex.util.escapeCSS('P1_ITEM');  // escapes special chars for jQuery selectors
```

---

## apex.debug — Client-Side Debugging

Replaces Forms debug messages.

```javascript
apex.debug.error('Critical error: ', errorObj);   // always logged
apex.debug.warn('Warning: ', msg);                 // level 2+
apex.debug.info('Info: ', data);                   // level 4+
apex.debug.trace('Entering function: ', name);     // level 6+
apex.debug.getLevel();                             // current debug level
apex.debug.LOG_LEVEL.ERROR;   // 1
apex.debug.LOG_LEVEL.WARN;    // 2
apex.debug.LOG_LEVEL.INFO;    // 4
apex.debug.LOG_LEVEL.TRACE;   // 6
```

---

## apex.lang — Internationalization

Replaces Forms message text / multi-language support.

```javascript
// Get translated message (from APEX text messages)
apex.lang.getMessage('MY_MSG_KEY');
apex.lang.formatMessage('HELLO_USER', userName);   // with substitution
apex.lang.hasMessage('MY_MSG_KEY');                // check if exists

// Add messages client-side (typically done via page JS)
apex.lang.addMessages({
    'CONFIRM_DELETE': 'Desea eliminar este registro?',
    'SAVED': 'Guardado correctamente.'
});
```

---

## apex.locale — Number/Date Formatting

Replaces Forms format masks.

```javascript
// Number formatting (replaces Forms FORMAT_MASK on NUMBER items)
apex.locale.formatNumber(1234567.89);              // "1,234,567.89" (locale-dependent)
apex.locale.formatNumber(1234567.89, 'FML999G999G999G990D00');

// Currency
apex.locale.getCurrency();          // "$", etc.
apex.locale.getGroupSeparator();    // ","
apex.locale.getDecimalSeparator();  // "."

// Date formatting
apex.locale.formatDate(new Date(), 'DD-MON-YYYY');
```

---

## apex.theme — Theme/UI Control

Replaces Forms SHOW_VIEW, HIDE_VIEW, canvas visibility.

```javascript
// Collapsible regions (replaces Forms tab canvas show/hide)
apex.theme.openRegion('my_static_id');
apex.theme.closeRegion('my_static_id');

// Check if region is open
// Use: $('#my_static_id').is(':visible')
```

---

## apex.storage — Client-Side Storage

Replaces Forms global variables that persist across forms.

```javascript
// Cookies
apex.storage.getCookie('MY_COOKIE');
apex.storage.setCookie('MY_COOKIE', 'value');

// Scoped local storage (per app+page or per app)
var store = apex.storage.getScopedLocalStorage({
    prefix: 'MY_APP',
    usePageId: false     // false = shared across pages
});
store.setItem('lastSearch', 'test');
store.getItem('lastSearch');
store.removeItem('lastSearch');

// Session storage (per tab)
var sessionStore = apex.storage.getScopedSessionStorage({prefix: 'MY_APP'});
```

---

## apex.actions — Keyboard Shortcuts & Actions

Replaces Forms KEY-* triggers (KEY-F9, KEY-COMMIT, etc.).

```javascript
// Create action context (for custom keyboard shortcuts)
var actions = apex.actions.createContext('myContext', document);

// Add action (replaces Forms KEY-* trigger)
actions.add({
    name: 'save-record',
    label: 'Guardar',
    shortcut: 'Ctrl+S',
    action: function() {
        apex.page.submit('SAVE');
        return true;  // handled
    }
});

// Lookup existing action
apex.actions.lookup('save-record');

// Remove action
actions.remove('save-record');

// Built-in APEX actions (already available):
// 'change-page'       — navigate to page
// 'open-search'       — open spotlight search
// 'apex-help'         — show help
```

---

## Legacy Functions ($v, $s, $x)

Still work but prefer apex.item() API. Common in migrated code.

```javascript
$v('P1_ITEM')                  // get value (same as apex.item('P1_ITEM').getValue())
$s('P1_ITEM', 'value')         // set value (same as apex.item('P1_ITEM').setValue('value'))
$x('P1_ITEM')                  // get DOM element (same as document.getElementById('P1_ITEM'))
$v2('P1_ITEM')                 // get value as array (for multi-select)

// jQuery shortcuts
$('#P1_ITEM').val()             // raw jQuery — does NOT trigger APEX events
// ALWAYS prefer apex.item().getValue/setValue — they handle LOV display values,
// cascade refresh, and change events properly.
```

---

## Forms Trigger to APEX Pattern Mapping

### WHEN-NEW-FORM-INSTANCE -> Page Load (Execute when Page Loads)
```javascript
// In "Execute when Page Loads" or DA on Page Load
$(function() {
    // Initialize page state
    apex.item('P1_DATE').setValue(new Date().toISOString().slice(0,10));
    if (apex.item('P1_MODE').getValue() === 'VIEW') {
        $(':input').prop('disabled', true);
    }
});
```

### WHEN-VALIDATE-ITEM -> DA on Change + Validation
```javascript
// DA: Event=Change, Selection=Item(P1_MONTO), Action=Execute JavaScript
var val = parseFloat(apex.item('P1_MONTO').getValue());
if (isNaN(val) || val <= 0) {
    apex.message.showErrors([{
        type: 'error', location: ['page','inline'],
        pageItem: 'P1_MONTO', message: 'Monto debe ser positivo.'
    }]);
    apex.da.cancel();
} else {
    apex.message.clearErrors();
}
```

### WHEN-BUTTON-PRESSED -> DA on Click or Button Submit
```javascript
// Option A: DA with Execute JavaScript
apex.message.confirm('Procesar seleccionados?', function(ok) {
    if (ok) {
        apex.server.process('PROCESS_SELECTED', {
            x01: apex.item('P1_ID').getValue(),
            pageItems: '#P1_STATUS'
        }, {
            success: function(data) {
                apex.message.showPageSuccess('Procesado.');
                apex.region('report').refresh();
            }
        });
    }
});
```

### KEY-COMMIT -> Ctrl+S Keyboard Shortcut
```javascript
// In Execute when Page Loads
apex.actions.add({
    name: 'quick-save',
    shortcut: 'Ctrl+S',
    action: function(e) {
        e.preventDefault();
        apex.page.submit('SAVE');
        return true;
    }
});
```

### POST-QUERY -> After Refresh DA or Column Formatting
```javascript
// DA: Event=After Refresh, Selection=Region(report_static_id)
// Replaces POST-QUERY trigger that modified displayed values
$('#report_static_id td[headers="STATUS"]').each(function() {
    var val = $(this).text().trim();
    if (val === 'ANULADO') {
        $(this).css('color', 'red');
    }
});
```

### ON-ERROR -> apex.message.showErrors
```javascript
// In error handling callback
apex.message.clearErrors();
apex.message.showErrors([{
    type: 'error',
    location: 'page',
    message: errorMessage,
    unsafe: false  // true if message contains trusted HTML
}]);
```
