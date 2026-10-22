# 21: Return to Home with a swipe-dismissable confirmation card

**What to build:** after confirmed City acceptance, return to Home and present the exact SR number, Copy, and View receipt in a confirmation notice that follows the agreed left-swipe interaction. Trace: Q24/Q26.

**Blocked by:** 11: Establish usable skills and the animation authoring/runtime route.

**Status:** resolved

- [x] Home displays the exact confirmed SR with working Copy and View receipt actions. It returns without a standard lateral route slide. The full authored letter scene belongs to 25 and is not required to demonstrate this usable endpoint.
- [x] Copy and View receipt work without waiting for 20's share-sheet support. Missing, rejected, or unconfirmed outcomes never show a fabricated acceptance notice.
- [x] Normalize leftward displacement by the card width, clamp rightward displacement to zero, and let the card follow the drag independently of its opacity. Maintain full opacity through 20% of card width, then progressively fade to zero at one full card-width displacement.
- [x] Release at or above 40% of card width completes the leftward exit and fade. Release below 40% always recenters and restores full opacity. Velocity alone cannot override this distance-on-release rule.
- [x] Gesture cancellation always recenters and restores full opacity, including after crossing the dismissal threshold or partially fading. Separately verify the no-fade region, progressive fade, below-threshold release, threshold release, cancellation after partial fade, and retained Receipt availability.
- [x] Recenter and dismiss behavior respects the existing system/session motion-preference seam without haptics or a persistent manual preference upgrade. Controlled tests do not establish observed iOS system-setting compliance; that native evidence remains part of 13 and final integration.
- [x] Dismissal hides only the Home notice. It never deletes a Receipt, cancels a City request, changes delivery state, clears an unresolved attempt, or unlocks another send. Preserve existing Reports, exact SR values, durable attachments, and locks across restart.
- [x] Demonstrate the gesture with labeled synthetic confirmed acceptance and a native recording that shows recentering; no new live send is required. Preserve the historical original native-send evidence gap.
- [x] Keep anonymous illegal-dumping native-client behavior intact. Do not call City write endpoints or historical live-send helpers, add automatic/background retry queues, contact flows, or other issue types. Implement one behavior per test-first burst and scoped Conventional Commit with meaningful checks and 100% production line coverage without exclusions.

## Comments

2026-10-22: the accepted result returns Home immediately through Navigator.removeRoute only after the submitted Report has been retained. Failed storage keeps the existing Receipt and sending lock on the report page; missing, rejected and unconfirmed outcomes cannot produce the Home card. Home shows the exact retained SR, Copy and View receipt. The card follows normalized leftward distance, clamps rightward movement to zero, stays opaque through 20%, fades linearly to zero at one width, dismisses on release at or above 40%, and recenters after below-threshold release or cancellation. Velocity does not change this decision. Dismissal hides the notice only. Home also uses the shared faint overflow cue.

The resident test first failed because accepted production-client HTTP replay remained on the report page, then passed the complete Home/Copy/Receipt/gesture/retention journey in normal and verified effective session-reduced motion. It records exact outcomes then verifies them once, including 10%/20% full opacity, 35%/70% fade, 100% opacity zero, cancellation after partial fade and at full width, a fast below-threshold release, exact 40% dismissal, and unchanged saved Receipt. Formatting passes and Dart analysis reports No errors. Raw red/green JSON: reports/.scratch-confirmation-{red,green}.json; frozen hashes: evidence/ticket21/source-manifest.json. Full CLI gate passed with exit 0: 85 tests, 1196/1196 production lines covered across every lib file, without exclusions. Raw full.log/full.exit and coverage.json are retained in evidence/ticket21; full JSON is reports/.scratch-confirmation-full.json. Native build/recorded recentering and the combined accepted animation remain in ticket26's native gate. All HTTP responses in the controlled test are synthetic; no City write was made and no original native-send proof gap is closed.

### Recognized native pointer cancellation correction

