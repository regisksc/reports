const { test, before, after, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

let browser;
let page;

before(async () => { browser = await chromium.launch(); });
after(async () => { await browser.close(); });
beforeEach(async () => {
  page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.route(/^https?:/, (route) => route.abort());
  await page.goto(pathToFileURL(path.join(__dirname, 'reports-prototype-buttons-v2.html')).href);
});
afterEach(async () => { await page.close(); });

test('Start a Report opens all services without replacing an unfinished v2 report', async () => {
  const original = await page.evaluate(() => {
    const draft = { ...ReportsApp.createDraft(), address: '200 N Spring St', step: 3, details: 'Keep these details' };
    localStorage.setItem('reports-prototype-v1', JSON.stringify({ draft }));
    return draft;
  });
  await page.reload();
  await page.getByRole('button', { name: 'Start a report', exact: true }).click();
  await page.locator('#service-search').waitFor({ state: 'visible', timeout: 1500 });
  const actual = await page.evaluate(() => ({
    draft: ReportsApp.getState().draft,
    services: JSON.parse(document.getElementById('reports-service-catalog').textContent).length,
    bottomBars: document.querySelectorAll('.bottom-nav,[role="tablist"]').length,
  }));
  assert.deepEqual(actual, { draft: original, services: 68, bottomBars: 0 });
});

test('choosing illegal dumping retains the v2 map, six-step report and replacement confirmation', async () => {
  await page.evaluate(() => localStorage.clear());
  await page.reload();
  await page.getByRole('button', { name: 'Start a report', exact: true }).click();
  await page.getByRole('textbox', { name: 'Search services' }).fill('Illegal Dumping');
  await page.locator('[data-service="illegal-dumping-item-pickup"]').click();
  await page.locator('[data-action="start-flow"]').click();
  await page.locator('[data-od-id="flow-step-label"]').waitFor({ state: 'visible', timeout: 1500 });
  await page.locator('[data-field="address"]').fill('200 N Spring St');
  await page.getByRole('button', { name: 'Save and close' }).click();
  await page.getByRole('button', { name: 'Start a report', exact: true }).click();
  await page.getByRole('textbox', { name: 'Search services' }).fill('Illegal Dumping');
  await page.locator('[data-service="illegal-dumping-item-pickup"]').click();
  await page.locator('[data-action="start-flow"]').click();
  await page.getByRole('dialog').waitFor({ state: 'visible', timeout: 1500 });
  await page.getByRole('button', { name: 'Keep it' }).click();
  assert.deepEqual(await page.evaluate(() => ({
    address: ReportsApp.getState().draft.address,
    mapPreserved: Boolean(document.getElementById('maplibre-vendor')),
    inspectorPreserved: Boolean(document.getElementById('reports-api-inspector-runtime')),
    flowStep: ReportsApp.getState().draft.step,
  })), { address: '200 N Spring St', mapPreserved: true, inspectorPreserved: true, flowStep: 0 });
});
