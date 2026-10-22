# 25: Deliver the Report as a 2D letter into the Home hero

**What to build:** confirmed acceptance plays one expressive authored 2D story: the Report becomes a letter, flies through the air, reaches town hall, and the town-hall scene shrinks into the existing Home hero while Home and its confirmed SR card appear around it. Trace: Q14/Q22/Q23/Q27.

**Blocked by:** 13: Make reporting controls visibly responsive and motion-aware; 21: Return to Home with a swipe-dismissable confirmation card.

**Status:** resolved

- [x] Follow the verified authoring/runtime route from 11 and author the actual artwork and animation as part of this slice. Rive plus Flutter is a researched recommendation, not a mandatory engine or a substitute for creating the real asset; Unity and actual 3D are not required. Verify feasible authoring before committing to a runtime, and obtain an explicit decision for any scope reduction.
- [x] Retain the official confirmed SR/Receipt before starting success. Rejected, missing, or unconfirmed responses never start the story. The letter depicts City acceptance of the real API Submission, not a new email API or completed physical cleanup.
- [x] Visibly transform the Report into a letter, carry it through the air with the agreed expressive, complex motion, and visibly establish arrival at town hall. A loader, checkmark, text replacement, or placeholder alone does not satisfy this scene. No numeric duration or easing curve was agreed; tune them while preserving the complete story.
- [x] Continue the same composition smoothly into Home: shrink/settle the town-hall scene into the existing Home hero with its agreed proportions unchanged, while the rest of Home and the exact-SR confirmation card appear around it. Do not insert a standard lateral page transition.
- [x] Preserve working Receipt access if the animation is interrupted or an asset fails. Presentation failures never delete accepted records, alter delivery state or SR values, or authorize another send.
- [x] Honor the proven system/session reduced-motion path without haptics or a persistent manual preference upgrade. Preserve a usable confirmed Receipt and Home outcome when motion is reduced.
- [x] Record the complete accepted-success-to-Home presentation, card recentering, and reduced-motion outcome with environment and truthful provenance. A static screenshot alone is insufficient; use labeled synthetic accepted responses without a new City submission and preserve the historical original native-send evidence gap.
- [x] Preserve anonymous illegal-dumping native-client behavior, existing Reports, durable attachments, and uncertain-attempt locks. No City writes or historical live-send helpers, automatic/background retry queues, contact flows, or other issue types are allowed.
- [x] Implement one behavior per test-first burst and scoped Conventional Commit, run meaningful focused and native checks, and maintain 100% production line coverage without exclusions.

## Comments

- Native Flutter Canvas authors the approved report-to-letter fold, curved rightward exit, offscreen-left re-entry, town-hall door arrival, layered clouds, trails and sparkles. The same vector composition and shared controls settle continuously into the measured existing Home hero. No video playback or lateral success route is used.
- The accepted Report and exact SR are retained before Home starts the scene. Rejected, uncertain and failed durable saves retain their existing receipt/lock path. System/session reduced motion bypasses the story; interruption or missing target layout completes once on static Home with receipt access. Artwork is synchronous native vectors with no runtime asset dependency.
- Fresh meaningful red: `.scratch-delivery-red4.json` observes no scene on the prior source. Format/analysis and four focused delivery, original motion and confirmation scenarios pass in `.scratch-delivery-green4.json`. Every test has one final outcome assertion.
- Evidence: `.scratch/illegal-dump-reporter/evidence/ticket25/` contains the exact source manifest, raw full-suite log/exit, all-file coverage inventory, preserved TCR bursts and labeled controlled widget storyboard. Native synthetic Portal HTTP recording is being captured separately; this does not repair the historical native City-send provenance gap or send a new City request.

- Full gate: `rtk proxy flutter test --coverage --concurrency=1 test/` exits 0; 93 tests pass and every production line is covered, 1655/1655 across all 10 lib files, no exclusions. Raw JSONL: `reports/.scratch-delivery-full.json`; source-bound inventory and exit: `evidence/ticket25/coverage.json`, `full.exit`, `source-manifest.json`.

### Inspectable gate record, 2026-10-22 UTC

```text
command: rtk proxy flutter test --coverage --concurrency=1 --reporter expanded --file-reporter json:.scratch-delivery-full.json test/
exit: 0
JSONL: {"success":true,"type":"done","time":111961}
nonhidden successful tests: 93
LCOV, hit/found, no exclusions:
lib/main.dart: 202/202
lib/src/history_page.dart: 111/111
lib/src/home_confirmation_card.dart: 39/39
lib/src/location_map.dart: 119/119
lib/src/mobile_report_flow.dart: 384/384
lib/src/portal_submission_client.dart: 213/213
lib/src/report.dart: 56/56
lib/src/report_delivery_scene.dart: 388/388
lib/src/reports_design.dart: 81/81
lib/src/storage.dart: 62/62
all lib files present: 10; total: 1655/1655
SHA256 source:
lib/main.dart: c1f224a3548b7d8d2001b47db176a87ec9507aa0653de84051208c74ad8cc3e3
lib/src/report_delivery_scene.dart: d7e8413654160a00fcb5c8e04d5930c395a53fd3ff31693eb1c942ec7f02f83f
test/report_delivery_test.dart: c0472b459435775133e2c6ba0fba7926f3d78e409e59c7f47ad236ae05477df3
review repair: 8 independent tests, one scenario and one final assertion per test; normal/system/session are separate registered tests; production source unchanged from full gate.
focused command: flutter test --reporter expanded --file-reporter json:.scratch-delivery-review-fix.json test/report_delivery_test.dart
focused result: 00:12 +8: All tests passed!; exit 0
formatter: 0 changes after format; analyzer: No errors
```

### Accepted resolution

Accepted integrated commit: `7503f11`. The complete authored native Flutter letter fold, curved right exit, offscreen-left entry, town-hall door arrival and continuous measured-hero settlement are accepted. Actual normal native recording, 54.135s: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-normal.mp4](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-normal.mp4); actual iOS Reduce Motion recording, 37.626667s: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-reduced.mp4](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-reduced.mp4). Restored system setting: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-motion-restored-off.ax.txt](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-motion-restored-off.ax.txt). Native Home frame: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-frames-verified/home.png](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-frames-verified/home.png). Retained-SR-before-scene and real pointer evidence: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-proof-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket21-cancel/native-proof-summary.json). These are labeled synthetic HTTP acceptances through the production native client, not a new City request, email API or cleanup completion.

Root review accepted all criteria for this issue on 2026-10-22; this acceptance supersedes earlier pending notes. The combined final26 code gate passed under TZ=Asia/Tokyo: 121 tests, 0 skipped, 1884/1884 covered lines across all 13 production files, no exclusions and stable source hashes; formatting 32 files/0 changes, analyzer No errors. Exact existing gate records: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json). Final26 native build/UI acceptance remains pending; this issue's resolution does not mark 26 done. No City write was performed; original native-send evidence gaps 01/04/09 remain unresolved.
