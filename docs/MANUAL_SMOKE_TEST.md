# Careerly — Manual Smoke Test (RC1)

Record **PASS / FAIL / EXTERNAL** for each row. Do not mark PASS if you bypassed auth, billing, or backend.

## Environment under test

| Field | Value |
|-------|-------|
| Build | e.g. `flutter run --release` / internal APK |
| ENV | |
| USE_MOCK_ANALYSIS | |
| API_BASE_URL | |
| Tester | |
| Date | |

## Cases

| # | Case | Result | Notes |
|---|------|--------|-------|
| 1 | Cold start → language → onboarding → auth → personalization → home | | |
| 2 | Production/staging: mock auth blocked or IdP works | | EXTERNAL if IdP not configured |
| 3 | Analyze CV (PDF) returns scores from engine (not fixture 78) when mock=false | | |
| 4 | Job Match paste JD → score + skill Yes/Some/No language integrity | | |
| 5 | Builder create CV → edit → autosave → preview A4 | | |
| 6 | Export PDF EN + TR; open in reader; text selectable | | |
| 7 | Template switch Classic/Modern/Student/Tech keeps content | | |
| 8 | AI rewrite shows Original/Suggested/Why; does not auto-apply; asks for missing metrics | | |
| 9 | Translate creates new version; proper nouns preserved | | may be Pro-gated |
| 10 | Check CV from Builder without re-upload | | |
| 11 | Free limit → paywall; no force-Pro in release | | |
| 12 | Restore purchases (store) or EXTERNAL stub message | | EXTERNAL |
| 13 | Network offline → clear error (no silent success) | | |
| 14 | 429 → rate limit message | | |
| 15 | Delete account data wipes local CV/analysis/matches | | |
| 16 | Sign out → cannot access prior session data without sign-in | | |
| 17 | a11y: TalkBack/VoiceOver on score + save status | | |
| 18 | EN/TR UI strings render (no raw keys) | | |

## READY TO TEST — local / device QA

### Local (mock OK for UI)

```bash
flutter pub get
flutter run -d chrome --web-port=43123 \
  --dart-define=ENV=dev --dart-define=USE_MOCK_ANALYSIS=true
```

### Local API (internal testing)

```bash
cd backend && source .venv/bin/activate
# APP_ENV=dev AUTH_MODE=dev in .env
uvicorn app.main:app --host 0.0.0.0 --port 8787

flutter run -d chrome --web-port=43123 \
  --dart-define=ENV=dev \
  --dart-define=USE_MOCK_ANALYSIS=false \
  --dart-define=API_BASE_URL=http://127.0.0.1:8787
```

### Production-shaped (expect fail-closed until EXTERNAL complete)

```bash
flutter run --dart-define=ENV=production \
  --dart-define=USE_MOCK_ANALYSIS=false \
  --dart-define=API_BASE_URL=https://api.careerly.ai
# Auth should refuse mock sign-in until IdP is wired.
```

### Android release compile (stop at signing)

```bash
flutter build appbundle --release
# Store upload requires: android/key.properties + -PstoreRelease=true
```

### iOS release compile (stop at signing)

```bash
flutter build ios --release --no-codesign
# Codesign / Archive in Xcode with team credentials (EXTERNAL).
```
