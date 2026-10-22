# 24: Read truthful statuses and Los Angeles dates consistently

**What to build:** saved Reports, Receipts, and confirmation surfaces communicate actual delivery state consistently and show US dates with a 12-hour clock in Los Angeles time. Trace: Q10/Q11/Q21/Q25.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Show green Submitted, amber Submission unconfirmed, and neutral Not sent with those text labels. Never infer acceptance or delivery state from color alone or change a record's actual state to match its presentation.
- [x] Use US date presentation and a 12-hour clock with AM/PM in America/Los_Angeles, including the applicable PST/PDT offset, regardless of a device's different timezone.
- [x] Preserve original stored timestamps, actual delivery states, and exact City SR values. Verify daylight-saving boundaries and a differing device timezone with fixed labeled synthetic data.
- [x] Preserve anonymous illegal-dumping submission through the real native client, existing Reports, durable attachments, and uncertain-attempt locks across restart. No City writes or historical live-send helpers, automatic/background retry queue, haptics, persistent manual motion preferences, contact flow, or other issue types are introduced.
- [x] Honor existing system/session reduced motion wherever motion is added. Implement one behavior per test-first burst and scoped Conventional Commit, run meaningful checks, and maintain 100% production line coverage without exclusions. Keep synthetic evidence labeled and the historical native-send evidence gap unresolved.

## Comments

- Shared presentation maps only submitted to green Submitted, only notSent to neutral Not sent, and failed/submissionUncertain to amber Submission unconfirmed. Legacy failed is deliberately protected per GLOSSARY.md, Submission unconfirmed; no stored-state migration.
- timezone 0.11.2 IANA America/Los_Angeles formatter supplies US MM/DD/YYYY, 12-hour AM/PM and applicable PST/PDT with numeric UTC offset. History, Receipt and shared Created text use it. Confirmation surfaces add explicit green Submitted text.
- Fixed synthetic regression covers spring/fall DST boundaries, noon/midnight, Tokyo equivalent instants, every stored state, exact SR and byte-identical reports_v2 rows. RED/failed-burst/first-green proof is under .scratch/illegal-dump-reporter/evidence/ticket24. Focused 5 tests passed; Dart analysis clean; format26 files0 changes. Full coverage pending. Pure Dart native verification joins combined ticket26.

### Fresh candidate gates

- Started 2026-10-22T10:48:24.160Z; full exit 0, 96 tests passed in 127270 ms, JSONL done.success=true. Command from reports/: `TZ=Asia/Tokyo TMPDIR=/Users/regiskian/Git/reports/.scratch/api-photo-tmp/ rtk proxy flutter test --coverage --concurrency=1 --reporter expanded --file-reporter json:/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket24/full-tests.jsonl test/`. Final raw output: `01:56 +96: All tests passed!`. This explicitly runs with a process timezone different from Los Angeles.
- Formatter: Dart MCP dart_format lib/test, `Formatted 26 files (0 changed) in 0.15 seconds.` Analyzer: Dart MCP analyze_files, `No errors`. Focused test command: Dart MCP run_tests test/report_presentation_test.dart and test/receipt_actions_test.dart, `00:03 +5: All tests passed!`.
- LCOV covers every production file, 1309/1309 lines, missing files=[], exclusions=[]:
  - lib/src/portal_submission_client.dart: 213/213, uncovered lines=[]
  - lib/src/report.dart: 56/56, uncovered lines=[]
  - lib/src/history_page.dart: 140/140, uncovered lines=[]
  - lib/src/report_presentation.dart: 26/26, uncovered lines=[]
  - lib/src/reports_design.dart: 81/81, uncovered lines=[]
  - lib/src/storage.dart: 62/62, uncovered lines=[]
  - lib/main.dart: 172/172, uncovered lines=[]
  - lib/src/home_confirmation_card.dart: 51/51, uncovered lines=[]
  - lib/src/mobile_report_flow.dart: 389/389, uncovered lines=[]
  - lib/src/location_map.dart: 119/119, uncovered lines=[]
- Exact SHA-256 source manifest was identical before and after the full suite:
  - reports/lib/main.dart: `f815863a16641f938d35899240fd2a3ba81efcf40918ddb5209a0192e5aa1233`
  - reports/lib/src/history_page.dart: `e79a5b26819858ba49de2584188845042d5c40df5cee91b0ed0d8cd8bc93fd71`
  - reports/lib/src/home_confirmation_card.dart: `c5e47e343c837ce0143b62a9d5bae4118a7456f39e8d59d2c7ff2aeb6a184cd0`
  - reports/lib/src/portal_submission_client.dart: `22a8ba02712df13e25213eb6e1f022dabeba0254b26c8cdf09cd61c9fc2f72cd`
  - reports/lib/src/storage.dart: `4da66503e95b614df0f29e0f890e5bbd9a3703728257beab3822d4cc20bf7d15`
  - reports/lib/src/mobile_report_flow.dart: `d29a3fc467762d8a1ce10efa7b5e800849374b9226bfeb2ab3124f8e4af49821`
  - reports/lib/src/location_map.dart: `1c96246c3610646704ae21727fd2687e447ab3d6648299733a49c967ce48cd82`
  - reports/lib/src/reports_design.dart: `5e63232f8707153204f0cd556ffb7b00180fd0df8c6f5f35fe14dce0fd92141b`
  - reports/lib/src/report_presentation.dart: `612d302d396b61974e411549f62ed0b48f8459607b22b81dbbda6f753b92d073`
  - reports/lib/src/report.dart: `45fc63c76605749c230fad8f374142cd0389bfe3b57407f378686191bc7d6d9a`
  - reports/pubspec.yaml: `549f73451f43929ad240fcfb11725bc5cb2e5c3cea3825d3776ad3cd5298cc7b`
  - reports/pubspec.lock: `d73693a277068ce023251ac04ef6dc789486010a1fb2b60109e79ec33a533dcc`
  - reports/test/report_presentation_test.dart: `ee3913054f38d150330bcf3cf8380e8c3474c429653d17e391a895475fada4eb`
  - reports/test/receipt_actions_test.dart: `5f7cfaff3f82f7f2fd4512f23e74b1fea36003a00de87fd39b00cc1dc67836c2`
- Raw JSONL, full stdout, exit manifest and unchanged hashes: evidence/ticket24/full-tests{.jsonl,.log,-result.json}; coverage-summary.json and lcov.info retain raw coverage. Native presentation verification is included in the final integrated ticket26 build, without another standalone pure-Dart build.

### Accepted resolution

Accepted commit: `e7fcda6`. Green Submitted, amber Submission unconfirmed and neutral Not sent are accepted without state mutation; Los Angeles US dates/12-hour AM/PM with PST/PDT offsets are verified across Tokyo device/process timezone and DST boundaries. Existing controlled proof: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket24/full-tests-result.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket24/full-tests-result.json) and [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket24/coverage-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket24/coverage-summary.json); fixed boundary fixtures are in `/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/reports/test/report_presentation_test.dart`. The final integrated Tokyo code gate below passes. No standalone native 24 capture is asserted; final combined native verification remains with 26.

Root review accepted all criteria for this issue on 2026-10-22; this acceptance supersedes earlier pending notes. The combined final26 code gate passed under TZ=Asia/Tokyo: 121 tests, 0 skipped, 1884/1884 covered lines across all 13 production files, no exclusions and stable source hashes; formatting 32 files/0 changes, analyzer No errors. Exact existing gate records: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json). Final26 native build/UI acceptance remains pending; this issue's resolution does not mark 26 done. No City write was performed; original native-send evidence gaps 01/04/09 remain unresolved.
