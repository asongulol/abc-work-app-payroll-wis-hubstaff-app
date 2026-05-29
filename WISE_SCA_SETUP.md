# Wise SCA (2FA) setup — required to FUND via API

Funding a transfer from your Wise balance is a sensitive action and Wise
protects it with **Strong Customer Authentication (SCA)**. The first funding
call returns **HTTP 403** with an `x-2fa-approval` one-time token; the request
must be **re-signed with your private key** and retried with `x-2fa-approval` +
`X-Signature` headers.

The `wise-payouts` edge function already implements this flow (`fetchWithSca` /
`signOtt`). All you need to do is generate a key pair, register the **public**
key with Wise, and give the edge function the **private** key.

> **This only matters for the API funding path** (the `feature/api-payouts-*`
> work). Drafting, the manual batch CSV, and reconciliation don't fund and don't
> need SCA. Test the whole funding flow in the **Wise sandbox first** —
> `WISE_API_BASE=https://api.sandbox.transferwise.tech`.

---

## 1. Generate an RSA key pair

```bash
# Private key in PKCS#8 (-----BEGIN PRIVATE KEY-----), which Web Crypto needs.
# Use genpkey (NOT `openssl genrsa`, which emits PKCS#1 and won't import).
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out wise_sca_private.pem
# Public key (you upload this to Wise)
openssl rsa -in wise_sca_private.pem -pubout -out wise_sca_public.pem
```

## 2. Register the PUBLIC key with Wise

In the Wise web UI: **Settings → API tokens** (the same area as your API token)
→ add/manage **public keys** → upload `wise_sca_public.pem`. (In the sandbox,
do this in the sandbox dashboard.) Wise ties the key to your profile so it can
verify your signatures.

## 3. Give the edge function the PRIVATE key

Store the private key as a Supabase secret (server-side only — it never touches
the browser):

```bash
supabase secrets set WISE_PRIVATE_KEY="$(cat wise_sca_private.pem)"
```

Then redeploy:

```bash
supabase functions deploy wise-payouts --no-verify-jwt
```

Delete the local `wise_sca_private.pem` once it's set, or store it somewhere
safe and out of the repo (it's covered by `.gitignore`'s `*.pem` rule).

## 4. How the flow works (already implemented)

1. The `fund` action POSTs to `/v3/profiles/{id}/transfers/{tid}/payments`.
2. If Wise returns **403 + `x-2fa-approval`**, `fetchWithSca` signs that token
   (RSA, SHA-256, PKCS#1 v1.5 → base64) and retries with
   `x-2fa-approval: <token>` and `X-Signature: <signature>`.
3. A successful SCA session is valid ~5 minutes for low-risk endpoints.
4. If SCA is required but `WISE_PRIVATE_KEY` is missing, the function returns a
   clear `ok:false` ("WISE_PRIVATE_KEY not set …") and stores it as `fund_error`
   — it does not silently fail.

## 5. Test (sandbox)

1. Set `WISE_API_BASE` to the sandbox, register the public key in the sandbox,
   set `WISE_PRIVATE_KEY`, redeploy.
2. Enable `companies.api_payouts_enabled` for one test company.
3. Draft a transfer, then fund it via the app. Confirm:
   - the first attempt without the key gives the clear `fund_error`;
   - with the key set, funding succeeds and `payments.funded_at` is written.
4. Only after sandbox works end-to-end, repeat with the live `WISE_API_BASE`
   and a real public key — and keep the flag off until you opt a company in.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `WISE_PRIVATE_KEY not set` on fund | Set the secret (step 3) and redeploy. |
| 403 persists after retry | Public key not registered (step 2), or it doesn't match the private key. Re-derive the public key from the same private key. |
| Signature rejected | Ensure the key is PKCS#8 PEM (`-----BEGIN PRIVATE KEY-----`). Convert if needed: `openssl pkcs8 -topk8 -nocrypt -in old.pem -out wise_sca_private.pem`. |
