# Careerly API

The backend parses a PDF or DOCX, stores the structured CV, and scores it with deterministic rules. The Flutter app does not call a model provider and does not hold an API key.

Original files are deleted after extraction. Raw CV text is not stored. `AI_ENABLED=false` by default; scores do not come from a model.

## Quick start

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

SQLite (`sqlite:///./careerly_dev.db`) is created on startup in development, so the API can run without Docker.

PostgreSQL:

```bash
# from the repository root
docker compose up -d
cd backend
# set DATABASE_URL=postgresql+psycopg://careerly:careerly@localhost:5432/careerly
alembic upgrade head
```

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8787
```

Interactive docs: `http://127.0.0.1:8787/docs`

Health: `GET /health` → `{"status":"ok","service":"careerly-api"}`

CV pipeline:

- `POST /api/v1/cvs/parse` multipart field `file` (`.pdf` or `.docx`), optional `career_stage`, `target_fields`
- `PATCH /api/v1/cvs/{cv_id}/parsed`
- `POST /api/v1/cvs/{cv_id}/analyze`
- `GET /api/v1/cvs`, `GET /api/v1/cvs/{cv_id}`, `GET /api/v1/cvs/{cv_id}/analysis`
- `DELETE /api/v1/cvs/{cv_id}`

Development auth accepts `Authorization: Bearer dev:<user>` or `X-User-Id`. Production requires `AUTH_MODE=hmac` and ignores `X-User-Id`.

Billing counters, idempotency records and subscriptions are stored in SQL tables. Existing databases must run `alembic upgrade head` before production startup. Development creates missing tables automatically.

`/cvs/{id}/analyze`, `/reanalyze` and `/rewrite` enforce server plan limits. A successful API operation records its own usage; clients must not record a second usage charge. Each executed operation receives a server-generated billing ID; a repeated client request ID does not authorize additional unpaid work. The explicit `/billing/usage/record` endpoint remains idempotent per user for local-only operations such as Builder document creation.

CV scoring and its usage charge share one transaction; failed scoring rolls both back. Counter increments enforce the cap atomically across workers. Expired subscriptions use Free limits even if their last stored status was active.

The older `POST /api/v1/resumes/analyze` route is still available. New Careerly scores use `/api/v1/cvs`.

## AI providers

| `AI_PROVIDER` | Behavior |
|---------------|----------|
| `mock` (default) | Deterministic structured signals — safe for CI, no paid calls |
| `openai` | OpenAI-compatible chat completions (`OPENAI_API_KEY`, optional `OPENAI_BASE_URL`, `OPENAI_MODEL`) |

The CV pipeline in `app/scoring/` owns Careerly scores (weights 0.20 / 0.20 / 0.15 / 0.15 / 0.10 / 0.10 / 0.10). A model may rewrite wording only when `AI_ENABLED=true`. It never sets `overallScore`.

`POST /api/v1/resumes/analyze` still uses the older weight table in `app/services/scoring_weights.py`.

## Key locations

| Concern | Path |
|---------|------|
| AI system prompt | `app/providers/ai_provider.py` → `AI_SYSTEM_PROMPT` |
| CV scoring weights | `app/scoring/weights.py` |
| CV parser | `app/cv/parser.py` |
| Legacy scoring weights | `app/services/scoring_weights.py` → `SCORE_WEIGHTS` |
| Legacy ATS rules | `app/services/ats_engine.py` |
| AI provider config | `.env` / `app/core/config.py` |
| Job Match AI prompt | `app/services/job_match_ai.py` → `JOB_MATCH_SYSTEM_PROMPT` |
| Job Match weights | `app/services/job_match_weights.py` → `JOB_MATCH_WEIGHTS` |
| Skill aliases | `app/services/skill_aliases.py` |
| Job Match endpoint | `POST /api/v1/jobs/match` |

## Tests

```bash
pytest -q
ruff check app tests
```

## Flutter client

Point the app at this API:

```bash
flutter run -d chrome \
  --dart-define=ENV=dev \
  --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

The API engine is the default. `USE_MOCK_ANALYSIS=true` is fixtures only. `USE_LOCAL_ANALYSIS=true` keeps scoring on the device.

Android emulator localhost: `http://10.0.2.2:8787`  
iOS simulator: `http://127.0.0.1:8787`
