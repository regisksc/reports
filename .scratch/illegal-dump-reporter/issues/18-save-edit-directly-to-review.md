# 18: Save a Review edit directly back to Review

**What to build:** A resident can edit a selected Review section and return directly to the updated Review without traversing the remaining steps, preserving every unrelated answer through the complete editing flow. Trace: Q5.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] From Review, open a selected section, change its values, and use Save changes to return directly to Review with those new values and all unrelated answers intact.
- [x] Required-field validation still applies. Cancellation/back never silently dispatches or erases the Report.
- [x] Demonstrate the complete edit-and-return journey for the currently supported sections and verify that the updated Review feeds the real client's outbound payload through controlled tests without a City write.
- [x] Each later location/photo feature preserves this same edit-return contract, including retained attachment access and the selected actual location.
- [x] Preserve anonymous illegal-dumping scope (Q18), native submission through the real client, confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Add no other issue type or contact/login flow.
- [x] Create no City write or second Service Request, and never execute historical live-send helpers. Label controlled fixtures explicitly synthetic; they cannot prove a live Submission. Tickets 01, 04, and 09 retain unresolved original native-send proof gaps without blanket-blocking this improvement.
- [x] Introduce no automatic/background send queue, automatic retries, haptics, or persistent manual motion preference. Honor system/session reduced motion wherever motion changes.
- [x] Implement one behavior at a time: a meaningful failing test, the minimal code change, relevant formatter/lint/analysis/test/build checks, then one scoped Conventional Commit. Preserve 100% production line coverage with no exclusions.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim fast tier was applied without evidence.

## Evidence

- The retained-Draft resident scenario first failed on missing Save changes after Edit Photo. The minimal Review edit mode now returns all four sections directly to updated Review; quantity/description validation and both back paths preserve inputs without dispatch.
- The same controlled scenario checks changed GPS coordinates, debris and quantity, description, retained photo bytes, anonymous contact and the real PortalSubmissionClient payload. Existing known-failure retry and phone-width normal/system/session motion scenarios retain their original safety/geometry assertions with the intended edit-back contract.
- Fresh Dart formatter and analyzer pass before the serial full coverage gate:85 tests pass, all8 production files1,128/1,128 lines without exclusions. Raw evidence is in evidence/ticket18; integrated native verification is assigned to ticket26. No City write occurred. Independent review/commit pending.

## Comments

- 2026-10-22 acceptance: reviewedbab0dbb →6bab597 proves every supported Review section saves directly to updated Review, retaining unrelated answers, photo access and required validation. worktrees/draft/.scratch/illegal-dump-reporter/evidence/ticket18/source-manifest.json, focused.exit0 and full.exit0 preserve85tests/1128lines plus format/analyze. The controlled real PortalSubmissionClient payload contains corrected coordinates and answers. Later17 retains direct Photo edit return. All criteria inspected;26 covers combined native regression. No City write.
