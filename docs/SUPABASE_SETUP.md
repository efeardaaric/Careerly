# Supabase integration

## Status

- Repository: `https://github.com/efeardaaric/Careerly`, branch `main`.
- Organization: `Carrerly` (`uyxpwwhblcasewqxpozz`), free plan.
- The dashboard project form is prepared; creation requires the owner to enter and submit the database password. No live project, database migration or end-to-end cloud verification has been claimed.
- Flutter supports Supabase email signup/signin, confirmation-required signup, session recovery, token refresh and signout. Session tokens use platform secure storage, not SharedPreferences.
- Backend `AUTH_MODE=supabase` validates each bearer with the configured project's Auth service; a supplied user header cannot select another account. Billing uses the Supabase user UUID.
- SQL migrations are in `supabase/migrations`. All application tables have RLS enabled and deny direct `anon`/`authenticated` access. Flutter accesses CV and billing data through the authenticated FastAPI service, not through unrestricted database writes.

## Dashboard

1. Complete project creation in `Carrerly` with name `Careerly`, Europe region and the selected `efeardaaric/Careerly` repository. Keep automatic table exposure disabled and automatic RLS enabled.
2. In project GitHub integration settings, verify repository `efeardaaric/Careerly`, branch `main`, working directory `.`. Enable production migration deployment only. Preview branching is not required and may incur charges.
3. Deploy the baseline migration to the **new, empty project**. It creates CV and billing tables and stamps Alembic at `0002_billing_persistence`. Do not run this baseline against an existing Careerly database. Subsequent schema changes must keep Supabase SQL migrations and Alembic revisions aligned; do not independently apply conflicting migrations.
4. Obtain Project URL and the **publishable** (or legacy anon) key. Never put a secret/service-role key or database password into Flutter or GitHub.
5. Auth → URL Configuration: add `io.careerly.app://login-callback` to the redirect allowlist. Set the Site URL to the real web destination when hosted; `localhost:3000` in config is only a local placeholder. GitHub database deployment does not apply these Auth settings automatically.
6. Email confirmations remain enabled. Google/Apple OAuth repository and mobile callback handling are present, but those providers require the owner's OAuth credentials and dashboard enablement. They are not configured merely by creating Supabase.

## Flutter

Create a gitignored `.config/supabase.json` based on `supabase.client.example.json`, then:

```sh
flutter run --dart-define-from-file=.config/supabase.json
```

Set `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` and `API_BASE_URL`. Configuring Supabase disables mock auth even in development. Production also requires a real HTTPS backend host and cannot use mock billing. Public API keys are safe to distribute, but are not authorization credentials for application table writes.

## Backend

Set these in gitignored `backend/.env`:

```dotenv
AUTH_MODE=supabase
SUPABASE_URL=https://PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
DATABASE_URL=postgresql+psycopg://postgres.PROJECT_REF:URL_ENCODED_PASSWORD@SESSION_POOLER_HOST:5432/postgres?sslmode=require
```

Use the exact **session pooler** host from Dashboard → Connect, with the database password URL-encoded. The transaction pooler on port 6543 is not this configuration. Migration-controlled Supabase mode disables automatic `create_all`, including in development. After successful baseline deployment, `alembic current` must report `0002_billing_persistence`.

Supabase does **not** host this Python/FastAPI service. A separate deployment and HTTPS `API_BASE_URL` are still needed for a live application. Run the existing backend locally for development; do not claim cloud scoring works until a deployed service is connected and smoke-tested.

## Deliberate limits

- Raw CV uploads are not retained (`STORE_ORIGINAL_CV=false`); no public Storage bucket is created.
- Builder documents, saved jobs, applications and personalization retain the current device-local behavior. Cross-device synchronization is not implemented by this integration.
- The profile's delete action explicitly deletes device-local data and signs out. It does **not** delete the Supabase Auth account or server-side records. Cloud account deletion needs a separately implemented authenticated server workflow before store release.
- Actual Apple/Google purchase verification remains a separate existing release blocker.

## Verification

Local verification (2026-10-04): 108 Flutter tests and 84 backend tests passed; Ruff passed; unsigned iOS Release built successfully (26.7 MB). Live Supabase provisioning and PostgreSQL/remote-auth smoke checks remain pending the owner's project creation step.

Run `flutter analyze`, `flutter test`, and backend `pytest`/`ruff`. Live smoke checks must additionally verify email confirmation/login, token refresh/recovery/signout, rejection of anonymous database access, CV ownership isolation, usage persistence, and connected PostgreSQL migrations. Unit tests do not replace those cloud checks.

References: [Flutter initialization](https://supabase.com/docs/reference/dart/initializing), [GitHub integration](https://supabase.com/docs/guides/deployment/branching/github-integration), [Postgres connections](https://supabase.com/docs/guides/database/connecting-to-postgres).
