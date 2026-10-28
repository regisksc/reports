const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('repository guidance names the v2 design as the canonical reference', () => {
  const readme = fs.readFileSync(path.join(__dirname, '../README.md'), 'utf8');
  const inspector = fs.readFileSync(path.join(__dirname, '../docs/api-inspector.md'), 'utf8');
  const html = fs.readFileSync(path.join(__dirname, 'reports-prototype-buttons-v2.html'), 'utf8');
  const catalog = JSON.parse(html.match(/<script id="reports-service-catalog" type="application\/json">([\s\S]*?)<\/script>/)[1]);
  assert.deepEqual({
    repositoryEntry: readme.includes('(design-prototype/reports-prototype-buttons-v2.html)'),
    inspectorEntry: inspector.includes('(../design-prototype/reports-prototype-buttons-v2.html)'),
    oldAuthority: inspector.includes('Canonical Open Design project:'),
    catalog,
  }, { repositoryEntry: true, inspectorEntry: true, oldAuthority: false, catalog: require('./full-portal/reports-portal-catalog.json') });
});
