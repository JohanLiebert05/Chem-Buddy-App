# Gemini credential health check

Maintenance endpoint for the project owner. It sends one tiny generation request
per configured `GEMINI_KEY_1` through `GEMINI_KEY_4` / `GEMINI_API_KEY` and returns only names, HTTP status
and sanitized outcome categories. It never returns credential values or raw
provider error messages. Credentials go to Google in headers, never query URLs.

Deploy with gateway `verify_jwt: false`: the handler itself requires an exact
project server secret from `SUPABASE_SECRET_KEYS` or the legacy service-role key.
Ordinary user JWTs, publishable keys and unauthenticated calls are rejected before
any provider request. This supports the dashboard's **Add secret key** control;
it does not grant students access to this maintenance endpoint. Do not embed a
project server secret in the app or a test report.

In Supabase → Edge Functions → gemini-key-health → Test, use POST with `{}`,
choose **Add header options → Add secret key**, then Send Request. Clear the
request authorization field after checking. The app's student AI allowance is
separate and is not changed by this check.

On 1 November 2026 both credentials returned `generation_ok` / HTTP 200 using
`gemini-3.6-flash`. The new supplied credential was saved as `GEMINI_KEY_1`;
the previous `GEMINI_API_KEY` remains available. The deployed spectroscopy
orchestrator already reads both names. This tests connectivity, not NMR accuracy.

A later five-credential check on the same date returned HTTP 200 for
`GEMINI_KEY_1`, `GEMINI_KEY_4` and `GEMINI_API_KEY`. Google rejected
`GEMINI_KEY_2` and `GEMINI_KEY_3` with HTTP 401 / `UNAUTHENTICATED`; they are
stored but unusable until replaced. One live Ask ChemBuddy question through its
existing guest API returned HTTP 200 and a chemistry answer from
`gemini-3.6-flash`. The deployed Ask ChemBuddy reader recognizes all these secret
names and skips failed credentials during failover. This check does not change
the earlier partial 40-case spectroscopy report or the student's allowance.

Local authorization/redaction tests:
`node --experimental-strip-types --test tool/gemini_key_health.test.mjs`.
