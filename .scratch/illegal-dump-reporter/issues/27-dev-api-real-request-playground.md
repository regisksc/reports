# 27: Run real 311 operations in Dev Mode

**What to build:** make Reports Dev / API mode a domain-specific MyLA311 request playground. It should run the actual illegal-dumping operations used by Reports and display real responses. Do not expose an arbitrary API client. Update the saved Open Design artifact first, then refresh its existing prototype folder. This is the follow-on assigned after tickets 11–26; keep their existing delivery ownership unchanged.

**Blocked by:** None. Reuse ticket 12's request workspace and attachment evidence. Do not repeat that investigation.

**Status:** ready-for-human

**Owner:** dedicated follow-on task `01a16306-ad66-7348-87e2-2c2eff6570f3`.

## Acceptance

- [x] Inspect and update the existing Dev / API sheet in canonical Open Design. Keep the current Reports screen and ordinary Report draft intact.
- [x] Expose only named operations grounded in `PortalSubmissionClient` and the verified `docs/portal-api.md` contract: guest bootstrap, `fetchInitialDetails`, `fetchCaseTypeDetails`, `validateAddress`, `submitCase`, and the documented optional `getRelatedCaseLst` read (labeled as not used by the current Flutter client). Do not expose arbitrary method, host, URL, headers, raw body, Photon sample, or unknown Apex action.
- [x] Build each Aura request with its documented fixed MyLA311 host/route, action descriptor, form params, page URI, cacheability, ordered counter, guest token, and live in-memory Aura context. Prepared Report coordinates and data feed the relevant calls; inspector edits do not mutate the Report.
- [x] Show actual loading, HTTP/Aura/Portal/network/CORS/auth/timeout/cancel results and received JSON/text. Clear stale responses on edits and ignore older completions. No fabricated success, response, or Service Request number.
- [x] Provide the current client's real `submitCase` path. Show its exact City destination, method, page URI, and generated action params for review, then require an explicit second confirmation. Guard report data that the current client does not map instead of silently converting it. No City write or upload was executed to test this feature.
- [x] Keep Aura session values and response/request history in memory only. Do not persist sessions, photos, payloads, or response bodies. Retain only a bounded request metadata history. Cancellation does not claim to undo server-side effects; uncertain writes require checking MyLA311/3-1-1 before retry.
- [x] Add focused controlled-transport and layout tests. No test performs network access or a City submission.
- [x] Update canonical Open Design source first, then refresh the same files in the existing `design-prototype/` folder. The entry embeds the standalone runtime byte-for-byte; source/export hashes match for entry, runtime, tests, spec, sidecar, and handoff.
- [x] Update canonical `api-inspector.md` and repository `docs/api-inspector.md` with operation scope, payload/session behavior, confirmations, privacy, test evidence, and remaining gaps.
- [ ] Run one safe read-only request from the actual approved preview runtime and record its real result or honest error. The earlier `file://` route was denied before page load; no supported HTTPS preview URL was found in existing Open Design project/deployment metadata. Do not bypass the URL policy or create a local server.
- [ ] Reopen the refreshed prototype in a supported preview and visually verify parity. The prior Open Design accessibility calls timed out (`-10005`); do not retry those calls without a supported route.

## Verified MyLA311 contract

The current `reports/lib/src/portal_submission_client.dart` call order is:

1. `GET https://myla311.lacity.gov/s/` — read the guest Aura context.
2. `POST https://myla311.lacity.gov/s/sfsites/aura` — `X11_H_ParentController.fetchInitialDetails`.
3. Same Aura route — `X11_RI_ParentController.fetchCaseTypeDetails` for the returned Illegal Dumping Item Pickup id.
4. Same Aura route — `LA_AddressController.validateAddress` from Report coordinates.
5. Same Aura route — `X11_RI_ParentController.submitCase`.

`X11_RI_ParentController.getRelatedCaseLst` is documented/captured as a read-only Portal operation, but the current Flutter client does not call it. The current client submits anonymously using the “I'm not sure” / “Loose/Miscellaneous Debris” mapping, one debris location/count, description, and at most one photo. Photo bytes are inline in `submitCase`; no separate upload endpoint exists. Unsupported categories, multiple items/attachments, or contact-mode submission are blocked in this prototype instead of guessed. `submitCase` remains source-derived and its original successful raw envelope/native-send provenance are still unverified; see `docs/portal-api.md` and tickets 04/09.

## Current implementation and evidence

- Canonical Open Design project: `Reports Motion Design Brief`, ID `74204d10-326c-44f9-b11a-7d9401baa491`.
- Entry: `reports-prototype-buttons-v2.html`; runtime: `reports-api-inspector.js`; focused tests: `reports-api-inspector.test.cjs` and `reports-api-inspector-layout.test.cjs`; design spec: `reports-design-spec.json`; handoff: `api-inspector.md`.
- Refreshed repo export: `design-prototype/`; repository notes: `docs/api-inspector.md`.
- Focused command: `node --test design-prototype/reports-api-inspector.test.cjs design-prototype/reports-api-inspector-layout.test.cjs` — 26 passed, 0 failed. Tests use controlled synthetic fixtures only.
- Canonical and refreshed prototype HTML SHA-256: `3a03c8e44ae68e7494938fdfce0176502997546ba8ee098d272916e2c317223a`.
- Canonical and refreshed prototype standalone runtime SHA-256: `264b95df87d4837e1f061a2b9083596d640606e7cde0c1964b3fa0a2dabe8b06`.
- Live UI smoke remains unverified. Browser policy rejected `file:///Users/regiskian/Git/reports/design-prototype/reports-prototype-buttons-v2.html` before navigation/request dispatch with: “Browser Use rejected this action due to browser security policy. Reason: The browser URL policy blocks this action. Browser use could not acquire authority to trigger network egress. The URL policy gate did not grant access. The requested URL protocol is not allowed. Allowed protocols: \"http:\", \"https:\".” No supported project HTTPS preview was found. No fallback server or URL-policy workaround was attempted.

## Comments

- 2026-10-22 user correction supersedes ticket's original generic-request-editor acceptance; the focused 26-test run also covers diagnostic redaction: Dev mode must run only relevant verified MyLA311 operations, use actual Report inputs, and keep `submitCase` available behind exact-payload confirmation.
- Canonical design was updated before the existing prototype export. The safe read-only UI smoke and supported-preview visual reopen remain pending because no supported HTTPS preview route is available. No City request, submission, upload, credential change, push, or deploy was made.
