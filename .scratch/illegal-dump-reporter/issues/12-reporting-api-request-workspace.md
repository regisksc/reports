# 12: Inspect the reporting API in a reusable request workspace

**What to build:** A developer can follow the anonymous reporting request/response chain in a Postman-style workspace and distinguish observed behavior from synthetic examples or missing evidence. Trace: Q6 and the API-investigation intention.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Reuse the existing endpoint reference, captures, and fixtures before creating exports.
- [x] Document session setup, location/questions, duplicate checks, attachment constraints, and result/error interpretation with per-example provenance.
- [x] Establish the supported attachment contract or explicitly document the unsupported/unverified boundary. Do not infer three-photo support from a UI.
- [x] Sanitize shareable examples and exclude dispatch requests from unattended runs. Controlled read-only inspection may establish missing evidence, but no City write is authorized to complete this investigation.
- [x] Keep missing original transaction/native provenance explicit. Existing native-send proof gaps in tickets 01, 04, and 09 remain unresolved, without becoming blanket blockers for unrelated improvements.
- [x] Preserve anonymous illegal-dumping scope (Q18), native submission through the real client, confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Do not introduce another issue type or contact/login flow.
- [x] Create no City write or second Service Request; never execute historical live-send helpers. Label controlled fixtures explicitly synthetic and never present them as proof of a live Submission.
- [x] Introduce no automatic/background send queue, automatic retry, haptics, or persistent manual motion preference. Honor system/session reduced motion wherever motion changes.
- [x] For any implementation behavior needed later, begin with one meaningful failing behavior test, make the minimal change, run relevant formatter/lint/analysis/test/build checks, and finish one scoped Conventional Commit per completed behavior. Preserve 100% production line coverage with no exclusions; verify the workspace without dispatching City writes.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim a fast tier was applied without evidence.

## Comments

### 2026-10-22: request workspace candidate

- Reused `docs/portal-api.md`, retained preflight response envelopes and the
  preserved Portal bundle. The older temporary capture directory is absent;
  no original successful transaction was recovered. Tickets 01–10 are untouched.
- Fresh read-only HTTP 200: guest bootstrap, `fetchInitialDetails`,
  `fetchCaseTypeDetails`, `validateAddress` at public City Hall, and
  `getRelatedCaseLst`. No dispatch/helper execution or new Service Request.
- Current configuration advertises five optional attachments. Portal source
  serializes the whole ordered array, with exact base64, filename, per-file
  limits, and encoding documented in `docs/api-workspace/attachment-contract.json`.
  Three photos fit this advertised/source-supported contract; end-to-end
  multi-photo acceptance and aggregate Aura size remain unverified.
- Added a five-read Postman collection, minimized observed response examples,
  explicitly synthetic bootstrap fixture, inert source-derived dispatch/result
  samples, and a workspace guide. Dispatch is absent from the runnable export.
- Test-first workspace verification: initial offline behavior check failed
  because the export did not exist; after implementation all four tests pass.
  Actual exported scripts also processed the full original bootstrap and four
  fresh raw response files offline. No network calls occur in these tests.
- `git diff --check` passed. JavaScript parses and JSON round-trips in the
  offline checks. Official JSON Schema downloads returned HTTP 403 on both
  legacy and current hosts; no full-schema-validation claim is made. No Dart,
  native source, app behavior, or production coverage changes require new app
  analysis/build/coverage runs for this documentation/workspace slice.
- Private evidence: `.scratch/illegal-dump-reporter/evidence/ticket12/`, including
  current raw reads, hashes, operation logs, offline check output, and schema
  download diagnostics. Shareable provenance excludes session/guest data.
- Implementation was delegated with ticket12-only ownership. Requested model
  policy is GPT-6.1 Sol/high; service-tier control is not exposed, so fast tier
  is unverified. Root owns serialized Git and the configured candidate review;
  review and scoped commit are pending at this candidate handoff.

2026-10-22, integration: parent inspected the workspace, executable scripts,
attachment provenance and operation logs, then freshly ran
`rtk proxy node --test docs/api-workspace/test-workspace.mjs`: four passed,
zero failed. Configured strict review approved worker commit `7088ace`,
integrated as `2c6dceb`. Private evidence is copied to `../evidence/ticket12/`.
This resolves the documented read workspace and advertised attachment contract;
it does not establish multi-photo acceptance or repair historical native proof.
