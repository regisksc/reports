const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const context = vm.createContext({});
const sourcePath = require.resolve('./dist/reports-portal-ui.js');
vm.runInContext(fs.readFileSync(sourcePath, 'utf8'), context, { filename: sourcePath });
const ui = context.ReportsUI;

test('category counts use singular only for one service', () => {
  const catalog = [{ group: 'Street' }, { group: 'Trees' }, { group: 'Trees' }];
  const counts = Array.from(ui.services(catalog, '').matchAll(/<small>(\d+ services?)<\/small>/g), (match) => match[1]);
  assert.deepEqual(counts, ['1 service', '2 services']);
});

test('service information explains resident requirements without City schema terms', () => {
  const base = { id: 'example', name: 'Example service', group: 'Street', evidence: '5 configured questions; Picklist; location boundary City Boundary; locator behavior must be captured.' };
  const variants = [
    ['guest-form', 'required', /No account is needed/, /A photo is required/],
    ['contact-required', 'optional', /Your contact details are required/, /Photos are optional/],
    ['account-required', 'none', /A City account is required/, /No photo is needed/],
    ['unknown', 'unknown', /not verified yet/, /Photo requirements will be shown/],
  ];
  for (const [mode, attachments, contactCopy, photoCopy] of variants) {
    const markup = ui.service({ ...base, mode, attachments });
    assert.match(markup, contactCopy);
    assert.match(markup, photoCopy);
    assert.doesNotMatch(markup, /configured questions|Picklist|location boundary|locator behavior|authenticated form/);
  }
});

test('normalizes catalog evidence without inventing capabilities', () => {
  const rows = [
    { name: 'Flooding', group: 'Street', evidence: 'anonymous available; 4 configured questions, 0 preliminary questions; required attachments; advertised limit 5; location boundary City Boundary;' },
    { name: 'Inspection', group: 'Street', evidence: 'contact required, guest form readable; 5 configured questions, 0 preliminary questions; no upload control; no map control.' },
    { name: 'Containers', group: 'Collection', evidence: 'account required; form, validation and authenticated contract remain unverified.' },
    { name: 'Other', group: 'Other', evidence: 'not established' },
    { name: 'Trees/Pests', group: 'Park', evidence: 'anonymous available; optional attachments;' }
  ];
  assert.deepEqual(JSON.parse(JSON.stringify(rows.map(ui.normalize))), [
    { ...rows[0], id: 'flooding', mode: 'guest-form', boundary: 'City Boundary', attachmentLimit: 5, attachments: 'required', questionCount: 4, preliminaryCount: 0 },
    { ...rows[1], id: 'inspection', mode: 'contact-required', boundary: null, attachmentLimit: null, attachments: 'none', questionCount: 5, preliminaryCount: 0 },
    { ...rows[2], id: 'containers', mode: 'account-required', boundary: null, attachmentLimit: null, attachments: 'unknown', questionCount: null, preliminaryCount: null },
    { ...rows[3], id: 'other', mode: 'unknown', boundary: null, attachmentLimit: null, attachments: 'unknown', questionCount: null, preliminaryCount: null },
    { ...rows[4], id: 'trees-pests', mode: 'guest-form', boundary: null, attachmentLimit: null, attachments: 'optional', questionCount: null, preliminaryCount: null }
  ]);
});

test('the portal shell exposes five resident destinations and a local-demo notice', () => {
  const html = fs.readFileSync(path.join(__dirname, 'reports-full-portal.html'), 'utf8');
  for (const name of ['Home', 'Services', 'Nearby', 'My Reports', 'Account']) assert.match(html, new RegExp(`>${name}<`));
  assert.match(html, /Local design demo/);
});

