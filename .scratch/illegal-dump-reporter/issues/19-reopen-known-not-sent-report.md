# 19: Reopen a known Not sent Report for manual correction

**What to build:** A resident can reopen a retained known Not sent Report from saved reports, correct its contents through the resumable editing flow, review the corrections, and explicitly retry. Trace: Q4/Q19.

**Blocked by:** 14: Continue an unfinished Draft after reopening the app.

**Status:** resolved

- [x] Preserve the retained Report and working attachments instead of losing the failed entry or creating duplicates for each correction.
- [x] Only known Not sent outcomes enter this correction path. Submitted and Submission unconfirmed records never become sendable Drafts.
- [x] An unconfirmed attempt remains blocked across restart. Do not introduce an automatic retry, queue, or clearing of its protected marker.
- [x] Demonstrate saved-report reopening, retained input/attachment correction, Review, and an explicit manual retry through the real client using controlled synthetic outcomes without a City write.
- [x] Preserve anonymous illegal-dumping scope (Q18), native submission through the real client, confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Add no other issue type or contact/login flow.
- [x] Create no City write or second Service Request, and never execute historical live-send helpers. Label controlled fixtures explicitly synthetic; they cannot prove a live Submission. Tickets 01, 04, and 09 retain unresolved original native-send proof gaps without blanket-blocking this improvement.
- [x] Introduce no automatic/background send queue, automatic retries, haptics, or persistent manual motion preference. Honor system/session reduced motion wherever motion changes.
- [x] Implement one behavior at a time: a meaningful failing test, the minimal code change, relevant formatter/lint/analysis/test/build checks, then one scoped Conventional Commit. Preserve 100% production line coverage with no exclusions.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim fast tier was applied without evidence.

## Evidence

- The resident regression first failed on absent Correct report. Saved known Not sent rows now reuse the existing Draft/Review flow and original row identity. Legacy JSON with omitted nullable fields replaces by its existing createdAt identity, avoiding an appended duplicate.
- The complete controlled journey reopens a legacy JSON Not sent row, keeps working photo bytes and unrelated exact SR, corrects its description, saves directly to Review, closes/reopens at Review through saved reports, and explicitly retries through the real PortalSubmissionClient HTTP fixture. Corrected answers, anonymous contact and attachment bytes reach the controlled payload; no transport calls happen before Retry. The original row becomes one synthetic Receipt, survives restart, and has no correction action.
- Separate stale-action scenarios preserve fresh Submitted, Submission unconfirmed and ambiguous legacy failed state and block sending. Existing interrupted-send/marker/restart tests remain green. The resident return journey caught and corrected a synchronous setState callback that initially returned a Future; failing candidates and raw outputs were preserved before scoped reverts.
- Fresh formatter and analyzer pass before the serial full gate:89 tests pass, all8 production files1,174/1,174 lines without exclusions. Raw source-bound evidence is under evidence/ticket19. Native verification is assigned to ticket26; no City writes occurred. Independent review/commit pending.

- Safety allowlist: only ReportState.notSent is correctable. GLOSSARY establishes that failed wording does not prove non-delivery; legacy failed rows remain unchanged, read-only and included in the global unconfirmed-send lock. Their Draft continuation is suppressed. A meaningful stale-failed regression first reproduced the unsafe Retry path, then passed with the minimal guard. Current authoritative evidence is ticket19/known-only-*; earlier full logs are preserved superseded candidates.

## Comments

- 2026-10-22 acceptance: reviewed81aaa06 and merged3cf5f4a restrict correction to known Not sent only. Legacy failed, unconfirmed and submitted rows remain protected; stale actions cannot unlock sending. The meaningful three-photo History regression reproduced loss, then photoPaths preserved all attachments through Review/correction/manual controlled retry. worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket19/integrated-focused.log/.exit and integrated-full.log/.exit preserve95tests/1283productionlines, formatter/analyzer and source manifest. Explicit configured commit review passed for the merged candidate. All criteria inspected;26 rechecks native integration. No City write.
