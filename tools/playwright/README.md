# Authed mobile tests (Playwright)

Extends the login-only smoke test (`tools/mobile-smoke-test.mjs`) to the
**authenticated** admin screens — the tabs, tables, and modals that sit behind
the Google sign-in gate and that the smoke test can't reach.

## How it works

- Tests run against the **current branch code** in `app/` (served locally by
  `server.mjs` on `http://127.0.0.1:4178`), **not** the deployed site — so you
  test what you're about to ship.
- They use a **real, logged-in Supabase session**. Because the Supabase session
  is a JWT in `localStorage` (validated server-side by token), it's
  origin-independent: you capture it once on the prod origin (where Google OAuth
  is whitelisted) and the tests inject that token into the local origin.
- **Read-only guarantee:** a network guard (`authed-test.mjs`) lets `GET`/`HEAD`
  and Supabase Auth token-refresh through, but **blocks any POST/PATCH/PUT/DELETE**
  to `/rest/v1/`, `/rpc/`, `/functions/v1/`, `/storage/v1/object`. If a test ever
  triggers a write, the guard fulfills it with a benign response (nothing reaches
  the DB) **and fails the test**. So tests read your real prod data but can never
  modify it.

## Setup (once)

```bash
cd tools/playwright
npm install            # installs @playwright/test (uses your system Chrome, no browser download)
```

## Run

```bash
# 1. Capture a login (opens a visible Chrome; complete the Google sign-in once).
#    Saves the session token to .auth/supabase-session.json (gitignored).
npm run capture

# 2. Run the authed mobile tests at 360 / 390 / 414 / 768 px.
npm test
```

### If `npm run capture` gets stuck on Cloudflare ("verify you are human")

Cloudflare's bot challenge trips on the Playwright-automated browser and can
loop forever. Sidestep it — grab the session from your **normal** Chrome (which
already passed Cloudflare and is logged in). The tests load from localhost, so
they never touch Cloudflare; they only need the Supabase JWT.

1. In your normal Chrome, on **https://payroll.abbilabs.com** (logged in), open
   DevTools (`Cmd+Opt+J`) → **Console**, paste this one line, press Enter:

   ```js
   copy(JSON.stringify(Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('sb-')))))
   ```

   This copies **all** Supabase localStorage entries (handles the modern
   base64/chunked token format) to your clipboard. If it copies `{}`, that tab
   isn't signed in — sign in, then re-run the line.

   ⚠ Copy the snippet's **output** (what lands on your clipboard after Enter) —
   don't paste a shell command or these instructions. `npm run import` now
   rejects anything that isn't a real session, so a wrong paste fails loudly
   instead of silently leaving you on the sign-in screen.

2. In the terminal:

   ```bash
   npm run import     # reads the clipboard (macOS pbpaste) and saves the session
   npm test
   ```

   Fallbacks if clipboard reading is blocked: `pbpaste | npm run import`, or
   paste into a file and `npm run import -- that-file.txt`.

# Watch it drive the browser:
npm run test:headed

# Open the HTML report after a run:
npm run report
```

The access token expires after ~1 hour; supabase-js auto-refreshes it during a
run, but if a run fails with "still on the sign-in screen", just re-run
`npm run capture`.

## What it asserts (per viewport)

- The app gets **past the Google login** (authed shell renders).
- **Every primary tab** (Contractors, Time Import, Run Payroll, Reports, Audit
  Log, Documents, Portal Settings, Companies, Admin) loads with **no horizontal
  page overflow**.
- Opening/closing a **modal** causes no overflow and the sheet doesn't exceed the
  viewport width.
- **No uncaught page errors / console errors** across the run.

## Files

| File | Purpose |
|------|---------|
| `playwright.config.mjs` | Projects for the 4 viewports; starts `server.mjs`; system Chrome |
| `server.mjs` | Serves `../../app` locally |
| `capture-login.mjs` | One-time prod login via Playwright → saves session token (gitignored) |
| `import-token.mjs` | Cloudflare fallback: import a session token copied from your normal browser |
| `authed-test.mjs` | Fixture: injects the session + enforces the read-only write-guard |
| `mobile-authed.spec.mjs` | The read-only navigation + modal tests |

## Safety notes

- `.auth/` (the captured session) is **gitignored** — never commit it.
- Tests point at **production data** by default (read-only). To point at a
  different Supabase project, set `localStorage` `sb_url`/`sb_anon` overrides or
  capture against a staging URL via `PROD_URL=… npm run capture`.
