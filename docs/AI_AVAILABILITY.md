# AI availability diagnosis — 2 November 2026

The General AI question shown in the phone screenshot was reproduced through
the deployed Ask ChemBuddy API. Before the repair it returned HTTP 502 with
"All Gemini credentials are cooling down after provider errors."

Two separate bugs were identified:

- The client falls back to its local study library after cloud errors, including
  quota and authentication failures. Its generic local response incorrectly
  asserted "Zero Internet Detected" without a connectivity measurement. The
  response now says "Online AI answer unavailable" and explains possible causes.
  This client text change requires a subsequent application build.
- The deployed key rotation cooled down a credential globally after a model's
  403, 404 or 429 response. An unavailable embedding/model endpoint could disable
  otherwise usable chat fallbacks. The shared cooldown helper now scopes those
  failures to the model endpoint. Only HTTP 401 blocks the credential across
  models. Existing authentication and account allowances were preserved.

The server repair was deployed to Ask ChemBuddy and the spectroscopy
orchestrator. Retesting the exact question then reached the provider and returned
a Google `429 RESOURCE_EXHAUSTED` quota error, rather than the old all-models
cooldown failure. This confirms a remaining provider quota limitation; it does
not establish that the phone has no internet. Reinstalling cannot restore
provider quota or repair rejected Google credentials.

Verification: six Flutter mode/fallback tests and fourteen focused backend
credential/cooldown tests passed. Tests cover a failed embedding endpoint followed
by an available chat endpoint, invalid-credential cooldown across models, quota
cooldown expiry, and absence of a false zero-internet claim after a cloud failure.