test('the mobile shell uses the Reports font and raised orange action treatment', () => {
  const css = fs.readFileSync(path.join(__dirname, 'reports-portal.css'), 'utf8');
  assert.match(css, /reports-mona-sans\.woff2/);
  assert.match(css, /--accent:\s*#ff9600/);
  assert.match(css, /box-shadow:\s*0 4px 0/);
});

test('search finds services by name or group without changing the source', () => {
  const catalog = [{ name: 'Flooding', group: 'Street Problems' }, { name: 'Tree Trimming', group: 'Trees' }];
  assert.deepEqual(JSON.parse(JSON.stringify(ui.search(catalog, 'street'))), [catalog[0]]);
  assert.deepEqual(JSON.parse(JSON.stringify(ui.search(catalog, 'TRIMMING'))), [catalog[1]]);
  assert.deepEqual(JSON.parse(JSON.stringify(ui.search(catalog, 'missing'))), []);
  assert.equal(ui.search(catalog, '').length, 2);
});

test('escapes text before inserting it into the portal', () => {
  assert.equal(ui.escape(`<a title="x">&'`), '&lt;a title=&quot;x&quot;&gt;&amp;&#39;');
});

test('the services view renders groups or matching services', () => {
  const catalog = [{ id: 'flooding', name: 'Flooding', group: 'Street Problems' }, { id: 'trees', name: 'Tree Trimming', group: 'Trees' }];
  assert.match(ui.services(catalog, ''), /Street Problems/);
  assert.match(ui.services(catalog, ''), /data-group="Trees"/);
  assert.match(ui.services(catalog, 'flood'), /data-service="flooding"/);
  assert.match(ui.services(catalog, 'missing'), /No services found/);
});

test('category and service views expose the evidence and appropriate next step', () => {
  const catalog = [{ id: 'flooding', name: 'Flooding', group: 'Street', mode: 'guest-form', evidence: 'Guest configuration observed.' }, { id: 'bins', name: 'Bins', group: 'Street', mode: 'account-required', evidence: 'Account required.' }, { id: 'other', name: 'Other', group: 'Street', mode: 'unknown', evidence: 'Not verified.' }];
  assert.match(ui.category(catalog, 'Street'), /data-service="flooding"/);
  assert.match(ui.service(catalog[0]), /data-action="start-flow"/);
  assert.match(ui.service(catalog[1]), /data-route="signin"/);
  assert.match(ui.service(catalog[2]), /not verified/i);
});

test('the page includes the catalog and local runtime dependencies', () => {
  const html = fs.readFileSync(path.join(__dirname, 'reports-full-portal.html'), 'utf8');
  const catalog = JSON.parse(html.match(/<script id="catalog-data" type="application\/json">([\s\S]*?)<\/script>/)[1]);
  assert.equal(catalog.length, 68);
  assert.match(html, /src="dist\/reports-portal-flow\.js"/);
  assert.match(html, /src="dist\/reports-portal-ui\.js"/);
});

test('resident views explain local-only capabilities and provide navigation', () => {
  for (const route of ['nearby', 'history', 'account', 'signin', 'register', 'recovery', 'profile', 'settings', 'help', 'lookup']) {
    assert.match(ui.page(route), /data-od-id=/);
    assert.match(ui.page(route), /data-(route|action|form)=/);
  }
  assert.match(ui.page('nearby'), /not live/i);
  assert.match(ui.page('lookup'), /not connected/i);
});

test('local reports show their preview status and unavailable City actions', () => {
  const report = { id: 'demo-1', name: 'Flooding', status: 'Preview complete' };
  assert.match(ui.reports([]), /No local reports/);
  assert.match(ui.reports([report]), /data-report="demo-1"/);
  assert.match(ui.report(report), /Preview complete/);
  assert.match(ui.report(report), /City status.*not available/i);
  assert.match(ui.report(report), /edit or cancel.*not verified/i);
});

test('delegated navigation opens the searchable catalog and service details', () => {
  const handlers = {};
  const main = { innerHTML: 'Home screen', focus() {} };
  const nav = [{ dataset: { route: 'home' }, setAttribute() {}, removeAttribute() {} }, { dataset: { route: 'services' }, setAttribute() {}, removeAttribute() {} }];
  const doc = { querySelector: () => main, querySelectorAll: (selector) => selector === '.bottom-nav button' ? nav : [], addEventListener: (name, fn) => { handlers[name] = fn; }, getElementById: () => ({ focus() {}, setSelectionRange() {} }) };
  const catalog = [{ id: 'flooding', name: 'Flooding', group: 'Street', mode: 'guest-form', evidence: 'Guest form.' }];
  ui.mount(doc, catalog, {}, { getItem: () => null, setItem() {} });
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  click({ route: 'services' });
  assert.match(main.innerHTML, /Services/);
  handlers.input({ target: { dataset: { search: '' }, value: 'flood' } });
  assert.match(main.innerHTML, /data-service="flooding"/);
  click({ service: 'flooding' });
  assert.match(main.innerHTML, /<h1 class="page-title">Flooding<\/h1>/);
  assert.match(main.innerHTML, /data-action="start-flow"/);
  click({ group: 'Street' });
  assert.match(main.innerHTML, /data-service="flooding"/);
  click({ route: 'home' });
  assert.equal(main.innerHTML, 'Home screen');
  handlers.click({ target: { closest: () => null } });
  handlers.input({ target: { dataset: {} } });
});

test('the page starts the portal with the embedded catalog and local flow', () => {
  const html = fs.readFileSync(path.join(__dirname, 'reports-full-portal.html'), 'utf8');
  const bootstrap = html.match(/<script id="portal-bootstrap">([\s\S]*?)<\/script>/)[1];
  const data = html.match(/<script id="catalog-data" type="application\/json">([\s\S]*?)<\/script>/)[1];
  let count = 0;
  const sandbox = { document: { getElementById: () => ({ textContent: data }) }, ReportsUI: { normalize: (row) => row, mount: (_doc, rows) => { count = rows.length; } }, ReportsFlow: {}, localStorage: {}, location: { search: '' }, URLSearchParams };
  vm.runInNewContext(bootstrap, sandbox);
  assert.equal(count, 68);
});

test('developer entry is hidden unless explicitly enabled outside resident settings', () => {
  const html = fs.readFileSync(path.join(__dirname, 'reports-full-portal.html'), 'utf8');
  assert.match(html, /data-developer hidden/);
  assert.doesNotMatch(ui.page('settings'), /developer/i);
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const developer = { hidden: true };
  const doc = { querySelector: (selector) => selector === 'main' ? main : developer, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  ui.mount(doc, [], {}, { getItem: () => null, setItem() {} }, true);
  assert.equal(developer.hidden, false);
  handlers.click({ target: { closest: () => ({ dataset: { route: 'developer' } }) }, preventDefault() {} });
  assert.match(main.innerHTML, /no network/i);
});

test('main navigation opens the local resident modules', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  ui.mount(doc, [], {}, { getItem: () => null, setItem() {} });
  for (const route of ['account', 'history', 'nearby', 'settings', 'help', 'signin', 'register', 'recovery', 'profile', 'lookup']) {
    handlers.click({ target: { closest: () => ({ dataset: { route } }) }, preventDefault() {} });
    assert.match(main.innerHTML, new RegExp(`data-od-id="${route}"`));
  }
});

test('the flow bridge saves local drafts and demo receipts without City calls', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  let saved = '';
  const storage = { getItem: () => null, setItem: (_key, value) => { saved = value; } };
  const flow = { create: () => ({ step: 'details' }), render: (draft) => `<p>${draft.step}</p>`, handle: (draft, _service, action, payload) => ({ ...draft, step: action === 'submit' ? 'confirmation' : action, confirmation: action === 'submit', payload }) };
  const catalog = [{ id: 'flooding', name: 'Flooding', group: 'Street', mode: 'guest-form', evidence: 'Guest form.' }];
  ui.mount(doc, catalog, flow, storage);
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  click({ service: 'flooding' });
  click({ action: 'start-flow' });
  assert.match(main.innerHTML, /details/);
  handlers.input({ target: { dataset: { flowField: 'description' }, type: 'text', value: 'Water' } });
  assert.match(main.innerHTML, /details/);
  handlers.input({ target: { dataset: { flowField: 'extra' }, type: 'checkbox', checked: true } });
  handlers.input({ target: { dataset: { flowField: 'contactMode' }, type: 'select-one', tagName: 'SELECT', value: 'named' } });
  click({ action: 'flow-next' });
  assert.match(main.innerHTML, /next/);
  click({ action: 'flow-save' });
  assert.match(main.innerHTML, /My Reports/);
  assert.equal(JSON.parse(saved)[0].status, 'Draft');
  click({ service: 'flooding' });
  click({ action: 'start-flow' });
  click({ action: 'flow-submit' });
  assert.match(main.innerHTML, /confirmation/);
  assert.equal(JSON.parse(saved)[1].status, 'Preview complete');
  click({ action: 'flow-submit' });
  click({ route: 'history' });
  const reportId = JSON.parse(saved)[1].id;
  assert.match(main.innerHTML, /Flooding/);
  click({ report: reportId });
  assert.match(main.innerHTML, /City status not available/);
});

