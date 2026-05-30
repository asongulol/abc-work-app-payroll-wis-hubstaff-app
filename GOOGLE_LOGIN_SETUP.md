# Google sign-in setup

The app now requires a **Google sign-in** before it loads (a login *gate*). This
adds a real login screen and records the signed-in email as the **audit actor**
(instead of the constant `"admin"`).

> **Scope (important):** this is a *gate only*. Data access still uses the anon
> key and the current permissive RLS — so this gives you a login + accountability,
> not a hardened data boundary. The real boundary (scoped RLS) is **Phase 2** in
> [docs/AUTH_RLS_DESIGN.md](docs/AUTH_RLS_DESIGN.md).

> **⚠️ Do this setup BEFORE merging `feature/google-login` to main.** Once merged,
> the app won't load past the sign-in screen until the Google provider is enabled
> — so configure and test on the branch first.

---

## 1. Create Google OAuth credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/) → create
   (or pick) a project.
2. **APIs & Services → OAuth consent screen**: configure it (External is fine for
   a personal Google account). Add your email as a test user, or publish.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**:
   - Application type: **Web application**.
   - **Authorized redirect URI**: your Supabase callback —
     `https://<your-project-ref>.supabase.co/auth/v1/callback`
     (find `<project-ref>` in Supabase → Project Settings → API).
4. Copy the **Client ID** and **Client secret**.

## 2. Enable the provider in Supabase

1. Supabase dashboard → **Authentication → Providers → Google** → enable.
2. Paste the **Client ID** and **Client secret** from step 1. Save.
3. **Authentication → URL Configuration → Redirect URLs**: add the URL(s) the app
   is served from (e.g. `http://localhost:8000`, and your production URL). The app
   redirects back to `window.location.origin + pathname`, so that exact origin
   must be allowlisted.

## 3. Restrict who can sign in (recommended)

Google sign-in lets **anyone with a Google account** authenticate. For a gate,
that means a stranger could pass the login screen (they'd still only reach the
app shell, since data uses the existing anon key + RLS — but you don't want that).
Options, lightest first:

1. **Keep the consent screen in "Testing"** and add only your own Google
   account(s) as test users — Google then blocks everyone else at sign-in.
2. When you do the **Phase 2 RLS rewrite**, the `admin_users` allowlist becomes
   the real enforcement (see the design doc).

## 4. Test (on the branch)

1. Serve the branch's `app/index.html`, open it, connect with URL + anon key.
2. You should see **Sign in → Sign in with Google**. Complete the Google flow.
3. You should land in the app, with your **email shown in the top bar** next to
   **Sign out**.
4. Make any change and confirm the **Audit Log** now shows your email as the
   actor (not "admin").
5. **Sign out** returns you to the sign-in screen; **Disconnect** also clears the
   Supabase connection.

Only after this works end-to-end, merge `feature/google-login` to main.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "provider is not enabled" on the button | Enable Google in Supabase Auth (step 2). |
| `redirect_uri_mismatch` from Google | The redirect URI in Google Cloud must be exactly the Supabase `/auth/v1/callback` URL (step 1.3). |
| Lands back on the sign-in screen after Google | Add the app's origin to Supabase → Auth → URL Configuration → Redirect URLs (step 2.3). |
| Stranger can sign in | Keep the consent screen in Testing with only your accounts as test users (step 3). |
