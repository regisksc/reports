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
