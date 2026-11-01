# Gemini credential health check

Maintenance endpoint for the project owner. It sends one tiny generation request
per configured `GEMINI_KEY_1` through `GEMINI_KEY_6` and returns only names, HTTP status
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

## Six-key numbering

The owner subsequently supplied a complete five-key set. Those values are saved
as `GEMINI_KEY_1` through `GEMINI_KEY_5` in supplied order, with the earlier
user-supplied key retained as `GEMINI_KEY_6`. Provider values are not recorded here.
Both deployed `ask-chembuddy` and `ask-gemini-orchestrator` now read numbered
slots 1–6; legacy aliases remain supported and duplicate values are deduplicated.
The existing `GEMINI_API_KEY` matches numbered slot 5, rather than adding a seventh
credential. The diagnostic checks each of the six numbered slots independently.
The earlier five-key reports describe the previous numbering only.

The first check after renumbering returned HTTP 200 for keys 2 and 6, HTTP 429
for keys 1 and 5, and HTTP 401 for keys 3 and 4. These are provider responses at
that time, not guarantees about future quota availability. An uncached Ask
ChemBuddy question about ethyl acetate NMR returned HTTP 200 using
`gemini-3.6-flash` after the six-slot deployment. The status and sample-answer
reports are in `docs/reports/gemini-six-key-status-2026-11-01.json` and
`docs/reports/ask-chembuddy-six-key-check-2026-11-01.json`.
