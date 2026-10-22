# 03: Submit a Report to the city

**What to build:** A resident takes an optional photo, confirms their
location, describes the dumping, and taps Submit. The app saves the Report
first, sends it to the city through the Portal's own API using the doc from
ticket 01, shows progress, then shows the Service Request number. The Report
is stored as submitted. Submit stays disabled until the details the city
requires are present. The old clipboard-and-browser handoff is deleted with
its code. One Submission client hides session setup, photo upload, and
submit. Happy path only. A widget test runs the flow against a stand-in
connection built from the doc's examples.

**Blocked by:** 01: Portal API doc; 02: Illegal-dumping-only Report.

**Status:** resolved (implementation); live-send proof remains blocked in 04

- [x] Submit sends the Report through the one Submission client and the
  Service Request number appears on screen. (`test/submit_flow_test.dart`
  happy path against a fake client; the real client is
  `lib/src/portal_submission_client.dart`, covered by offline transport tests.)
- [x] The Report is saved before sending and stored as submitted on success.
  (The attempt marker precedes dispatch; accepted results retain the official
  receipt. The happy-path test reads the stored Report.)
- [x] Submit is disabled until the required details are present. (Test covers
  location, description, debris location and quantity.)
- [x] The clipboard handoff and the browser launch are deleted. The unused
  `url_launcher` dependency was also removed.
- [x] A widget test of the happy path passes against the stand-in, and the
  analyzer is clean. Current counts are tracked by ticket 08.
- [x] The work is reported as unverified against the city until ticket 04.
  (A historical helper recorded C-04955177, but original native-screen send
  provenance was not preserved. Do not send again to fill that evidence gap.)
