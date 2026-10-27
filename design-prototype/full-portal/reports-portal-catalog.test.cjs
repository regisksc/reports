const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const catalog = require('./reports-portal-catalog.json');

test('the service catalog preserves the 68 advertised services across 14 groups', () => {
  assert.equal(catalog.length, 68);
  assert.equal(new Set(catalog.map((service) => service.group)).size, 14);
  assert.equal(new Set(catalog.map((service) => service.name)).size, 68);
  assert.ok(catalog.every((service) => service.evidence.length > 0));
  assert.equal(
    createHash('sha256').update(JSON.stringify(catalog)).digest('hex'),
    '45a6150688376ec55b73a1bbf78d41f5fd15d957ec3354dde2aea11fda8d3e0f',
  );
});
