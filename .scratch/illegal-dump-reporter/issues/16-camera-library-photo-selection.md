# 16: Select and remove an optional photo from camera or library

**What to build:** A resident can use the photo library as well as the camera, review the selected optional photo, and remove it before explicitly sending a Report through the currently supported one-photo contract. Trace: Q3.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Keep the currently supported one-photo contract working end to end through the native real submission client.
- [x] Selection/removal updates the visible Report, Review, and retained attachment data. Cancelled pickers and permission failures do not erase other answers.
- [x] A removed attachment is absent from the actual outbound Report payload, verified with controlled tests without a City write.
- [x] Photo-free reporting remains available.
- [x] Preserve the direct edit-return contract when editing a photo from Review, including saving the changed selection and retaining unrelated answers.
- [x] Preserve anonymous illegal-dumping scope (Q18), confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Add no other issue type or contact/login flow.
- [x] Create no City write or second Service Request, and never execute historical live-send helpers. Label controlled fixtures explicitly synthetic; they cannot prove a live Submission. Tickets 01, 04, and 09 retain unresolved original native-send proof gaps without blanket-blocking this improvement.
- [x] Introduce no automatic/background send queue, automatic retries, haptics, or persistent manual motion preference. Honor system/session reduced motion wherever motion changes.
- [x] Implement one behavior at a time: a meaningful failing test, the minimal code change, relevant formatter/lint/analysis/test/build checks, then one scoped Conventional Commit. Preserve 100% production line coverage with no exclusions.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim fast tier was applied without evidence.

## Comments

-16a library selection candidate: explicit camera and library actions reuse the existing one-photo picker and durable support-directory copy. A pending picker disables both photo actions; cancellation and native permission exceptions retain the existing photo and unrelated answers. No package, storage lifecycle, submission client, or navigation change.
- One new resident scenario fails first on the missing library action, then proves retained preview and Draft, usable bytes after removing the synthetic picker cache, cancellation, permission failure, preserved camera source, Review answers, the real client's exact one-photo payload over MockClient, and an unchanged synthetic prior receipt. Full81 tests pass, all8 production files1040/1040 lines covered without exclusions; analyzer clean; formatter19 files0 changes. Evidence is under evidence/ticket16/library in the photo worktree.
- Real-entry arm64 simulator build passed with preserved exit0 in58.0s; Podfile target15.0 override remains intact. This proves the build, while native interaction and strict review/commit remain pending.
- This cycle does not yet add removal; the later direct Review edit-return proof remains separate. Controlled fixture responses do not prove a live City Submission or repair tickets01/04/09.

- 16a native follow-up: the isolated `dev.regis.reports.photo.fixture` used the real system Photos picker to select an imported synthetic PNG. Native preview and Review displayed the retained attachment; the persisted Draft kept the photo in application support and preserved its other answers. Submit was never pressed. Source/kernel hashes, normal framework identifiers, signing results, screenshots and AX text are indexed by `evidence/ticket16/native/harness-ready.json` and `native-interaction.json`. The fixture never instantiates a network client. The original app preference SHA-256 after this batch was `369632069f6eebfa903ab68965e1074b2b69cf2b61e9f54dfe92ebeb9ebb7c19`.
- 16b removal candidate: `Remove photo` clears the selected reference and picker error, then saves the Draft through the existing persistence function. It never deletes a physical file, because a confirmed Report may retain that same file. A resident regression first fails on the missing control, then proves no preview, photo-free Review, retained unrelated answers after restart, the real PortalSubmissionClient's empty `sFileLinks` over controlled MockClient, and the exact prior SR and shared receipt photo remaining intact.
- Fresh 16b gates: Dart MCP focused removal test passed; Dart MCP analysis returned `No errors`; `rtk proxy flutter test --coverage --concurrency=1 --reporter expanded test/` passed 82 tests, exit 0; every production Dart file appears in LCOV, 1047/1047 lines covered with no exclusions. `rtk proxy dart format --output=none --set-exit-if-changed lib test` passed with 19 files and 0 changed; `rtk git diff --check` passed. The declared arm64 iOS simulator `xcodebuild` passed, exit 0 in 17.2 seconds. Raw logs, exits and exact candidate source hashes are indexed by `evidence/ticket16/removal/gate-summary.json`.
- Two initial post-code focused checks exposed fixture assumptions, the no-photo button is `Skip photo` and restored Review waits for the storage lock before Submit. Each failure reverted only the removal production burst before correcting the test and reapplying the minimal candidate. No production fallback or weakened assertion was introduced.
- Ticket 16 remains open until ticket 18's direct Review edit-return contract is integrated and verified. These controlled tests and native fixtures create no City write and do not establish the missing historical live Submission provenance.

- 2026-10-22 acceptance: reviewedc2ea93e/d822f95 →0792eda/23447aa prove selection/removal, photo-free payload, cancelled/failed picker retention and restart. ticket16/removal/gate-summary.json preserves82tests/1047lines, format/analyze/nativebuild0. ticket16/native/native-interaction.json and native-library.png/native-review-photo.png show the real iOS Photos picker and durable file. This UI-only fixture forbids City writes; real-client attachment behavior is separately controlled. Reviewed18/17 supply direct Photo edit return and retained unrelated answers. All criteria inspected;26 rechecks integration.
