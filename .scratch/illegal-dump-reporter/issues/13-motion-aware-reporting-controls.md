# 13: Make reporting controls visibly responsive and motion-aware

**What to build:** A resident sees stronger step/page movement, raised-button press feedback, and a faint cue when content continues below, with system/session reduced motion honored throughout the existing reporting journey. Trace: Q9/Q12/Q13/Q15/Q16/Q20.

**Blocked by:** 11: Establish usable skills and the animation authoring/runtime route.

**Status:** resolved

- [x] First use the selected usable motion/animation guide or authoring route established by ticket 11. Do not substitute an unverified route or silently skip its preflight.
- [x] Verify the installed iOS/Flutter system preference path against the installed SDK and demonstrate Follow device settings with iOS Reduce Motion. Fix preference delivery only if a focused reproduction shows a failure; do not claim a current bug was observed beforehand.
- [x] Pressing a raised button visibly compresses it and reduces its shadow. Step/page movement is more obvious than the rejected subtle-transition proposal.
- [x] Keep the bottom continuation hint at most five logical pixels high and very light; hide it at the end of the content. Keep the Home hero's existing proportions.
- [x] Both system and session motion choices retain usable feedback without expressive transitions. Add no haptics or preference-persistence upgrade.
- [x] Demonstrate the complete behavior through the existing report journey without a City send, with meaningful controlled tests for normal motion and both reduced-motion choices.
- [x] Preserve anonymous illegal-dumping scope (Q18), native submission through the real client, confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Add no other issue type or contact/login flow.
- [x] Create no City write or second Service Request, and never execute historical live-send helpers. Label controlled fixtures explicitly synthetic; they cannot prove a live Submission. Tickets 01, 04, and 09 retain their unresolved original native-send proof gaps without blocking unrelated improvements.
- [x] Introduce no automatic/background send queue or automatic retries. Keep manual motion preference session-only.
- [x] Implement one behavior at a time: a meaningful failing test, the minimal code change, relevant formatter/lint/analysis/test/build checks, then one scoped Conventional Commit. Preserve 100% production line coverage with no exclusions.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim fast tier was applied without evidence.

## Comments

2026-10-22, first bounded behavior: raised primary buttons use the retained
Flutter animations v2.0 guide and native implicit widgets. Jev `jev-latest`
selected the existing theme integration and then standard implicit widgets.
The actual Home button keeps its white face and border through the shared style
factory; its face compresses by 3 logical pixels and shadow drops from 4 to 1.
Label placement follows the face, while outer hitbox and hero geometry stay
fixed. Cancellation restores the surface; reduced motion keeps immediate press
feedback, and disabled controls have no raised shadow or press response.

After preserving the failed custom-tween candidate and restoring the owned
source, the new visual tests failed against the restored source, then passed
against the implicit implementation. One focused test retains all 18 visual/action assertions across normal, reduced-motion
and disabled states. It and all 78 tests pass.
All seven production files total 883/883 covered lines, with no exclusions;
Dart MCP analysis reports No errors and formatting passes. Raw red/green/full
coverage results are retained in ignored `evidence/ticket13/`.

This is one behavior, not ticket completion. Step/page movement, the bottom
continuation hint and observed iOS Settings Reduce Motion remain pending.
Controlled reduced-motion tests are synthetic; they do not prove native system
preference delivery. Native simulator ownership belongs to the Draft work until
released. No City requests or historical live-send helpers were used. No haptic
feedback or persistent manual preference was added. No exposed runtime payload
proves a fast service tier, so none is claimed.

Native build for this candidate: direct Xcode arm64 build targeting iPhone 18 Pro
completed with exit 0 and `BUILD SUCCEEDED`. Command, log and exit status are in
`evidence/ticket13/ios-arm64-build-*`. The general Flutter simulator build
first failed on a deleted context-mode temp directory, then on combined-arch
validation; the stable-temp, explicit-arm64 build succeeded. Generated
Podfile.lock changes were restored byte-for-byte to HEAD. This verifies native
compilation only; simulator interaction remains pending.

2026-10-22, second bounded behavior, native reproduction: the separate synthetic
motion fixture compiled from d971076 showed Follow device settings selected
while the actual iOS Settings Reduce Motion switch was on. The runtime reported
`reduceMotion: true`, `disableAnimations: false`, and effective Home animations
enabled. The session override disabled animations. Actual AX, screenshot, source
and compiled Dart kernel fingerprints are retained in `evidence/ticket13b/`.
Only the changed iOS Reduce Motion switch was restored to its original off state.

