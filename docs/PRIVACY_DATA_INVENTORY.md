# Careerly — Privacy / Data Inventory (RC1)

## Data categories

| Data | Where stored | Retention | Notes |
|------|--------------|-----------|-------|
| Locale, onboarding flags | Device SharedPreferences | Until reset/delete | Local only |
| Mock email / display name | Device SharedPreferences | Until sign-out/delete | Not a production IdP account |
| Access token (dev) | Device SharedPreferences | Session | `dev:<email>` for local API |
| Personalization (stage, goal, fields, CV language) | Device SharedPreferences | Until delete | |
| Last analysis JSON | Device SharedPreferences | Until clear/delete | Scores + findings |
| Saved job matches | Device SharedPreferences | Until clear/delete | |
| Builder ResumeDocuments | Device SharedPreferences | Until delete | Structured CV content |
| Billing entitlement cache / usage (mock) | Device SharedPreferences | Until delete | |
| Uploaded CV bytes | Backend memory only during request | Not persisted | Discarded after analyze |
| AI prompts / CV text | Sent to AI provider when `AI_PROVIDER=openai` | Provider policy | EXTERNAL: DPA with provider |
| Subscription receipts | Sent to verify endpoint | Server in-memory mock store | Production needs durable store (EXTERNAL) |

## Processing purposes

- CV readiness scoring and ATS checks
- Job Match alignment (pasted JD only — no scraping)
- CV Builder editing, PDF export, rewrite/translate assists
- Entitlement / usage metering

## User controls (implemented locally)

- Sign out
- Reset demo onboarding
- **Delete account data** — wipes all Careerly keys on device

## Not implemented (EXTERNAL / future)

- Hosted account deletion across devices
- Privacy Policy / Terms URLs (placeholders only)
- Regional data residency guarantees
- Full GDPR export package

## Logging

Backend applies PII redaction filters (email, phone, bearer tokens, key-like assignments). Still: never log raw CV text.
