# Review fixes — deployment

Code now contains account separation, server-only AI keys, durable sync, guarded roles/ingestion, contextual AI, shared-cache retirement, OD/chart and route corrections, actual PDF diagrams, descriptor limits/labels, IST scheduling, fact cycling and production-signing configuration.

## Required live steps
1. Rotate any previously valid embedded Gemini keys from both the client and legacy Edge Functions in the provider console. Removing source does not revoke keys in existing APKs/Git history.
2. Back up Supabase. Apply all previous migrations followed by supabase/migrations/20261025_review_hardening.sql. Academic rows are preserved; client access to the old shared cache is revoked.
3. Review existing admin accounts; the role guard cannot identify past unauthorized promotions.
4. Deploy the updated Edge Functions, including ingest-document and ask-gemini-orchestrator with the shared access helper. All seven legacy provider pools now use server environment secrets only. Ensure SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY and provider secrets are configured. The fallback orchestrator fails closed without the atomic budget function. Its non-admin limit is 50 requests/day; main-tutor limits remain separate.
5. Configure GitHub secrets ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD. Preserve the appropriate signing identity and check existing-installation upgrade compatibility.
6. Version 3.5.4 is validated by GitHub Actions before publishing. Without production signing secrets, the workflow publishes the separately installed ChemBuddy Preview test APK.

Publishing source and the APK does not rotate secrets, apply migrations, deploy functions or configure production signing.

## Phone acceptance checks
Account A/B switching and legacy migration; offline/reconnect and rejected writes; fresh-device expectations; PDF/history/mode separation; OD charts; calculator links; diagrams and pagination; reboot/background actions; diverse chemical inputs; small screens and large fonts.

Local encryption, full restore and a full RDKit integration remain outside the implemented fixes; their limitations are documented honestly.
