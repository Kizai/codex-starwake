import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

test('animation renders, seeks, replays and skips without external requests', async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROME_PATH || undefined,
  });
  try {
    const page = await browser.newPage({
      viewport: { width: 1280, height: 720 },
      deviceScaleFactor: 1,
    });
    const errors = [],
      external = [];
    page.on('pageerror', (error) => errors.push(error.message));
    page.on('request', (request) => {
      if (/^https?:/.test(request.url())) external.push(request.url());
    });
    await page.goto(
      new URL('../web/index.html?manual=1', import.meta.url).href,
    );
    await page.waitForFunction(() => Boolean(window.shorekeeper));
    assert.equal(await page.evaluate(() => window.shorekeeper.duration), 6800);
    await page.evaluate(() => window.shorekeeper.seek(3200));
    assert.equal(await page.evaluate(() => window.shorekeeper.time), 3200);
    await mkdir(new URL('../test-results/', import.meta.url), {
      recursive: true,
    });
    await page.screenshot({
      path: fileURLToPath(
        new URL('../test-results/desktop.png', import.meta.url),
      ),
    });
    if (process.env.UPDATE_PREVIEW === '1')
      await page.screenshot({
        path: fileURLToPath(
          new URL('../docs/images/shorekeeper-preview.png', import.meta.url),
        ),
      });
    await page.keyboard.press('Escape');
    await page.locator('#endcard').waitFor({ state: 'visible' });
    await page.locator('#replay').click();
    assert.equal(await page.locator('#endcard').isVisible(), false);
    await page.waitForFunction(() => window.shorekeeper.time > 100);
    await page.keyboard.press('Escape');
    assert.equal(await page.evaluate(() => window.shorekeeper.finished), true);
    await page.setViewportSize({ width: 390, height: 844 });
    await page.evaluate(() => window.shorekeeper.seek(3200));
    await page.screenshot({
      path: fileURLToPath(
        new URL('../test-results/mobile.png', import.meta.url),
      ),
    });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.emulateMedia({ reducedMotion: 'reduce' });
    assert.equal(
      await page
        .locator('.aura')
        .evaluate((el) => getComputedStyle(el).display),
      'none',
    );
    assert.deepEqual(errors, []);
    assert.deepEqual(external, []);
  } finally {
    await browser.close();
  }
});
