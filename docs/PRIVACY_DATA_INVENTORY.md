# Careerly — Privacy / Data Inventory (RC1)

## Data categories

| Data | Where stored | Retention | Notes |
|------|--------------|-----------|-------|
| Locale, onboarding flags | Device SharedPreferences | Until reset/delete | Local only |
| Mock email / display name | Device SharedPreferences | Until sign-out/delete | Not a production IdP account |
| Access token (dev) | Device SharedPreferences | Until sign-out/delete | `dev:<email>` for local API; production tokens still require secure storage |
| Personalization (stage, goal, fields, CV language) | Device SharedPreferences | Until delete | |
| Last analysis JSON | Device SharedPreferences | Until clear/delete | Scores + findings |
| Saved job matches | Device SharedPreferences | Until clear/delete | |
| Builder ResumeDocuments | Device SharedPreferences | Until delete | Structured CV content |
| Billing entitlement cache / usage (mock) | Device SharedPreferences | Until delete | |
| Uploaded CV bytes | Backend memory and temporary extraction file | Temporary file removed after extraction | Original upload is not retained |
| Structured CV, contact details, section text and analysis findings | Backend SQL database | Until explicit CV deletion | Full extracted raw-text field is omitted; sections still contain personal data |
| CV versions and application tracker | Device SharedPreferences | Until sign-out/reset/delete | Device-local; no cross-device sync |
| AI prompts / CV text | Sent to provider on enabled AI paths | Provider policy | New CV paths require `AI_ENABLED=true`; legacy routes use `AI_PROVIDER` separately |
| Subscription receipts | Sent to verify endpoint | Not stored by current verifier | Real store verification remains unconfigured |
| Subscription state and usage/idempotency records | Backend SQL database | No automatic retention policy yet | Persistent across server restarts; device deletion does not remove these records |

## Processing purposes

- CV readiness scoring and ATS checks
- Job Match alignment (pasted JD only — no scraping)
- CV Builder editing, PDF export, rewrite/translate assists
- Entitlement / usage metering

## User controls (implemented locally)

- Sign out
- Reset demo onboarding
- **Delete account data** — wipes all Careerly keys on device and clears active feature state; does not delete backend data
- Backend `DELETE /api/v1/cvs/{cv_id}` removes an owned CV and its associated analysis records; this is not yet connected to the local account deletion button

## Not implemented (EXTERNAL / future)

- Hosted account deletion across devices
- Privacy Policy / Terms URLs (placeholders only)
- Regional data residency guarantees
- Full GDPR export package

## Logging

Backend applies PII redaction filters (email, phone, bearer tokens, key-like assignments). Still: never log raw CV text.
