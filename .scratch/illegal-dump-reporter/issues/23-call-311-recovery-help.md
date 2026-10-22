# 23: Reach Call 311 from unconfirmed-submission Help

**What to build:** a resident with an unconfirmed submission can find recovery guidance and invoke the verified Call 311 phone action while retaining the unresolved Report and attempt context. Trace: Q7.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Follow the inspected prototype's Help/recovery presentation and verify the City's contact information before exposing the phone action. The prototype's guidance alone is not evidence of a working telephone action.
- [x] Keep the unresolved SR/attempt context visible and truthful. Opening Help or invoking Call 311 never clears a lock, retries a dispatch, implies cancellation, deletes the record, or changes delivery state.
- [x] Verify the native OS telephone handoff without placing a call. Record any simulator limitation accurately and preserve native handoff evidence with labeled synthetic recovery data where used.
- [x] Preserve anonymous illegal-dumping real-native-client submission, existing Reports/SR numbers, durable attachments, and uncertain-attempt protection. Do not send City writes, invoke historical live-send helpers, or add automatic/background retry queues, haptics, persistent manual motion preferences, contact flows, or other issue types.
- [x] Honor existing system/session reduced motion wherever motion is added. Implement one behavior per test-first burst and scoped Conventional Commit with meaningful checks and 100% production line coverage without exclusions; retain the historical native-send evidence gap.

## Comments

- City contact verified 2026-10-22 against https://lacity.gov/directory/311-call-center and https://lacity.gov/residents/request-services-report-problems: 311 / (213) 473-3231. Real existing url_launcher phone handoff uses tel:+12134733231, externalApplication, with false/exception fallback. Official https://pub.dev/packages/url_launcher notes iOS simulators have no default telephone app; actual native fallback evidence will be retained in ticket26, without placing a call.
- One shared Help page retains the actual globally protected Report context, exact stored reference, description and coordinates; Flow and History expose it for unresolved/legacy-failed records. Opening Help or phone action never invokes submission or storage mutation. Existing continuation hints cover Help and long History. Legacy failed remains protected and amber Submission unconfirmed.
- Meaningful RED: prepared recovery journey failed because recovery UI was absent. GREEN: three separate unavailable/exception/opened phone-boundary tests, each SETUP then EXECUTE then one final deep VERIFY, preserve marker bytes, exact stored SR, Report state/data and attachment bytes across Flow→Help→back→History→Help. No Submit/Retry present, real SubmissionClient test guard throws if called. Dart analyzer final result: No errors. Full coverage pending.

### Fresh candidate gates

- Started 2026-10-22T11:03:33.054Z; full exit 0, 99 tests passed in 106796 ms, JSONL done.success=true. Exact command from reports/: `TZ=Asia/Tokyo TMPDIR=/Users/regiskian/Git/reports/.scratch/api-photo-tmp/ rtk proxy flutter test --coverage --concurrency=1 --reporter expanded --file-reporter json:/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket23/full-tests.jsonl test/`. Final raw output: `01:40 +99: All tests passed!`.
- Final formatter command `rtk proxy dart format --output=none --set-exit-if-changed lib test`: exit0, `Formatted 28 files (0 changed) in 0.19 seconds.` Dart MCP analyze_files: `No errors`. Focused Dart MCP run_tests test/recovery_help_test.dart: `00:03 +3: All tests passed!`; each test explicitly verifies submissionCalls=0, launcherCalls=1, immutable Report, marker and attachment bytes.
- Every production file covered, 1357/1357 lines; missing files=[], exclusions=[]:
  - lib/src/portal_submission_client.dart: 213/213, uncovered lines=[]
  - lib/src/report.dart: 56/56, uncovered lines=[]
  - lib/main.dart: 172/172, uncovered lines=[]
  - lib/src/history_page.dart: 149/149, uncovered lines=[]
  - lib/src/home_confirmation_card.dart: 51/51, uncovered lines=[]
  - lib/src/mobile_report_flow.dart: 400/400, uncovered lines=[]
  - lib/src/reports_design.dart: 81/81, uncovered lines=[]
  - lib/src/storage.dart: 62/62, uncovered lines=[]
  - lib/src/report_presentation.dart: 26/26, uncovered lines=[]
  - lib/src/recovery_help_page.dart: 28/28, uncovered lines=[]
  - lib/src/location_map.dart: 119/119, uncovered lines=[]
