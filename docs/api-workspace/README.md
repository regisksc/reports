# Anonymous illegal-dumping request workspace

Import `myla311-read-only.postman_collection.json` into Postman. Run its five
requests in order: guest bootstrap, request-type discovery, questions/config,
coordinate validation, nearby duplicates. A run contacts the City for reads
only. No credentials, contact details, dispatch request, or upload request are
included. Default coordinates identify public Los Angeles City Hall and do not
represent an actual dumping report.

The collection's scripts use Postman's documented [variable APIs](https://learning.postman.com/docs/tests-and-scripts/write-scripts/postman-sandbox-reference/pm-variables)
and [response APIs](https://learning.postman.com/docs/tests-and-scripts/write-scripts/postman-sandbox-reference/pm-response).
No scripts make secondary network calls,
schedule retries, or select another request. Scripts surface HTTP/Aura/Portal
errors; configure the runner to stop on script errors when inspecting a failed
chain. Start each investigation at bootstrap to replace previous context.

## Transport and chaining

Bootstrap extracts the percent-encoded page's `fwuid` and loaded application ID.
These are framework context values, not a user login. The next four requests
POST URL-encoded Aura actions to `/s/sfsites/aura`, with a monotonically
increasing `r`, the fresh `aura.context`, `aura.pageURI=/s/`, and guest
`aura.token=null`. The collection sets local message/context/counter variables
immediately before each request. Apex class and method are fixed in those
scripts; numeric location input is checked before constructing JSON.

Discovery selects only `Illegal Dumping Item Pickup` and URI-decodes its
`caseConfigId` for `fetchCaseTypeDetails`. The live response's full configuration
and anonymous contact template are retained as collection variables
`caseConfig` and `anonymousContact`. `locationResult` retains the locator's full
address attributes and `locatorStatus` its message. `duplicateEnvelope` retains
the nearby-case envelope. Coordinates may be changed through `latitude` and
`longitude`; location and duplicate requests use the same values.

The distributed export contains only public coordinates as variable values.
A run adds framework context, encrypted type identity, configuration/contact
templates, and locator results to collection variables. Clear generated values
before exporting or sharing a run; the sanitized saved examples are separate.

The endpoint reference, required question answers, exact parameter names, and
source-derived dispatch fields are in [portal-api.md](../portal-api.md).
The Portal performs the duplicate step; the current native client does not
call that step. The collection documents the Portal chain without changing the
native client.

## Examples and provenance

Each collection response has a provenance label. The four Aura examples are
minimized from real read-only HTTP responses captured on **2026-10-22**. They
preserve nested JSON-string response encoding. Unrelated request types,
questions, district metadata, session values, guest identity, and encrypted
configuration IDs are omitted or replaced. The location is public City Hall.
The bootstrap example is **synthetic** percent-encoded HTML; its framework IDs
are replacement values. Saved examples are explanatory and cannot replace
fresh bootstrap/discovery results in a live run.

[attachment-contract.json](attachment-contract.json) identifies each private
source by SHA-256 and records the current advertised configuration plus exact
Portal source excerpts. Original responses, source, and operation logs remain
under ignored `.scratch/illegal-dump-reporter/evidence/ticket12/`; the retained
Portal bundle is under the original workspace's
`.scratch/illegal-dump-reporter/evidence/preflight/`. Original discovery
captures referenced in the older API note were not found at their historical
temporary path. This workspace reuses the retained bundle and preflight reads
and adds fresh read-only evidence rather than claiming the missing captures
were recovered.

[contract-examples.json](contract-examples.json) is **inert JSON**, with no
request URL or Postman request object. It describes dispatch parameters with
decoded nested JSON values and deliberately invalid synthetic photo bytes.
Its three-photo array illustrates the source contract, not a submitted Report.
Its success/rejection/uncertain examples are source-derived or synthetic as
labeled. Do not import it as an executable request or send its values.

## Attachment capability and limits

The current `fetchCaseTypeDetails` response advertises **five optional files**,
and the Portal's `submitRequest` serializes the entire ordered attachment
array as `sFileLinks`. This supports a native limit of three photos under the
advertised contract. It does **not** prove end-to-end acceptance of three photos:
no captured multi-photo write exists and no additional City write is authorized.
The server's aggregate Aura/body-size limit remains unknown.

- Allowed extensions: `.heic;.heif;.jpeg;.jpg;.pdf;.png;.webp`.
- Images: at most **10,000,000 input bytes each**. The Portal redraws images to
  JPEG at quality **0.5**; if input size is greater than **500,000 bytes**, it
  reduces a dimension exceeding **600 px** while preserving aspect ratio.
  HEIC/HEIF has a separate JPEG conversion path.
- At most **one PDF**, at most **3,000,000 input bytes**. PDFs are not an app
  photo requirement and remain outside the current native photo flow.
- Input names longer than **60 characters** are rejected. The ordinary image
  path lowercases the name, truncates its stem to **30 characters**, retains
  the original extension, and applies a final 60-character suffix-preserving
  helper. `fileType` is the lowercase extension; the ordinary image payload
  bytes are JPEG even when the retained extension differs. A native JPEG
  encoder should use matching `.jpg` names/types.
- Each image contains `fileData` (base64 without a `data:` prefix), `fileName`,
  `fileType`, `showImage:true`, and `showPdf:false`. `position` is null without
  EXIF GPS; `dateTime` is absent without EXIF DateTime. Neither is a required
  replacement for the Report's validated location. Array order is preserved
  by the source's `Promise.all` and final `.map`. An empty array means no photo.

These are configuration/source rules. They do not establish a separate upload
endpoint, server-side transcoding, retention policy, or a safe aggregate maximum
for encoded attachments. Native multi-photo implementation must preserve all
selected files and report validation failures, never silently truncate them.

## Results, errors, and existing proof gaps

HTTP 200 alone does not mean an action succeeded. Check Aura `state`, decode
`returnValue.returnValue`, then inspect Portal `isSuccess`, `message`, and
`response`. Some `response` values require another JSON decode. The observed
duplicate result `isSuccess:false`, `response:null`, `message:"No Data Available"`
means no nearby result for that query; it does not prove a particular SR absent.
The non-empty duplicate shape remains unobserved.

The Portal source recognizes dispatch success only with `isSuccess:true` and
`response.sCaseNumber`. Preserve exact SR text. The production client treats
`isSuccess:false` with null response as an explicit rejection, but missing or
malformed receipt data, transport errors, or loss after dispatch leave acceptance
uncertain. Retain the attempt marker and verify the existing request before
another send. Synthetic fixtures demonstrate this interpretation, not City
acceptance. The Aura `ERROR` examples in the offline check are synthetic;
no expired-session/large-body live error was induced.

The historical helper record **C-04955177** remains unchanged. Its original
successful request/response envelope and original native-send provenance were
not recovered. Current authoritative City readback remains blocked as described
in tickets 01/04/09 and the endpoint reference. A local receipt, fresh read-only
configuration, passing offline checks, or this collection resolves none of those
proof gaps. Never execute historical live-send helpers to fill them.

## Offline verification

From the repository root:

```sh
node --test docs/api-workspace/test-workspace.mjs
```

The check executes the actual exported scripts in a local VM against labeled
saved examples. It verifies the full read chain, fixed read-only Apex allowlist,
guest token, ordered counters, variable injection handling, error surfacing, and
inert dispatch examples. It makes **zero network calls**. No production Dart
source or tests are changed by this workspace.
