# Careerly — Release Checklist (RC1)

Use this before any store submission. Tick only what is **verified**.

## Classification gates

| Gate | Status key |
|------|------------|
| NOT READY | P0 open or tests failing |
| READY FOR INTERNAL TESTING | Repo P0/P1 fixed; EXTERNAL items documented |
| READY FOR STORE SUBMISSION | All EXTERNAL ACTIONS complete + signed binaries |

## Config (must be true for production binaries)

- [ ] `ENV=production`
- [ ] `USE_MOCK_ANALYSIS` not `true` (forced false in production bootstrap)
- [ ] `API_BASE_URL` is https non-localhost
- [ ] Backend `APP_ENV=production` starts without error
- [ ] Backend `AI_PROVIDER=openai` + live key (not mock)
- [ ] Backend `AUTH_MODE=hmac` + `AUTH_TOKEN_SECRET` set (not in git)
- [ ] Backend `CORS_ORIGINS` explicit allowlist (not `*`)
- [ ] Backend `SUBSCRIPTION_VERIFIER=production` with store credentials

## Client security

- [ ] Mock auth disabled (production uses ProductionAuthRepository fail-closed until IdP wired)
- [ ] Mock / force-Pro billing disabled in release+production
- [ ] Android `INTERNET` in main manifest
- [ ] Android release signing via `android/key.properties` when `-PstoreRelease=true`
- [ ] iOS signing / capabilities configured in Xcode (EXTERNAL)
- [ ] Privacy Policy + Terms URLs real (not placeholders) (EXTERNAL)

## Quality

- [ ] `flutter analyze` clean (or info-only)
- [ ] `flutter test` green
- [ ] `cd backend && pytest` green
- [ ] Manual smoke (`docs/MANUAL_SMOKE_TEST.md`) completed
- [ ] Secret scan clean (`scripts/secret_scan.sh`)

## Do not ship if

- Fixture analysis scores reachable in production path
- Client can force Pro without store verification
- Backend accepts arbitrary `X-User-Id` in production
- Debug signing used for Play/App Store upload