- SHA256 source manifest unchanged before/after full. Exact production/dependency/new-test hashes:
  - reports/lib/main.dart: `f815863a16641f938d35899240fd2a3ba81efcf40918ddb5209a0192e5aa1233`
  - reports/lib/src/history_page.dart: `b0043db10f86fe54e0aa02120b8401de5b0217a739c34f05fd5a19051e69d9d2`
  - reports/lib/src/home_confirmation_card.dart: `c5e47e343c837ce0143b62a9d5bae4118a7456f39e8d59d2c7ff2aeb6a184cd0`
  - reports/lib/src/portal_submission_client.dart: `22a8ba02712df13e25213eb6e1f022dabeba0254b26c8cdf09cd61c9fc2f72cd`
  - reports/lib/src/storage.dart: `4da66503e95b614df0f29e0f890e5bbd9a3703728257beab3822d4cc20bf7d15`
  - reports/lib/src/recovery_help_page.dart: `ebc004c3167816ad801675098ee7a45bc7079b65338a7a768e3432198838a9d2`
  - reports/lib/src/mobile_report_flow.dart: `f251fb3d3d5b41564dbae42a63856a57fd8f91a8daeb3fe61f9115d68be191fb`
  - reports/lib/src/location_map.dart: `1c96246c3610646704ae21727fd2687e447ab3d6648299733a49c967ce48cd82`
  - reports/lib/src/reports_design.dart: `5e63232f8707153204f0cd556ffb7b00180fd0df8c6f5f35fe14dce0fd92141b`
  - reports/lib/src/report_presentation.dart: `612d302d396b61974e411549f62ed0b48f8459607b22b81dbbda6f753b92d073`
  - reports/lib/src/report.dart: `45fc63c76605749c230fad8f374142cd0389bfe3b57407f378686191bc7d6d9a`
  - reports/pubspec.yaml: `549f73451f43929ad240fcfb11725bc5cb2e5c3cea3825d3776ad3cd5298cc7b`
  - reports/pubspec.lock: `d73693a277068ce023251ac04ef6dc789486010a1fb2b60109e79ec33a533dcc`
  - reports/test/recovery_help_test.dart: `d6cd5625f51153933356fe2428e0ff06f59efd5df00235abebaf9c7f3e52c95b`
- Raw stdout/JSONL/exits/all-source manifest and LCOV are retained at evidence/ticket23/full-tests{.log,.jsonl,-result.json}, coverage-summary.json and lcov.info. Actual native phone fallback/handoff result is pending final integrated ticket26; no call was placed.

### Final integrated native acceptance

- Frozen source commit `a633402`; fresh integrated full exit0,121 passed,1884/1884 lines across all13 production files, exclusions=[]; formatter32/0, analyzer No errors. Normal real-client arm64 build exit0 (90979ms), isolated fixture build exit0 (32509ms), signing/verification exit0. Source/kernel/product hashes: `evidence/ticket26/native/fixture-product.json` and `production-product.json`; normal product was never installed. Final index: `evidence/ticket26/native-proof-index.json`.
- Actual map pointer tap/zoom/drag, native GPS34.101547,-118.338701, direct Save changes to Review, preserved answers and anonymous real PortalSubmissionClient controlled-HTTP payload verified. Actual green Receipt/date and amber failed/uncertain LA DST presentation captured in native/18-receipt-status-date.png and22-history-status-dst.png. Prior accepted16 gallery selection,17/Flow26 three-photo payload and retained attachments,20 native copy/share cancel, Flow26 removal/restart/manual correction and Experience25 full success/Home/system reduced-motion/pointer recordings compose the reviewed native regression evidence.
- Real native url_launcher external tel:+12134733231 attempt returned unavailable on this simulator, which has no Phone app. Actual truthful fallback UI: native/21-phone.json and23-phone-unavailable.png. No call placed; successful dialer launch is unverified. Opening Help/phone preserved exact Report/SR/attachments/state. Real process restart native/24-protected-restart.json→25-snapshot.json→26-protected.json: Submit0,Retry0,context1,PortalHTTP0. native/27-data-preservation.json proves marker and entire isolated preferences byte-identical, original com.example preferences SHA256 unchanged `369632069f6eebfa903ab68965e1074b2b69cf2b61e9f54dfe92ebeb9ebb7c19`.
- Final native Photos grid was displayed, but CUA selection/cancel control failed with noWindowsAvailable; restart preserved Draft. No fabricated selection: current final request has one retained attachment; prior accepted actual gallery and three-photo component evidence is linked in the index. Historical original C-04955177 response/native-send provenance and City read-only verification remain unresolved;04/09 remain open. No City write, historical helper, call or email was executed. Parent owns final email-ready review package and acceptance metadata.
