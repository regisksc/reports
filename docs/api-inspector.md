# Reports Dev / API mode

## Scope and behavior

Dev / API mode is a request playground for the Reports app's illegal-dumping MyLA311 flow. It exposes only named operations whose endpoint and request contract are documented in the repository. The MyLA311 host and Aura route are fixed. There are no arbitrary method, URL, header, or body controls, no Photon sample, and no generic custom request mode. Selecting an operation or opening the sheet never sends a request; reads run only from **Run 311 request**.

The operation list mirrors the current `PortalSubmissionClient` flow:

1. `GET https://myla311.lacity.gov/s/` — bootstrap the guest Aura context. The HTML response is summarized; live `fwuid` and application ID values stay in memory and are not displayed or persisted.
2. `POST /s/sfsites/aura` — `X11_H_ParentController.fetchInitialDetails`, selecting the live `Illegal Dumping Item Pickup` configuration ID.
3. `POST /s/sfsites/aura` — `X11_RI_ParentController.fetchCaseTypeDetails`, loading the current question and anonymous-contact configuration.
4. `POST /s/sfsites/aura` — `LA_AddressController.validateAddress`, using the Report's coordinates.
5. `POST /s/sfsites/aura` — `X11_RI_ParentController.submitCase`, available only after a separate exact-payload review and explicit confirmation.

The verified `X11_RI_ParentController.getRelatedCaseLst` read is available as an optional Portal operation. It uses the locator result's `X`/`Y`; the Flutter `PortalSubmissionClient` does not currently call it. The prototype does not expose `validateOriginalAddress`, because the current client uses coordinate validation. Unknown Apex actions and unknown upload routes are not exposed. Portal photos are carried inline in `submitCase`; there is no separate upload endpoint.

## Request construction and payload boundaries

The Aura form is built from the observed client contract: the exact Apex class/method, request params, cacheability, encoded page URI, monotonically increasing `r`, `aura.context`, and guest `aura.token=null`. Read operations send only to `https://myla311.lacity.gov/s/sfsites/aura`. Browser-managed User-Agent values are not overridden. The prototype fills the Portal's free-text browser/platform/device metadata from the current browser runtime and identifies itself as Reports Dev/API mode; this differs from the Flutter client's native-iOS metadata and has not been validated against a live submit. Requests omit cookies and credentials, matching the documented guest read behavior. The live session context is memory-only.

Locator inputs are seeded from the Report's coordinates and can be edited inside the inspector. The submit preview is seeded from the same Report: description, debris placement/count, and one optional in-memory attachment. The current client contract maps anonymous `I'm not sure` → `Loose/Miscellaneous Debris`; it does not implement the prototype's other material/item combinations or non-anonymous contact flow. Unsupported categories, multiple items, multiple attachments, missing required fields, and missing session dependencies stop before dispatch instead of being coerced into a different City report. Inspector edits do not mutate the underlying Report draft.

`submitCase` is a real write path based on the existing Flutter client and the source-derived Portal contract. Pressing **Review submitCase payload** sends nothing. The review shows the fixed Aura destination including its next execution counter, POST method, form content type, issue page URI, and the exact action params. A second checkbox confirmation dispatches that exact plan. If a prior attempt is uncertain, a separate confirmation requires the operator to check MyLA311 or call 3-1-1 before retrying. A confirmed Service Request number locks out duplicate submission in the current inspector session. The prototype never mutates saved Reports or creates a local receipt.

## Response, cancellation, and privacy

The active operation displays loading, then its actual HTTP status and parsed server payload, or an honest readable non-JSON/error body. Bootstrap returns HTML, so the UI shows a response summary derived from that received HTML. Aura state errors, Portal `isSuccess:false`, expected `No Data Available`, HTTP 401/403, other HTTP errors, malformed JSON, and no-response network/CORS failures are distinct. A browser fetch failure cannot distinguish all network, CORS, and authentication causes. HTTP 200 alone is not treated as report acceptance.

Editing an operation input or the Report draft clears the prior result as stale. Only one request runs at a time; cancellation aborts locally and explicitly warns that the server may already have received a write. A 60-second timeout reports no response, not a fabricated status. No automatic retry runs. The latest 12 history records retain operation label, fixed method/path, outcome, status, and elapsed time in memory; they contain no request/response bodies or session values. Session values, files, and request history are not written to storage or logs.

## Source, export, and verification

- Canonical Open Design project: `Reports Motion Design Brief`, ID `74204d10-326c-44f9-b11a-7d9401baa491`.
- Canonical entry: `reports-prototype-buttons-v2.html`; standalone runtime: `reports-api-inspector.js`, embedded byte-for-byte as `reports-api-inspector-runtime`.
- Contract source: repo `reports/lib/features/report/data/portal_submission_client.dart`, `docs/portal-api.md`, and `docs/api-workspace/README.md`.
- Focused tests use controlled transports and explicitly synthetic fixture responses; they make no City requests and do not expose a mock mode in the product UI.
- The prior `file://` preview was rejected by browser URL policy before navigation or request dispatch. No supported HTTPS preview URL was found in the existing Open Design project/deployment metadata. The safe live UI request smoke therefore remains unverified; no server, alternate URL, or CORS/security bypass was attempted.
- No City write, submission, or attachment upload was executed for this change. The original successful `submitCase` envelope and native-send provenance remain unverified as documented in `docs/portal-api.md`.
