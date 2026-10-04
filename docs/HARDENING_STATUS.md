# Careerly hardening — 2026-10-04

## Implemented

- LocalStore reset notifications clear all initialized feature controllers, including optimization and pending billing request IDs, on sign-out, demo reset, local deletion and user switching.
- Delayed analysis, optimization, Builder AI and entitlement responses cannot restore the preceding user's state. API responses from an earlier session are rejected.
- Entitlement cache fallback is scoped to the requested user and denies metered/premium actions offline while retaining read access.
- New CV analysis/reanalysis and rewrite endpoints enforce plan access; targeted rewrites require Pro. CV usage changes share the CV transaction.
- SQL usage counters use conditional atomic updates; request records are scoped per user. Subscriptions and usage survive worker/server restarts. Expired subscriptions use Free limits.
- Migration `0002_billing_persistence` adds the billing tables. Run `alembic upgrade head` against an existing production database before deployment.
- API-backed successful actions are not charged again by the Flutter UI. Local Builder creation continues to use the explicit usage endpoint.
- Personalized target fields are passed to the API parser.
- All four PDF templates use bundled Noto Sans fonts with Turkish glyphs and no font downloads.
- Existing backend lint findings are resolved. Added tests cover concurrency, persistence, rollback, migration, API quotas, session cleanup, stale responses and offline PDF export.

## Still required before production

- Choose/configure a real identity provider, connect its Flutter SDK, verify its tokens on the backend and move production tokens to secure storage.
- Configure Apple/Google product IDs, connect native purchases, implement receipt validation and renewal/refund notifications. Existing production providers deliberately remain unavailable.
- Connect local account deletion to authenticated backend-wide deletion; define a retention policy for CV and billing data.
- Provision a TLS API host, database, CORS allowlist, legal pages and signed store builds.
- Run complete device smoke tests with the actual production providers. Automated test success does not verify live login or store transactions.

No existing user database was migrated or cleared by this work. Migration and persistence tests use temporary databases.

## Verification

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 105 tests passed.
- `backend/.venv/bin/python -m pytest backend/tests -q -p no:cacheprovider`: 74 tests passed. Existing third-party deprecation warnings remain.
- `backend/.venv/bin/ruff check --no-cache backend/app backend/tests`: passed.
- `flutter build ios --release --no-codesign --no-pub`: passed; unsigned `build/ios/iphoneos/Runner.app` (26.0 MB).
- `git diff --check`: passed.
- `scripts/secret_scan.sh`: no high-confidence patterns in tracked files; untracked files are outside that script's scope.
- Billing persistence, concurrent quota enforcement and Alembic upgrade/downgrade were tested with SQLite temporary databases. A live PostgreSQL deployment and physical-device smoke tests were not run.
