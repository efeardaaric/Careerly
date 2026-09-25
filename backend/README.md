# Careerly Analysis API (Phase 3)

Temporary CV analysis pipeline for the Flutter app. Documents are processed in memory and **not** stored permanently. AI provider keys stay on the server.

## Quick start

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8787
```

Health: `GET http://127.0.0.1:8787/health` → `{"status":"ok"}`  
Analyze: `POST http://127.0.0.1:8787/api/v1/resumes/analyze` (multipart `file`, optional `locale`, `career_stage`, `target_role`)  
Job Match: `POST http://127.0.0.1:8787/api/v1/jobs/match` (JSON resume snapshot + job title/description)
Entitlements: `GET /api/v1/billing/entitlements` · Usage: `GET/POST /api/v1/billing/usage*` · Verify: `POST /api/v1/billing/subscriptions/verify`

## AI providers

| `AI_PROVIDER` | Behavior |
|---------------|----------|
| `mock` (default) | Deterministic structured signals — safe for CI, no paid calls |
| `openai` | OpenAI-compatible chat completions (`OPENAI_API_KEY`, optional `OPENAI_BASE_URL`, `OPENAI_MODEL`) |

The LLM must **not** return the final overall score. `scoring_engine` + `SCORE_WEIGHTS` own scores.

## Key locations

| Concern | Path |
|---------|------|
| AI system prompt | `app/providers/ai_provider.py` → `AI_SYSTEM_PROMPT` |
| Scoring weights | `app/services/scoring_weights.py` → `SCORE_WEIGHTS` |
| ATS rules | `app/services/ats_engine.py` |
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
  --dart-define=USE_MOCK_ANALYSIS=false \
  --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

Android emulator localhost: `http://10.0.2.2:8787`  
iOS simulator: `http://127.0.0.1:8787`
