import { defineConfig } from '@playwright/test';

const PORT = 4178;
const BASE = `http://127.0.0.1:${PORT}`;

// Mobile-first viewports + one tablet. Uses the system Chrome (channel:'chrome')
// so there's no separate browser download.
const VIEWPORTS = [
  { name: 'mobile-360', width: 360, height: 740 },
  { name: 'mobile-390', width: 390, height: 844 },
  { name: 'mobile-414', width: 414, height: 896 },
  { name: 'tablet-768', width: 768, height: 1024 },
];

export default defineConfig({
  testDir: '.',
  testMatch: /.*\.spec\.mjs/,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: false, // one shared prod session; keep request volume gentle
  workers: 1,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'report' }]],
  use: {
    baseURL: BASE,
    channel: 'chrome',
    headless: true,
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
  projects: VIEWPORTS.map((v) => ({
    name: v.name,
    use: { viewport: { width: v.width, height: v.height } },
  })),
  webServer: {
    command: 'node server.mjs',
    url: BASE,
    reuseExistingServer: true,
    timeout: 30_000,
    env: { PORT: String(PORT) },
  },
});
