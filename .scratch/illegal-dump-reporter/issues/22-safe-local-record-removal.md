# 22: Remove a local Draft or confirmed Receipt safely

**What to build:** a resident can remove an unfinished Draft or a confirmed local Receipt while clearly understanding that local removal does not cancel a City Service Request. Trace: Q8.

**Blocked by:** 14: Continue an unfinished Draft after reopening the app.

**Status:** resolved

- [x] Provide clear local-removal actions for an unfinished Draft and a confirmed Receipt, preserving other saved Reports, durable attachments that remain in use, and exact retained SR values.
- [x] The removal outcome survives reopening. Local removal never calls a City cancellation endpoint or changes the City's record, and its presentation clearly states that it does not cancel a Service Request.
- [x] Unconfirmed attempts and protected markers cannot be removed to unlock another send. Preserve uncertain-attempt protection and prove that permitted removal cannot allow a duplicate dispatch.
- [x] Verify removal, reopening, unaffected records, and protected-attempt behavior with labeled synthetic data. Keep anonymous illegal-dumping submission through the real native client intact; no City writes or historical live-send helpers are allowed.
- [x] Add no automatic/background retry queue, haptics, persistent manual motion preference, contact flow, or other issue types. Honor system/session reduced motion wherever motion is introduced.
- [x] Implement one behavior per test-first burst and scoped Conventional Commit, run meaningful checks, maintain 100% production line coverage without exclusions, and preserve the original native-send evidence gap honestly.

## Evidence

Six independent labeled synthetic resident cases cover cancel, failed Draft removal, failed Receipt write, successful Receipt deletion/restart with hidden matching Draft suppressed, unfinished Draft discard/restart, and protected uncertain attempts. A separate storage case preserves a leftover durable attempt marker after Receipt deletion and proves that another dispatch stays blocked. Other rows, exact retained C-04955177, and shared photo bytes remain unchanged. No City request, cancellation, photo deletion, or historical send helper ran. Dialog honors reduced motion; History/detail use the continuation hint.

The required gate found and corrected an AppBar overflow at 320px/doubled text, then a shifted map drag target. The final Discard draft action sits below the step content. Formatter passed. Dart analyzer: No errors. Focused command `rtk proxy flutter test test/platform_flow_test.dart test/report_storage_test.dart test/location_map_test.dart --name 'local|unfinished Draft|failed Draft|failed Receipt|review remains readable|resident chooses a map point'` exited0,11 tests passed.

Final full command, run from `reports/` with stable repository TMPDIR:

```sh
rtk proxy flutter test --coverage --concurrency=1 test/
```

Raw final output: `00:51 +102: All tests passed!`, exit0. LCOV: **1340/1340 production lines, all10 files, no exclusions**. Source manifest matched after completion: true. Raw logs and exits: `evidence/worktrees/draft/.scratch/illegal-dump-reporter/evidence/ticket22/geometry-full.log`, `.exit`, `geometry-focused.log`, `.exit`; LCOV retained as `geometry-lcov.info`. Earlier failed gates are preserved separately and superseded. Native synthetic removal/restart proof joins ticket26; historical native-send evidence gap remains.

Source-bound SHA-256:

```json
{
  "reports/lib/src/storage.dart": "afc8344b6f850ec1e76c6a51900e7a6474d1a34806a01186e6cf55c62dee8f21",
  "reports/lib/src/history_page.dart": "8a6ef6df5eef9f3345f7f0cd55b128467dd53f1b35fac6ee7ae845ca84c4e4bc",
  "reports/lib/src/mobile_report_flow.dart": "d7366f0419abf194f6dc1cd89cef7e00b4a1ffee4066ae64467280592377c5ce",
  "reports/lib/src/local_record_removal.dart": "80c54948a4f934b3f8c33c9a6ca48f6a77401ce0e0e28a9347c9860c8833deef",
  "reports/test/platform_flow_test.dart": "262576eaaa6cdd8669e36abbe55300ddd21f0edf8416739bbac1bf3a2aafe06a",
  "reports/test/report_storage_test.dart": "b1b6f95a1646cff6ec9b8b131b15dc7daab631dea2b344179d12032a251db4c9"
}
```

## Comments

Resolved after strict source commit `b0f17d7`, reviewed integration port, and native controlled-fixture proof. Standalone final command `rtk proxy flutter test --coverage --concurrency=1 test/`: exit0, raw `00:51 +102: All tests passed!`, **1340/1340** production lines without exclusions. Merged ticket26 final command with expanded/json reporters: exit0, raw `01:29 +121: All tests passed!`, **1884/1884** production lines across13files without exclusions; pre/post source hashes identical in integration `evidence/ticket26/full-tests-result.json`.

Native proof binds frozen source `b0f17d773749b6cc5abface686d6238a8c36a4d4` on iPhone18Pro `C4E392DE-D493-40CD-881A-2F6729C93E45`, isolated bundle `dev.regis.reports.flow26.fixture`. Final native build, signing, verification, and install all exit0. Local Receipt removal showed the explicit no-cancellation notice, removed its hidden matching Draft first, and survived a genuine process restart: no Continue draft or removed row, exact retained `SR-SYNTHETIC-NATIVE-KEEP` and all3photo files/bytes intact. A separate unfinished Draft was restored after process restart, discarded through the production confirmation dialog, and remained absent after another process restart. Unconfirmed flow and History exposed no Submit/Retry/Discard/Remove/Correct actions; marker bytes remained identical across restart/navigation and no client methods ran. Permitted Receipt removal never removes protected markers, independently tested by the leftover-marker storage regression.

Original `com.example.reports` preferences SHA before/after: `369632069f6eebfa903ab68965e1074b2b69cf2b61e9f54dfe92ebeb9ebb7c19` (identical). All12 derived native checks are true. Source hashes, kernel SHA, framework IDs, raw RPC01..33, before/after marker/original-data captures, and inspected native PNGs are indexed at `evidence/worktrees/draft/.scratch/illegal-dump-reporter/evidence/ticket26/native-flow-proof.md` and `.json`. Real production PortalSubmissionClient ran with every HTTP request intercepted by MockClient, including explicit known-NotSent correction/Retry with3attachments, anonymity=true and one original row. These labeled synthetic proofs made no City write, cancellation, photo deletion, actual phone call, or historical live-helper invocation. The historical real-native-send evidence gap is unchanged.