- A controlled native two-move drag exposed that Flutter can deliver an accepted PointerCancel through onHorizontalDragEnd. The original onHorizontalDragCancel alone could dismiss a partially faded card beyond 40%. The failed native recording and raw error remain in ticket25/native-delivery-refined.mp4 and native-refined-swipe.json.
- A pointer listener now marks cancellation before the drag-end callback, which always recenters a cancelled gesture. Start/end/cancel reset the flag; normal distance thresholds, fading, rightward clamp, durable receipts and pressed controls remain unchanged.
- Actual pointer regression: tester.startGesture, two moveBy events past 40%, partial opacity, then gesture.cancel. Red reports dismissals=1; green restores the exact center and opacity=1, keeps the exact SR and opens View receipt. The existing accepted HTTP/notice scenario also passes. Raw red/green JSONL: reports/.scratch-pointer-cancel-red2.json and .scratch-pointer-cancel-green.json. Format and analysis pass.

```text
completion UTC: 2026-10-22T11:03:16.475341+00:00
command: rtk proxy flutter test --coverage --concurrency=1 --reporter expanded --file-reporter json:.scratch-pointer-cancel-full.json test/
exit: 0
JSONL: {"success":true,"type":"done","time":51015}
nonhidden successful tests: 100
lib/main.dart: 202/202
lib/src/history_page.dart: 111/111
lib/src/home_confirmation_card.dart: 48/48
lib/src/location_map.dart: 119/119
lib/src/mobile_report_flow.dart: 384/384
lib/src/portal_submission_client.dart: 213/213
lib/src/report.dart: 56/56
lib/src/report_delivery_scene.dart: 388/388
lib/src/reports_design.dart: 81/81
lib/src/storage.dart: 62/62
all lib files present: 10; total: 1664/1664; no exclusions
SHA256:
lib/src/home_confirmation_card.dart: 4d3c553228167a3bd63c6985f51df13ef2360d715eda57bcc4e41bc2ca4ae2e5
test/confirmation_pointer_cancel_test.dart: 08448f206112db929f5551debbf17d6b7387a5d7112adf61bb5108be289795cb
focused: flutter test test/confirmation_pointer_cancel_test.dart test/home_confirmation_test.dart; +2 All tests passed!, exit 0
formatter: 0 changes after format; analyzer: No errors
```

Integration review phase repair: the real pointer regression is now three independent tests: held recognized drag past 40% with partial opacity; cancellation restoring the exact rectangle/full opacity with no dismissal; and View receipt opening with the exact SR after cancellation. Each test has one operation under verification and one final assertion; preparatory gestures/cancellation are setup for the latter cases. Actual pointer movement remains tester.startGesture plus two moveBy events, with no direct handler invocation.

```text
command: flutter test --concurrency=1 --reporter expanded --file-reporter json:.scratch-pointer-cancel-phase-fix.json test/confirmation_pointer_cancel_test.dart
result: 00:00 +3: All tests passed!; exit 0
formatter: 0 changes; analyzer: No errors
production unchanged by phase repair; prior full 100 tests, 1664/1664 lines and recorded native pointer proof retained; integrated final26 full gate remains separate.
```

### Accepted resolution

Accepted integrated commit: `c564995`; real native cancellation correction/proof source: `a2c3824`. The recorded native pointer test holds 25% displacement at opacity 0.9375 then recenters on release; holds 70% at opacity 0.375 then recenters on cancellation; Copy, threshold dismissal and retained History receipt pass. Actual recording: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-fixed-cancellation.mp4](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-fixed-cancellation.mp4). Exact observed assertions: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-verification.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-verification.json). Installed kernel/source provenance: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-package.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-package.json). The isolated fixture uses production PortalSubmissionClient with labeled synthetic HTTP replies; it does not prove a live City send.

Root review accepted all criteria for this issue on 2026-10-22; this acceptance supersedes earlier pending notes. The combined final26 code gate passed under TZ=Asia/Tokyo: 121 tests, 0 skipped, 1884/1884 covered lines across all 13 production files, no exclusions and stable source hashes; formatting 32 files/0 changes, analyzer No errors. Exact existing gate records: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json). Final26 native build/UI acceptance remains pending; this issue's resolution does not mark 26 done. No City write was performed; original native-send evidence gaps 01/04/09 remain unresolved.