test('typing a report field preserves the focused input instead of replacing it', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  const flow = { create: () => ({}), render: () => '<textarea>Original</textarea>', handle: (draft) => draft };
  ui.mount(doc, [{ id: 'f', name: 'Flooding', group: 'Street', mode: 'guest-form' }], flow, { getItem: () => null, setItem() {} });
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  click({ service: 'f' });
  click({ action: 'start-flow' });
  main.innerHTML = 'typing remains intact';
  handlers.input({ target: { dataset: { flowField: 'description' }, type: 'textarea', value: 'x' } });
  assert.equal(main.innerHTML, 'typing remains intact');
});

test('changing a conditional control keeps keyboard focus on that control', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  let focused = false;
  const doc = { querySelector: (selector) => selector === 'main' ? main : { focus() { focused = true; } }, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  const flow = { create: () => ({}), render: () => '<input data-flow-field="extra">', handle: (draft) => draft };
  ui.mount(doc, [{ id: 'f', name: 'Flooding', group: 'Street', mode: 'guest-form' }], flow, { getItem: () => null, setItem() {} });
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  click({ service: 'f' });
  click({ action: 'start-flow' });
  handlers.input({ target: { dataset: { flowField: 'extra' }, type: 'checkbox', checked: true } });
  assert.equal(focused, true);
});

