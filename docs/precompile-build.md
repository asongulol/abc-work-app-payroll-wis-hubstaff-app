# Precompile build (drop in-browser Babel) — how to flip it on

**Status: tooling ready, NOT yet live.** The source apps still ship the
`<script type="text/babel">` block + `babel-standalone` CDN and transpile in the
browser. `tools/build-apps.mjs` produces a precompiled copy under `dist/` that
removes Babel entirely. Flip the live deploy to serve `dist/` **only after a
Cloudflare preview deploy verifies it** (see below) — a bad flip white-screens
every user.

## Why

`babel-standalone` is a ~2.8 MB download whose only job is to transpile ~700 KB of
JSX **on every visit** (no caching of the compiled output) — the dominant
time-to-interactive cost, worst on the modest devices PH contractors use.
Precompiling at deploy removes both the 2.8 MB download and the per-visit
transpile. Measured: `app/index.html` 723 KB → 514 KB, `legacy.html` 567 → 400 KB,
`portal/index.html` 124 → 101 KB (minified), plus no Babel download at all.

## What the tool does

`node tools/build-apps.mjs` (or `npm run build`, which stamps first):

- Reads `app/index.html`, `app/legacy.html`, `portal/index.html` (the JSX source —
  **never mutated**; keep editing these normally).
- Transpiles the `text/babel` block with esbuild (`loader:'jsx'`, classic
  `React.createElement` runtime — matches babel-standalone's default — `minify`,
  `target:es2019`), wraps it in an IIFE (preserving the current `data-type="module"`
  no-global-leakage scoping), emits it as a plain `<script>`, and removes the
  `babel-standalone` CDN tag.
- Copies every sibling asset (`_headers`, `version.txt`, favicons, logo, the
  portal's `wrangler.jsonc`) verbatim.
- Writes everything to `dist/app/` and `dist/portal/`. `dist/` is gitignored.

`npm run build:check` validates compilation without writing (use in CI/pre-push).

## How to flip the live deploy

The apps deploy as Cloudflare static-asset Workers that serve the committed files
directly (`portal/wrangler.jsonc` → `assets.directory: "./"`); there is no build
step in the deploy today. Pick ONE wiring:

**Option A — Cloudflare build command (recommended; keeps git-connected deploy):**
In each Worker's settings (or wrangler config), set a build command and point the
asset directory at the built folder:
- Build command: `npm ci && npm run build`
- Admin Worker assets dir: `dist/app`  · Portal Worker assets dir: `dist/portal`
Cloudflare runs the build on each push; esbuild is already a devDependency.

**Option B — commit the built output:** run `npm run build` locally and commit
`dist/` (remove it from `.gitignore`), then point each Worker's assets dir at
`dist/app` / `dist/portal`. Simpler infra, but you must rebuild before every commit.

## Verify BEFORE flipping prod (mandatory — live money app)

1. Deploy `dist/` to a **Cloudflare preview** (not prod).
2. Confirm the page renders (no white screen) and the Network tab shows **no
   `babel-standalone` request**.
3. Smoke the critical paths: login → Calculate a payroll period → open a contractor
   profile → (admin) print an agreement; on the portal: login → view pay.
4. Confirm `?ui=classic` / `legacy.html` kill-switch still loads.
5. Confirm `version.txt` self-reload still fires after a new build.
Only then point prod at `dist/`.

## CSP note (optional tightening, after flip)

Once Babel is gone, `_headers` no longer needs `'unsafe-eval'`, and
`https://cdnjs.cloudflare.com` is only needed for React/ReactDOM (still CDN-loaded).
You may drop `'unsafe-eval'` from `script-src` in `dist/*/`'s `_headers` for a
tighter policy — verify the app still loads after.
