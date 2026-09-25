# Careerly AI

Calm, bilingual (EN/TR) career companion for CV readiness, ATS clarity, job matching, and structured CV building.

**Working product name** — brand tokens and naming are replaceable without touching feature logic.

## Phase status

- **Phase 1:** Splash → language → onboarding → mock auth → personalization → home shell.
- **Phase 2:** CV upload UI, mock analysis pipeline, section review, readiness results.
- **Phase 3:** FastAPI analysis engine + `ApiResumeAnalysisRepository` (mock still default).
- **Phase 4:** Job Match engine — paste JD, alignment score, skill evidence, Optimize CV suggestions.
- **Phase 5:** Professional CV Builder — `ResumeDocument` → section editors → ATS templates → searchable PDF; AI rewrite/translate; structured Check CV.
- **Phase 6:** Monetization — entitlements, Free/Pro limits, paywall, usage metering, mock purchases.
- **Phase 8.1:** RC1 blocker fixes — production fail-closed config/auth/billing, backend Bearer auth + IDOR, release docs. **READY FOR INTERNAL TESTING** (not store submission).
- **UI/UX polish:** Visual-only pass — design tokens, shared processing view, reduced card density, signature-screen hierarchy (see polish report in agent docs store).

Not included: OCR, cover letters, interview AI, scraping, credits marketplace, application tracker, store publishing.

## Stack

- Flutter / Dart — Riverpod, GoRouter, Dio, file_picker, pdf/printing, gen-l10n EN/TR
- Backend — FastAPI under `backend/` (PDF/DOCX parse, ATS, AI provider, scoring, Job Match, Builder rewrite/translate/check)

## Run Flutter

```bash
flutter pub get
# Mock analysis + Job Match + Builder AI (default)
flutter run -d chrome --web-port=43123 --dart-define=ENV=dev --dart-define=USE_MOCK_ANALYSIS=true

# Real API
flutter run -d chrome --web-port=43123 \
  --dart-define=ENV=dev \
  --dart-define=USE_MOCK_ANALYSIS=false \
  --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

| Define | Purpose |
|--------|---------|
| `ENV` | `dev` / `staging` / `production` |
| `API_BASE_URL` | Backend origin (dev default `http://127.0.0.1:8787`) |
| `USE_MOCK_ANALYSIS` | `true` (default) or `false` for API (analysis + Job Match + Builder AI) |

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
flutter test test/builder/
cd backend && pytest tests/test_builder.py -q
```
