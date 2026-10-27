const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('the standalone portal preview resolves its complete local asset bundle', () => {
  const html = fs.readFileSync(path.join(__dirname, 'reports-full-portal.html'), 'utf8');
  const css = fs.readFileSync(path.join(__dirname, 'reports-portal.css'), 'utf8');
  const references = [
    ...Array.from(html.matchAll(/(?:src|href)="([^"#]+)"/g), (match) => match[1]),
    ...Array.from(css.matchAll(/url\(['"]?([^'"\)]+)['"]?\)/g), (match) => match[1]),
  ].filter((reference) => !reference.startsWith('data:'));

  assert.ok(references.includes('dist/reports-portal-flow.js'));
  assert.ok(references.includes('dist/reports-portal-ui.js'));
  assert.ok(references.includes('reports-mona-sans.woff2'));
  for (const reference of references) {
    assert.ok(!/^(?:https?:|\/|\.\.)/.test(reference));
    assert.ok(fs.existsSync(path.join(__dirname, reference)), reference);
  }
  const embeddedCatalog = JSON.parse(html.match(/<script id="catalog-data" type="application\/json">([\s\S]*?)<\/script>/)[1]);
  assert.deepEqual(embeddedCatalog, require('./reports-portal-catalog.json'));
});