test('account and lookup forms produce only local demo outcomes', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  const values = { 'reports-demo-records': JSON.stringify([{ id: 'local-1', name: 'Flooding', status: 'Draft' }]) };
  const storage = { getItem: (key) => values[key] || null, setItem: (key, value) => { values[key] = value; } };
  ui.mount(doc, [], {}, storage);
  const submit = (form, entries) => handlers.submit({ target: { dataset: { form }, elements: entries.map(([name, value]) => ({ name, value })) }, preventDefault() {} });
  submit('register', [['name', 'Alex'], ['email', 'demo@example.com']]);
  assert.match(main.innerHTML, /saved locally/i);
  assert.match(values['reports-demo-profile'], /Alex/);
  submit('signin', [['email', 'demo@example.com'], ['password', 'secret']]);
  assert.doesNotMatch(values['reports-demo-profile'], /secret/);
  assert.match(values['reports-demo-profile'], /Alex/);
  submit('profile', [['name', 'Sam'], ['email', 'demo@example.com']]);
  assert.match(values['reports-demo-profile'], /Sam/);
  submit('recovery', [['email', 'demo@example.com']]);
  assert.match(main.innerHTML, /no email was sent/i);
  submit('lookup', [['reference', 'missing']]);
  assert.match(main.innerHTML, /no local preview/i);
  submit('lookup', [['reference', 'local-1']]);
  assert.match(main.innerHTML, /City status not available/i);
  handlers.submit({ target: { dataset: {} }, preventDefault() {} });
});

