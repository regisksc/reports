# 08: Complete verification gates

Status: resolved
Blocked by: 03, 06

## Acceptance

- Full production line coverage is 100%, measured from LCOV without ignored files or coverage pragmas.
- Existing home/history/photo/camera/location behavior is exercised through public app and platform boundaries. Each test title states exactly what its assertions prove.
- All tests pass, Dart analysis is clean, Dart formatting is clean, and the real native entrypoint builds for the specified iOS simulator.
- Remove unused handoff dependencies and separate unused fake/live-send tooling from the deliverable, preserving historical evidence. Never run a live-send tool.

## Comments

Baseline: 31 passing tests, 464/486 covered production lines, 10 Dart files requiring formatting. Ownership is split in ketchup-plan.md to avoid overlaps.

## Current milestone status

Verified source: `cf64b2d86ddeb00b8f2c9e527aee8ec2ed1dacaa`.

- Fresh final Dart MCP full suite: 61 tests passed, no City requests.
- LCOV: 605/605 production lines, no exclusions or coverage pragmas. Six
  production files are measured, including the real entrypoint and client.
- Dart MCP analysis: no issues. Formatter: 11 files, zero changes.
- Native iPhone 18 Pro build/run passed. All eight source/dependency hashes
  match committed objects. No runtime errors; home, history, and the blank
  report form were inspected without submission.
- Hosted native permission XCTest: one test passed, zero failures, exit 0.
- Independent final Standards and Spec reviews: zero remaining actionable
  findings after the camera-photo retention and GPS navigation repairs.
- Original source, obsolete interface module, and historical live-send tools
  are archived under `evidence/original-workspace-20261022/`. No historical
  helper was executed. Unused handoff dependencies are removed.

Evidence: `evidence/final-verification/lcov.info`,
`evidence/native-final-camera-gps/native-final-result.json`,
`evidence/native-final-camera-gps/committed-source-comparison.json`, and
`evidence/native-final-580c693/native-permissions-serial-result.json`.
The iOS scaffold is unchanged between the native test and final app build.

These checks verify the implementation. Original native-send proof and current
City read-back remain blocked under tickets 01, 04, and 09. No second request
was created.