The one regression scenario failed on that same initial system flag, then passed
after the existing ReportApp state observed accessibility changes and combined
the iOS flag with inherited animation settings and the session override. It
also checks live changes, returning to device settings and observer disposal.
Jev `jev-latest` selected the existing state observer route with 0.94 confidence.
The retained Flutter animations v2.0 guide, installed SDK source and current
Context7 lookup informed the preference integration. All 81 tests pass, all
eight production files have 1044/1044 covered lines without exclusions, analysis
reports No errors, and formatting passes. The candidate arm64 native build
passed with exit 0.

Native candidate verification then passed in the separate fixture, whose
installed Dart kernel fingerprint matched the candidate build. The actual iOS
Reduce Motion switch changed on and off while Follow device settings remained
selected, and effective Home reduced motion changed true and false in the same
process. With the device setting off, the session override changed effective
motion true, and returning to Follow device changed it false. After enabling
the session override again, restarting only the fixture changed PID 33752 to
44760 and restored Follow device selected, session override unselected and
effective reduced motion false. The manual preference was not persisted.

Screenshots and actual native AX records are in `evidence/ticket13b/`, including
`candidate-system-on-follow-device`, `candidate-live-system-off-follow-device`,
`candidate-session-on-device-off`, `candidate-session-off-device-off`, and
`candidate-restart-follow-selected`. The iOS switch was restored off; original
`com.example.reports` preference/support file hashes stayed unchanged. No City
requests, haptics, persistent preference or automatic sends were added. The
synthetic fixture cannot prove a live Submission. Stronger step/page motion,
the continuation hint and the complete report-journey demonstration remain
pending, so this ticket stays open.

2026-10-22, 13c: report steps and routes now move vertically by 64 logical pixels with a 400 ms fade, and step changes reset scroll to the top. The Home hero remains stationary and unchanged in size. System and session reduced motion remove this movement.

The restored resident journey first failed with zero vertical route travel, then passed five transitions across normal/system/session modes while retaining Review values and the Home hero geometry. Dart MCP focused and complete tests pass (83 tests); all production files have 1104/1104 covered lines without exclusions. Dart formatting changed zero files and analysis reported No errors. Direct Xcode arm64 simulator compilation passed after restoring the missing CocoaPods Manifest.lock with pod install; the deployment target 15 override is retained. Raw JSON is in reports/.scratch-motion-{red,green,full}.json; exact source hashes and coverage are in evidence/ticket13c/retry-source-manifest.json and retry-coverage.json. No fixture was installed over the original bundle, no City requests were sent, and native interaction is reserved for integration verification. The <=5px continuation hint remains a separate 13d cycle.

2026-10-22, 13d: a static five-logical-pixel bottom gradient, at most 8% black opacity, indicates remaining report content and disappears at the end. It stays static under normal and reduced motion. The meaningful resident test failed first because no cue existed, then passed cue size/alpha/stationary geometry/end/reappearance assertions. Dart MCP focused and all 84 tests pass, all production files total 1131/1131 covered lines without exclusions, formatting passes and analysis reports No errors. Raw results: reports/.scratch-hint-{red,green,full}.json; candidate hashes and coverage: evidence/ticket13d/source-manifest.json and coverage.json. Native build and UI verification for this pure Dart presentation slice are defined in the combined ticket26 native gate. No City writes, haptics, preference persistence, or receipt changes.

### Accepted resolution

Accepted commits: `dfd2383`; native system/session preference integration: `97a89e4`. Raised presses, vertical transitions and the five-pixel continuation hint are accepted with retained Home proportions and reduced-motion behavior. Actual iOS Reduce Motion on/off and restored-setting records: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket13b/candidate-ios-setting-on.ax.txt](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket13b/candidate-ios-setting-on.ax.txt) and [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket13b/candidate-ios-setting-restored-off.ax.txt](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket13b/candidate-ios-setting-restored-off.ax.txt). Native normal/reduced delivery captures: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-normal.mp4](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-normal.mp4) and [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-reduced.mp4](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/preflight/.scratch/illegal-dump-reporter/evidence/ticket25/native-delivery-reduced.mp4). Only exposed runtime settings are reported; no unexposed fast service tier is claimed.

Root review accepted all criteria for this issue on 2026-10-22; this acceptance supersedes earlier pending notes. The combined final26 code gate passed under TZ=Asia/Tokyo: 121 tests, 0 skipped, 1884/1884 covered lines across all 13 production files, no exclusions and stable source hashes; formatting 32 files/0 changes, analyzer No errors. Exact existing gate records: [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/full-tests-result.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/coverage-summary.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/format.json), [/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json](/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/evidence/worktrees/integration/.scratch/illegal-dump-reporter/evidence/ticket26/analysis.json). Final26 native build/UI acceptance remains pending; this issue's resolution does not mark 26 done. No City write was performed; original native-send evidence gaps 01/04/09 remain unresolved.