test('profile fields restore locally saved values', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const fields = [{ dataset: { profile: 'name' } }, { dataset: { profile: 'email' } }, { dataset: { profile: 'missing' } }];
  const doc = { querySelector: () => main, querySelectorAll: (selector) => selector === '[data-profile]' ? fields : [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  const storage = { getItem: (key) => key === 'reports-demo-profile' ? '{"name":"Alex","email":"demo@example.com"}' : null, setItem() {} };
  ui.mount(doc, [], {}, storage);
  handlers.click({ target: { closest: () => ({ dataset: { route: 'profile' } }) }, preventDefault() {} });
  assert.equal(fields[0].value, 'Alex');
  assert.equal(fields[1].value, 'demo@example.com');
  assert.equal(fields[2].value, undefined);
});

test('local report management resumes drafts and updates follow preferences', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  let saved = JSON.stringify([{ id: 'local-1', name: 'Flooding', serviceId: 'flooding', status: 'Draft', draft: { step: 'details' } }]);
  const storage = { getItem: () => saved, setItem: (_key, value) => { saved = value; } };
  const flow = { render: (draft) => `<p>${draft.step}</p>`, handle: (draft) => draft };
  ui.mount(doc, [{ id: 'flooding', name: 'Flooding', group: 'Street', mode: 'guest-form' }], flow, storage);
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  click({ report: 'local-1' });
  assert.match(main.innerHTML, /Resume draft/);
  click({ action: 'follow' });
  assert.equal(JSON.parse(saved)[0].following, true);
  click({ action: 'follow' });
  assert.equal(JSON.parse(saved)[0].following, false);
  click({ action: 'follow' });
  click({ action: 'resume' });
  assert.match(main.innerHTML, /details/);
  click({ action: 'flow-save' });
  assert.equal(JSON.parse(saved)[0].following, true);
  click({ route: 'history' });
  click({ report: 'local-1' });
  click({ action: 'delete-local' });
  assert.equal(JSON.parse(saved).length, 0);
  assert.match(main.innerHTML, /No local reports/);
});

test('nearby filters and update preferences stay on the device', () => {
  const handlers = {};
  const main = { innerHTML: 'Home', focus() {} };
  const fields = [{ dataset: { setting: 'area' }, type: 'text' }, { dataset: { setting: 'updates' }, type: 'checkbox' }, { dataset: { setting: 'unset' }, type: 'text' }];
  const doc = { querySelector: () => main, querySelectorAll: (selector) => selector === '[data-setting]' ? fields : [], addEventListener: (name, fn) => { handlers[name] = fn; } };
  const values = {};
  const storage = { getItem: (key) => values[key] || null, setItem: (key, value) => { values[key] = value; } };
  ui.mount(doc, [], {}, storage);
  const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
  handlers.input({ target: { dataset: { setting: 'area' }, type: 'text', value: 'Hollywood' } });
  handlers.input({ target: { dataset: { setting: 'updates' }, type: 'checkbox', checked: true } });
  click({ route: 'nearby' });
  assert.equal(fields[0].value, 'Hollywood');
  assert.equal(fields[1].checked, true);
  click({ action: 'nearby-filter' });
  assert.match(main.innerHTML, /not live/i);
  click({ action: 'nearby-clear' });
  assert.equal(JSON.parse(values['reports-demo-settings']).area, '');
});

test('nearby preview includes the observed search and district filters', () => {
  const markup = ui.page('nearby');
  for (const text of ['Start date', 'End date', 'Neighborhood Council District', 'Council District', 'Map or list', '2,000']) assert.match(markup, new RegExp(text));
});

