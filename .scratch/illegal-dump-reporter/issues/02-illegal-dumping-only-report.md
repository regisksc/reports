# 02: Illegal-dumping-only Report

**What to build:** The app is about illegal dumping only. The category picker
and the other eight Issue Types are gone. A Report records location,
description, optional photo, created time, a submission state (not sent,
submitted, failed), and the Service Request number. The stored shape changes,
so the storage key is bumped and old rows are discarded (no real users yet).
The home copy says illegal dumping only. The app's connection to the Portal is
replaceable at the app root, so tests can swap in fake responses. The
glossary's Issue Type entry is updated to match.

**Blocked by:** None. (Relaxed by the orchestrator: this ticket needs no
Portal API facts. The Portal connection is only an interface at the app
root, fixed in
`/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/client-interface.md`.
Original blocker: 01: Portal API doc.)

**Status:** resolved

- [x] No Issue Type choice anywhere in the app, and the eight unused types are
  deleted.
- [x] Report carries state and Service Request number, and old stored rows are
  ignored without crashing.
- [x] The app root accepts a replaceable Portal connection, and the shipped
  app uses the real one. (`ReportApp(client:)` defaults to
  `PortalSubmissionClient()`; the Wave 2 client replaced the stub.)
- [x] Home copy says illegal dumping only.
- [x] The glossary matches the app.
- [x] The app builds and runs, and the existing smoke test passes.

Result: fresh merged-app tests, analysis, and formatting pass. The real native
app built and ran on the specified simulator. Home, history, and the report
form were inspected without sending a City request. Native evidence is retained
under `evidence/native-final-580c693/`; ticket 08 records final verification.
