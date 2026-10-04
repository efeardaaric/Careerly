# Careerly AI

Calm, bilingual (EN/TR) career companion for CV readiness, ATS clarity, job matching, and structured CV building.

**Working product name** — brand tokens and naming are replaceable without touching feature logic.

## Phase status

- **Phase 1:** Splash → language → onboarding → mock auth → personalization → home shell.
- **Phase 2:** CV upload UI, mock analysis pipeline, section review, readiness results.
- **Phase 3:** FastAPI analysis engine + `ApiResumeAnalysisRepository` (API is the default).
- **Phase 4:** Job Match engine — paste JD, alignment score, skill evidence, Optimize CV suggestions.
- **Phase 5:** Professional CV Builder — `ResumeDocument` → section editors → ATS templates → searchable PDF; AI rewrite/translate; structured Check CV.
- **Phase 6:** Monetization — entitlements, Free/Pro limits, paywall, usage metering, mock purchases.
- **Applications / optimization:** Local application tracking, CV versions, deterministic improvement suggestions, guarded AI rewrite.
- **Hardening:** Central session cleanup, server CV limits, durable billing counters/subscriptions, target-field forwarding, bundled Turkish PDF fonts. See `docs/HARDENING_STATUS.md`.
- **Phase 8.1:** RC1 blocker fixes — production fail-closed config/auth/billing, backend Bearer auth + IDOR, release docs. **READY FOR INTERNAL TESTING** (not store submission).
- **UI/UX polish:** Visual-only pass — design tokens, shared processing view, reduced card density, signature-screen hierarchy (see polish report in agent docs store).

Not included: OCR, cover letters, interview AI, scraping, credits marketplace, live production configuration, real purchase verification, store publishing. Supabase Auth and migration support are implemented; cloud setup is pending.

## Stack

- Flutter / Dart — Riverpod, GoRouter, Dio, file_picker, pdf/printing, gen-l10n EN/TR
- Backend — FastAPI under `backend/` (PDF/DOCX parse, ATS, AI provider, scoring, Job Match, Builder rewrite/translate/check)

## Run Flutter

```bash
flutter pub get
# Backend scoring (default). Start the API first; see backend/README.md.
flutter run -d chrome --web-port=43123 \
  --dart-define=ENV=dev \
  --dart-define=API_BASE_URL=http://127.0.0.1:8787

# Explicit fixture data, development only
flutter run --dart-define=USE_MOCK_ANALYSIS=true

# On-device rules engine, no backend
flutter run --dart-define=USE_LOCAL_ANALYSIS=true
```

| Define | Purpose |
|--------|---------|
| `ENV` | `dev` / `staging` / `production` |
| `API_BASE_URL` | Backend origin. Dev default `http://127.0.0.1:8787`. Android emulator: `http://10.0.2.2:8787`. |
| `USE_MOCK_ANALYSIS` | `true` selects fixture analysis. Forbidden when `ENV=production`. |
| `USE_LOCAL_ANALYSIS` | `true` selects the on-device rules engine. |

## Run backend

See [`backend/README.md`](backend/README.md).

```bash
cd backend && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8787
```

## Architecture

```
lib/features/analyze/     # CV analysis (UI + mock/api repos)
lib/features/jobs/        # Job Match (UI + mock/api repos)
lib/features/cv_builder/  # ResumeDocument, templates, PDF, Builder UI
backend/app/              # FastAPI (analyze + jobs/match + builder)
```

Mock auth: `features/auth/data/mock_auth_repository.dart`  
Builder persistence: LocalStore keys `builder_resume_ids` / `builder_resume_<id>`

## Tests

```bash
flutter analyze --no-pub
flutter test --no-pub
cd backend && pytest -q && ruff check app tests
```
## Supabase setup

See [Supabase integration status and configuration](docs/SUPABASE_SETUP.md) for real Auth, secure sessions, PostgreSQL migrations and the remaining dashboard/deployment steps.
