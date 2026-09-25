# Careerly — EXTERNAL ACTION REQUIRED (RC1)

These items **cannot** be completed honestly inside this repository without real credentials, legal copy, or vendor accounts. Do not invent secrets or Privacy/Terms URLs.

## 1. Identity provider (production auth)

**Why:** Production builds fail closed on mock email/password auth.  
**Steps:**

1. Choose IdP (Firebase Auth, Auth0, Cognito, or native Apple/Google).
2. Configure iOS/Android OAuth clients.
3. Issue short-lived access tokens; backend `AUTH_MODE=hmac` (or replace with JWT JWKS verify).
4. Set `AUTH_TOKEN_SECRET` (or JWKS URL) in secret manager — **never commit**.
5. Wire `ProductionAuthRepository` to the SDK.

**Owner:** Mobile + backend eng  
**Blocks:** READY FOR STORE SUBMISSION

## 2. Android Play signing

**Why:** Store uploads must not use debug keys.  
**Steps:**

1. Create upload keystore offline.
2. Add `android/key.properties` (gitignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
3. Build: `flutter build appbundle --release -PstoreRelease=true`
4. Enroll Play App Signing in Play Console.

**Blocks:** Play submission

## 3. Apple signing / App Store Connect

**Why:** `flutter build ios --release --no-codesign` only validates compile.  
**Steps:**

1. Apple Developer team + App ID + provisioning profiles.
2. Archive/sign in Xcode.
3. Upload via Transporter / Xcode.

**Blocks:** iOS submission

## 4. Store subscription verification

**Why:** `SUBSCRIPTION_VERIFIER=production` is a stub until Apple/Google credentials exist.  
**Steps:**

1. Create products `careerly_pro_monthly` / `careerly_pro_yearly` in stores.
2. Configure server receipt validation (App Store Server API / Google Play Developer API).
3. Persist entitlements durably (DB) — current mock is in-memory.
4. Set verifier credentials via env/secret manager.

**Blocks:** Paid Pro in production

## 5. Privacy Policy + Terms of Use URLs

**Why:** Paywall/legal copy is placeholder; stores require real policies.  
**Steps:**

1. Legal draft policies covering CV uploads, AI processing, retention, deletion.
2. Host on https URLs.
3. Replace placeholder strings in app + store listings.

**Do not** invent URLs in code.

**Blocks:** Store submission

## 6. Production API host + CORS

**Why:** Production rejects localhost and `CORS_ORIGINS=*`.  
**Steps:**

1. Deploy FastAPI behind TLS.
2. Set `CORS_ORIGINS` to exact app origins.
3. Point app `API_BASE_URL` to that host.

## 7. AI provider production key

**Why:** Production forbids `AI_PROVIDER=mock` (fixture signals).  
**Steps:**

1. Provision OpenAI-compatible key.
2. Set `OPENAI_API_KEY` in secret manager.
3. Confirm anti-fabrication prompts + scoring engine still own final scores.

## 8. PDF Turkish fonts offline (optional hardening)

**Why:** Noto download may fail offline → Helvetica lacks TR glyphs.  
**Steps:** Bundle licensed fonts under `assets/fonts/` and load in `CvFontBundle`.

## Rotation

If a real secret is ever found in git history: **ROTATION REQUIRED** — revoke at provider, scrub history, do not print the secret in reports.
