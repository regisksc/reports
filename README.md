# Reports

A Flutter app for reporting illegal dumping to MyLA311.

- `reports/`: native app, organized into app composition, shared design, and Report, Home and Dev/API features.
- `animation/`: the authored submission animation project.
- `design-prototype/`: interface references and artwork.

The app supports drafts, photos, map search, submission recovery and saved receipts. Submissions use the city's live system.

Run Flutter commands from `reports/`.

Developer tools use the `REPORTS_DEV_MODE` build flag. It defaults to enabled in
debug builds and disabled in profile and release builds. Pass
`--dart-define=REPORTS_DEV_MODE=false` to hide them in debug, or
`--dart-define=REPORTS_DEV_MODE=true` to explicitly enable them in another build.

Project guidance lives in [AGENTS.md](AGENTS.md) and the [glossary](GLOSSARY.md).
The [specification](.scratch/illegal-dump-reporter/spec.md) and
[tickets](.scratch/illegal-dump-reporter/issues/) retain the project decisions
and implementation records. See the [agent workflow](docs/agents/issue-tracker.md)
for local issue tracking and the [Portal API reference](docs/portal-api.md)
for the submission contract.
