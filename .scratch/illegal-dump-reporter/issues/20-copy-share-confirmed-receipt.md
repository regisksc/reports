# 20: Copy and share a confirmed Receipt

**What to build:** a resident can copy the exact confirmed Service Request number and share its accurate Receipt from the saved-Report/Receipt experience. Trace: Q6.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Copy uses the exact retained City SR number; sharing presents accurate retained Report/Receipt details for confirmed acceptance only. Unconfirmed and Not sent records never produce fabricated successful Receipts.
- [x] Native copy/share works independently of the new Home confirmation card and authored success animation. Dismissing the share sheet preserves the Receipt, delivery state, City request, and uncertainty protection.
- [x] Verify native clipboard and share-sheet behavior using clearly labeled synthetic confirmed records without a City send. Share-sheet work does not block 21's independent Copy and View receipt actions.
- [x] Preserve anonymous illegal-dumping submission through the real native client, existing Reports and exact SR values, durable attachments, and uncertain-attempt locks. No City writes or historical live-send helpers, automatic/background retry queue, haptics, persistent manual motion preference, contact flow, or other issue types are introduced.
- [x] Implement one behavior per test-first burst and scoped Conventional Commit, run meaningful focused checks, and maintain 100% production line coverage without exclusions. Synthetic evidence remains labeled; the original native-send evidence gap remains unresolved.

## Comments

- Candidate adds Copy number and Share receipt to the saved Report detail's confirmed Receipt only. Clipboard receives the exact retained SR. The native share sheet receives retained anonymous illegal-dumping details and an iPad origin rectangle; dismissal changes no row, SR, delivery state or attempt marker. Other delivery states and null/empty SR values expose neither action.
- Native sharing uses maintained `share_plus` 13.3.1, resolved by Dart MCP with platform interface 7.2.0. Jev selected the plugin over a custom channel, Context7 verified the current ShareParams API, and the resolved package's native channel contract was checked. No Home-card or authored animation implementation was changed.
- Meaningful red tests failed on the missing Receipt controls. Three focused structured tests now pass: exact Clipboard data and dismissed share preserving raw reports_v2 rows and a protected attempt marker; actionable platform failure messages without state changes; and successful-Receipt guards across unconfirmed and missing-SR records. Dart analysis is clean. Full coverage and isolated native compile/clipboard/share-sheet proof are pending; evidence is under `evidence/ticket20`.
- Controlled records and the native fixture are explicitly synthetic. The fixture instantiates no network submission client and cannot create a City request. The original live Submission provenance gap remains unresolved.

- 2026-10-22 acceptance: reviewedd2cdc50 →2d9c208 passes94tests/1265productionlines, formatter/analyzer and new-plugin arm64 build0 in85s. worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket20/native/native-interaction.json and clipboard-proof.json verify exact SR-SYNTHETIC-20-EXACT in native clipboard, observed iOS share sheet, cancellation without selecting a destination, and unchanged Receipt/preferences/protected marker. Parent inspected native-share-sheet.png and receipt-after-cancel.png. Original com.example.reports preferences remained byte-identical. All criteria inspected. Synthetic evidence proves no live City acceptance; no City write.
