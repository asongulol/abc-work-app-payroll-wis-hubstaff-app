# Automation & Deployment

How the dev cycle and deploys are automated for the HR & Payroll app. Everything
here is built on the scripts already in `tools/` — nothing requires a service you
don't already use.

## One-time setup

```bash
npm install            # if you haven't already
npm run hooks:install  # wire git hooks into .git/hooks
```

For the AI changelog, set your key in your shell (e.g. `~/.zshrc`):

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

The key is read from your environment only — it is never stored in the repo.

## npm scripts

| Script | What it does |
|--------|--------------|
| `npm run lint` | eslint + HTML syntax check (`tools/check-html-syntax.mjs`) |
| `npm run build` | Stamp build info, then precompile apps into `dist/` |
| `npm run build:check` | Precompile to memory only, fail on any error (no write) |
| `npm run check` | `lint` + `build:check` — the umbrella pre-flight check |
| `npm run check:secrets` | Scan staged changes for secrets/PII |
| `npm run deploy` | Full deploy: build → Workers → changed edge functions |
| `npm run deploy:frontend` | Build + deploy the Cloudflare Workers only |
| `npm run deploy:functions` | Deploy only the changed Supabase edge functions |
| `npm run docs` | Generate an AI changelog entry from the current diff |
| `npm run hooks:install` | Install the git hooks (run once after clone) |

## Git hooks

Installed by `npm run hooks:install`. Source lives in `tools/hooks/` (tracked);
the installer copies them into `.git/hooks/` (not tracked).

### pre-commit → `tools/check-secrets.sh`
Blocks a commit if staged changes contain:
- Provider tokens (Supabase JWT/service-role, Wise, Hubstaff), `sk-…` / Stripe
  keys, bearer tokens, or generic high-entropy `key/secret/token/password` values.
- `*.csv` files (contractor PII — these are gitignored, but this also catches
  `git add -f`).

Bypass a known-safe match with `git commit --no-verify` (use sparingly).

### pre-push → `tools/gen-changelog.sh` (+ checks)
1. Runs `npm run lint` and `npm run build:check`. **A failure aborts the push** —
   broken JSX or a failed precompile can't reach `main`.
2. Generates an AI changelog entry from the diff being pushed and prepends it to
   `CHANGELOG.md` (best-effort; never blocks the push).

Bypass with `git push --no-verify`.

> Note: the changelog commit lands on your *next* push (normal pre-push timing).

## Continuous integration

`.github/workflows/ci.yml` runs on every push and PR to `main`:
`npm ci` → `npm run lint` → `npm run build:check`.

Checks-only by design — **no production access, no secrets required.** It's the
backstop for any time a local hook was skipped (`--no-verify`) or someone pushes
from a machine without hooks installed.

## Deploying

The live **frontend deploy is `git push origin main`** — both Cloudflare Workers
are git-connected and auto-rebuild in ~15s ([README → Deploying](../README.md)).
There is no separate prod `wrangler deploy`. The only manual piece is keeping the
build stamp fresh and deploying changed edge functions.

`npm run deploy` (= `tools/deploy.sh`) runs, in order:

1. **Pre-flight** — clean-tree check + `lint` + `build:check`.
2. **Frontend** — runs `npm run stamp` (refreshes the visible Build footer +
   `version.txt`), then offers to `git add/commit/push` so Cloudflare rebuilds.
3. **Backend** — deploys **only the edge functions changed** since the last
   `deploy-fn-*` tag (via `supabase functions deploy`), then tags the deploy.

Flags:

```bash
bash tools/deploy.sh --frontend        # stamp + push only
bash tools/deploy.sh --functions       # changed functions only
bash tools/deploy.sh --all-functions   # force-redeploy all 10 functions
bash tools/deploy.sh --yes             # non-interactive (skips prompts)
```

Requires the `supabase` CLI on PATH (and `supabase link` run once) for function
deploys. Verify a frontend deploy landed:

```bash
curl -s https://abc-work-app-payroll-wis-hubstaff-app.asongulol.workers.dev/ | grep 'const BUILD'
```

> **Always stamp before pushing.** If you skip it the footer freezes and looks
> like the deploy didn't land (it did). The pre-push hook reminds you; `npm run
> deploy` does it for you.

## Suggested everyday flow

```text
edit app/ or portal/ or supabase/functions/*
  → git commit            (pre-commit blocks secrets/PII)
  → git push              (pre-push runs checks + writes changelog)
  → CI confirms green on GitHub
  → npm run deploy        (preview → verify → flip prod)
```

## Files

| File | Role |
|------|------|
| `tools/hooks/pre-commit`, `pre-push` | Hook entrypoints (tracked) |
| `tools/install-hooks.sh` | Installs hooks into `.git/hooks` |
| `tools/check-secrets.sh` | Secret/PII scanner (pre-commit) |
| `tools/gen-changelog.sh` | AI changelog from diff (pre-push / `npm run docs`) |
| `tools/deploy.sh` | Build + Wrangler + changed-function deploy |
| `.github/workflows/ci.yml` | Checks-only CI |
| `CHANGELOG.md` | Generated; one entry per push |
