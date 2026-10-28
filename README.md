# Reports

A Flutter app for reporting illegal dumping to MyLA311.

- `reports/`: native app, organized into app composition, shared design, and Report, Home and Dev/API features.
- `animation/`: the authored submission animation project.
- `design-prototype/`: interface references and artwork.

The [canonical v2 design](design-prototype/reports-prototype-buttons-v2.html)
extends the existing layout to all 68 advertised services. Start a Report opens
the service catalog; the gear opens Settings with account tools. Nearby and
saved reports use contextual actions. There is no bottom navigation bar.
OpenDesign copies follow this repository file. Prototype activity stays local;
the native app currently sends illegal-dumping reports only and still needs
the additional catalog, account and Nearby pages.

The app supports drafts, photos, map search, submission recovery and saved receipts. Submissions use the city's live system.

Run Flutter commands from `reports/`.

Developer tools use the `REPORTS_DEV_MODE` build flag. It defaults to enabled in
debug builds and disabled in profile and release builds. Pass
`--dart-define=REPORTS_DEV_MODE=false` to hide them in debug, or
`--dart-define=REPORTS_DEV_MODE=true` to explicitly enable them in another build.
The HTML design preview hides its developer playground unless opened with
`?dev=1`.

Project guidance lives in [AGENTS.md](AGENTS.md) and the [glossary](GLOSSARY.md).
The [specification](.scratch/illegal-dump-reporter/spec.md) and
[tickets](.scratch/illegal-dump-reporter/issues/) retain the project decisions
and implementation records. See the [agent workflow](docs/agents/issue-tracker.md)
for local issue tracking and the [Portal API reference](docs/portal-api.md)
for the submission contract.
