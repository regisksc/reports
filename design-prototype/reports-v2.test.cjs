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

test('the gear adds account journeys while keeping the original v2 settings', async () => {
  await page.getByRole('button', { name: 'Settings', exact: true }).click();
  await page.locator('[data-action="account"]').waitFor({ state: 'visible', timeout: 1500 });
  const retained = await page.locator('section[data-od-id$="-settings"]').evaluateAll((nodes) => nodes.map((node) => node.dataset.odId));
  await page.locator('[data-action="account"]').click();
  await page.getByRole('button', { name: 'Profile', exact: false }).click();
  await page.getByRole('textbox', { name: 'Display name' }).fill('Neighborhood helper');
  await page.getByRole('button', { name: 'Save demo profile' }).click();
  await page.getByRole('button', { name: 'Preferences & accessibility' }).click();
  await page.getByRole('switch', { name: 'Reduce motion' }).click();
  assert.deepEqual(await page.evaluate((retained) => ({
    retained,
    view: ReportsApp.getState().view,
    reduceMotion: ReportsApp.getState().settings.reduceMotion,
    profile: JSON.parse(localStorage.getItem('reports-demo-profile')).name,
    bottomBars: document.querySelectorAll('.bottom-nav').length,
  }), retained), {
    retained: ['motion-settings', 'saved-contact-settings', 'privacy-settings', 'local-data-settings'],
    view: 'settings', reduceMotion: true, profile: 'Neighborhood helper', bottomBars: 0,
  });
});

test('Nearby opens from Home and preserves saved filters and the existing draft', async () => {
  await page.evaluate(() => localStorage.setItem('reports-prototype-v1', JSON.stringify({ draft: { ...ReportsApp.createDraft(), address: 'Keep this location' } })));
  await page.reload();
  await page.getByRole('button', { name: /Nearby/ }).waitFor({ state: 'visible', timeout: 1500 });
  await page.getByRole('button', { name: /Nearby/ }).click();
  await page.getByRole('textbox', { name: 'Search an area' }).fill('Echo Park');
  await page.getByRole('button', { name: 'Apply demo filters' }).click();
  await page.getByRole('button', { name: 'Back to home' }).click();
  await page.getByRole('button', { name: /Nearby/ }).click();
  assert.deepEqual(await page.evaluate(() => ({
    area: document.querySelector('[data-setting="area"]').value,
    heading: document.querySelector('.task-header-title').textContent,
    address: ReportsApp.getState().draft.address,
    bottomBars: document.querySelectorAll('.bottom-nav').length,
  })), { area: 'Echo Park', heading: 'Nearby', address: 'Keep this location', bottomBars: 0 });
});

test('the existing saved reports page can reopen a completed report for another service', async () => {
  await page.getByRole('button', { name: 'Start a report', exact: true }).click();
  await page.getByRole('textbox', { name: 'Search services' }).fill('Flooding');
  await page.locator('[data-service="flooding"]').click();
  await page.locator('[data-action="start-flow"]').click();
  await page.locator('[data-flow-field="description"]').fill('Water across the road');
  await page.locator('[data-action="flow-next"]').click();
  await page.locator('[data-flow-field="address"]').fill('200 N Spring St');
  await page.locator('[data-action="flow-confirm"]').click();
  await page.locator('[data-action="flow-next"]').click();
  await page.locator('[data-action="flow-add-photo"]').click();
  await page.locator('[data-action="flow-next"]').click();
  await page.locator('[data-flow-field="contactMode"]').selectOption('anonymous');
  await page.locator('[data-action="flow-next"]').click();
  await page.locator('[data-flow-field="reviewConsent"]').check();
  await page.locator('[data-action="flow-submit"]').click();
  await page.getByRole('button', { name: 'Back to home' }).click();
  await page.getByRole('button', { name: /View saved reports/ }).click();
  await page.locator('[data-action="service-history"]').waitFor({ state: 'visible', timeout: 1500 });
  await page.locator('[data-action="service-history"]').click();
  await page.locator('[data-report]').click();
  assert.deepEqual(await page.evaluate(() => ({
    heading: document.querySelector('[data-od-id="report-detail"] h1').textContent,
    record: JSON.parse(localStorage.getItem('reports-demo-records'))[0].status,
    nativeLikeHistoryKept: Boolean(ReportsApp.renderMarkup({ ...ReportsApp.createState(), view: 'history' }).includes('Needs confirmation')),
  })), { heading: 'Flooding', record: 'Preview complete', nativeLikeHistoryKept: true });
});
