# 09: Verify the existing City request

Status: blocked
Blocked by: none

## Acceptance

- Recover any original request/response from preserved local captures or agent transcripts, distinguishing raw City traffic from summaries.
- Verify C-04955177 through the existing read-only City search/detail APIs and preserve evidence. Never call submitCase, replay an entire captured action batch, or create another request.
- Correct docs/portal-api.md and ticket 04 claims: clearly label captured browser calls, source-derived contracts, helper-send results, native UI proof, and independently verified City records.
- If original native-send provenance is absent, say so. Showing an imported/saved SR is not proof that the native UI originally sent it.
- Keep personal data and session tokens out of tracked documentation and examples.

## Comments

One existing helper send is recorded. The audit found the original search_verification.json failed with Input details are null. City search uses userSearch JSON, not searchKey/filterCriteria. See docs/portal-cancel.md and preserved portal source. No second live send is authorized.

Recovery searched preserved project/browser captures and report-specific agent
transcripts. No raw successful submit response or native-send provenance was
found. Corrected HTTP and official-browser searches did not complete. Detail
lookup requires an encrypted Case ID from the search response; the raw ID
returned an initialization-vector error. Nearby-open-case no-data is not proof
of absence. Private read-only artifacts: `.playwright-mcp/city-receipt-*`.

Documentation and ticket 04 now distinguish source contracts, helper results,
native local display, and authoritative City verification. The remaining
acceptance depends on a working City read-only search or recovered original
transaction evidence. No further City write was performed or authorized.