test('unreadable or unavailable preview storage keeps resident pages usable without replacing saved data', () => {
  const recoverable = { id: 'local-kept', name: 'Flooding', serviceId: 'flooding', status: 'Draft', draft: { step: 'details' } };
  const cases = [
    { records: '{', settings: '{', profile: '{' },
    { records: '{}', settings: '[]', profile: '[]' },
    { records: 'null', settings: 'null', profile: 'null' },
    { records: '1', settings: 'true', profile: '"text"' },
    { records: JSON.stringify([recoverable, null, [], 'invalid', {}, { id: 1, name: 'Invalid', status: 'Draft' }, { id: 'invalid', name: 1, status: 'Draft' }, { id: 'invalid', name: 'Invalid', status: 1 }]), settings: '[]', profile: '[]', retained: true },
    { deniedReads: true },
    { deniedWrites: true }
  ];
  for (const scenario of cases) {
    const handlers = {};
    const main = { innerHTML: 'Home', focus() {}, querySelector: () => main.innerHTML.includes('data-storage-notice') ? {} : null, insertAdjacentHTML: (_position, markup) => { main.innerHTML += markup; } };
    const doc = { querySelector: () => main, querySelectorAll: () => [], addEventListener: (name, fn) => { handlers[name] = fn; } };
    const values = { 'reports-demo-records': scenario.records, 'reports-demo-settings': scenario.settings, 'reports-demo-profile': scenario.profile };
    const original = { ...values };
    let writes = 0;
    const storage = {
      getItem(key) { if (scenario.deniedReads) throw new Error('Storage blocked'); return values[key] || null; },
      setItem(key, value) { writes++; if (scenario.deniedWrites) throw new Error('Storage full'); values[key] = value; }
    };
    const flow = { create: () => ({ step: 'details' }), render: (draft) => `<p>${draft.step}</p>`, handle: (draft) => draft };
    const catalog = [{ id: 'flooding', name: 'Flooding', group: 'Street', mode: 'guest-form' }];
    let serviceHandoff = '';
    const navigation = { initialRoute: 'services', navigateRoute: (route) => route === 'settings', startService: (service) => { if (serviceHandoff) return false; serviceHandoff = service.id; return true; } };
    assert.doesNotThrow(() => ui.mount(doc, catalog, flow, storage, false, navigation));
    const click = (dataset) => handlers.click({ target: { closest: () => ({ dataset }) }, preventDefault() {} });
    assert.match(main.innerHTML, /Services/);
    click({ route: 'nearby' });
    handlers.input({ target: { dataset: { setting: 'area' }, type: 'text', value: 'Hollywood' } });
    assert.match(main.innerHTML, /stay in this session/);
    click({ action: 'nearby-clear' });
    click({ route: 'account' });
    click({ route: 'settings' });
    assert.match(main.innerHTML, /Your account/);
    handlers.submit({ target: { dataset: { form: 'profile' }, elements: [{ name: 'name', value: 'Session resident' }] }, preventDefault() {} });
    assert.match(main.innerHTML, /Your account/);
    assert.match(main.innerHTML, /profile updated for this session/);
    click({ service: 'flooding' });
    click({ action: 'start-flow' });
    assert.equal(serviceHandoff, 'flooding');
    assert.match(main.innerHTML, /Before you start/);
    click({ action: 'start-flow' });
    click({ action: 'flow-save' });
    assert.match(main.innerHTML, /data-report="local-/);
    if (scenario.retained) assert.match(main.innerHTML, /data-report="local-kept"/);
    const reportId = main.innerHTML.match(/data-report="(local-[^"]+)"/)[1];
    click({ report: reportId });
    click({ action: 'follow' });
    click({ action: 'delete-local' });
    assert.match(main.innerHTML, /Existing stored data has not been replaced/);
    assert.deepEqual(values, original);
    assert.equal(writes, scenario.deniedWrites ? 3 : 0);
  }
});

test('guided flow controls inherit the raised Reports visual language', () => {
  const css = fs.readFileSync(path.join(__dirname, 'reports-portal.css'), 'utf8');
  assert.match(css, /\.flow-field/);
  assert.match(css, /\.flow-actions/);
  assert.match(css, /\.flow-error/);
});
