# Supabase integration

## Status

- Repository: `https://github.com/efeardaaric/Careerly`, branch `main`.
- Organization: `Carrerly` (`uyxpwwhblcasewqxpozz`), free plan.
- Live project: `Careerly`, reference `vazbrulhurklpdakhckx`, URL `https://vazbrulhurklpdakhckx.supabase.co`, region `eu-west-1` (Ireland). Owner created it; dashboard reports Healthy and the GitHub repository is connected.
- Baseline applied through the authenticated SQL editor in one transaction to the verified empty database. Supabase migration history records `20261004220000` / `careerly_baseline`; Alembic records `0002_billing_persistence`. Do not apply this baseline again.
- All nine public tables were checked: RLS enabled, no `anon` SELECT permission and no `authenticated` INSERT permission. Live Auth settings enable email signup with confirmation; Google and Apple are disabled. A malformed bearer was rejected with HTTP 403.
- Gitignored `.config/supabase.json` and `backend/.env` contain the live URL/public key. The backend now connects to the Supabase session pooler using the owner's supplied database credential. Client-to-pooler TLS, all nine application tables and Alembic `0002_billing_persistence` were verified. The local `.env` is readable/writable only by its owner. Full live login/CV processing is not yet verified.
- GitHub working directory is `.`. After the owner's approval, automatic production deployment was enabled and saved for branch `main`. No paid preview branching was enabled.
- Flutter supports Supabase email signup/signin, confirmation-required signup, session recovery, token refresh and signout. Session tokens use platform secure storage, not SharedPreferences.
- Backend `AUTH_MODE=supabase` validates each bearer with the configured project's Auth service; a supplied user header cannot select another account. Billing uses the Supabase user UUID.
- SQL migrations are in `supabase/migrations`. All application tables have RLS enabled and deny direct `anon`/`authenticated` access. Flutter accesses CV and billing data through the authenticated FastAPI service, not through unrestricted database writes.

## Dashboard

1. Project creation and repository connection are complete. Keep automatic table exposure disabled and automatic RLS enabled.
2. In project GitHub integration settings, verify repository `efeardaaric/Careerly`, branch `main`, working directory `.`. Enable production migration deployment only. Preview branching is not required and may incur charges.
3. The baseline is already deployed. It creates CV and billing tables and stamps Alembic at `0002_billing_persistence`. Subsequent schema changes must keep Supabase SQL migrations and Alembic revisions aligned; do not independently apply conflicting migrations.
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

Verified session-pooler template for this project:

```dotenv
DATABASE_URL=postgresql+psycopg://postgres.vazbrulhurklpdakhckx:URL_ENCODED_PASSWORD@aws-0-eu-west-1.pooler.supabase.com:5432/postgres?sslmode=require
```

The owner's credential has now been placed only in gitignored `backend/.env`; the private database URL must also be configured in the chosen hosting provider's secret environment before deployment. Never commit that file or put the credential into Flutter.

Supabase does **not** host this Python/FastAPI service. A separate deployment and HTTPS `API_BASE_URL` are still needed for a live application. Run the existing backend locally for development; do not claim cloud scoring works until a deployed service is connected and smoke-tested.

The Docker image supports the hosting provider's `PORT` environment variable (default `8787`) and excludes local credentials from its build context. Use `/ready` for deployment health checks: it returns HTTP 503 until the configured database is reachable and its revision matches the repository's Alembic head (currently `0002_billing_persistence`). `/health` remains a liveness endpoint and reports database availability separately. Hosting account/provider selection and server environment configuration are still required before actual hosting deployment.

## Deliberate limits

- Raw CV uploads are not retained (`STORE_ORIGINAL_CV=false`); no public Storage bucket is created.
- Builder documents, saved jobs, applications and personalization retain the current device-local behavior. Cross-device synchronization is not implemented by this integration.
- The profile's delete action explicitly deletes device-local data and signs out. It does **not** delete the Supabase Auth account or server-side records. Cloud account deletion needs a separately implemented authenticated server workflow before store release.
- Actual Apple/Google purchase verification remains a separate existing release blocker.

## Verification

Local verification (2026-10-04): 108 Flutter tests and 87 backend tests passed; Ruff passed; unsigned iOS Release built successfully (26.7 MB). Backend tests ignore local `.env` and use isolated development settings/databases, including after live Supabase configuration. Live checks cover project health, baseline deployment, both migration trackers, RLS/table permissions, Auth settings, invalid-token rejection, server-to-PostgreSQL connectivity and client-to-pooler TLS. The local FastAPI process returned HTTP 200 from `/health` and `/ready` against the live database, and HTTP 401 for a spoofed `X-User-Id` without a bearer. Automatic GitHub deployment is enabled and persisted after reload. Successful real-user login, CV end-to-end checks and the publicly hosted FastAPI service remain pending.

Run `flutter analyze`, `flutter test`, and backend `pytest`/`ruff`. Live smoke checks must additionally verify email confirmation/login, token refresh/recovery/signout, rejection of anonymous database access, CV ownership isolation, usage persistence, and connected PostgreSQL migrations. Unit tests do not replace those cloud checks.

References: [Flutter initialization](https://supabase.com/docs/reference/dart/initializing), [GitHub integration](https://supabase.com/docs/guides/deployment/branching/github-integration), [Postgres connections](https://supabase.com/docs/guides/database/connecting-to-postgres).
