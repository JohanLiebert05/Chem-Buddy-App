# Chemistry-only AI and immediate key failover

Deployed on 2 November 2026. Ask ChemBuddy and the spectroscopy orchestrator use
the shared six-key rotation helper. It retains the last successful key and moves
to the next available credential immediately after a rejected or quota-limited
response. There are no retry sleeps or speculative parallel generations. Slow
requests have timeouts; the whole chat attempt has a deadline. Invalid-key
cooldowns are global, while model-specific quota/access failures stay scoped to
that endpoint. Available quota and working credentials are still required.

Clearly unrelated questions are refused by a local server policy before Gemini,
embedding, response-cache lookup, or the daily AI allowance check. Chemistry
follow-ups and chemistry document requests are supported. The model system
instruction also restricts answers to chemistry. Unsupported/unclear questions
ask the user to include chemistry context. This is a bounded local topic policy,
not a semantic guarantee that every possible chemical term is recognized.

Ordinary questions without a document or subject no longer request embeddings.
Account-limit and provider-exhaustion responses contain an explicit
`status: unavailable`, `model: unavailable` and an availability notice in `answer`.
They are HTTP 200 for compatibility with installed clients that only render
`answer`; they are not successful model generations and are never cached as such.
These notices preserve account limits and avoid the old false offline fallback.

The app source renames General AI to Chemistry AI; its saved internal mode ID is
unchanged. This label needs an app update; the server restrictions and failover
already apply to installed apps.

Verification: 22 backend policy/rotation tests and 11 Flutter AI/workspace tests
passed. A live sports question was refused with model `local-policy` in 595 ms
round-trip, with no Gemini call. A live, uncached chemistry question returned
HTTP 200 and a Gemini 3.6 Flash answer. Reports are in
`docs/reports/chemistry-policy-live-2026-11-02.json`.
## Protected key diagnostics

`gemini-key-health` remains project-service-authorized. Its default POST checks
all six slots. An administrator can send `{"key_names":["GEMINI_KEY_1",
"GEMINI_KEY_3","GEMINI_KEY_4"]}` to inspect only failed slots and avoid consuming
the working keys' quota. Unsupported secret names are rejected before calling
Google. Error diagnostics return only allowlisted reason codes, daily/minute
quota classifications, zero-quota flags and a bounded numeric retry delay.
Provider messages, credential values and project metadata are never returned.
