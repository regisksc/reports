# 15: Choose the dumping location with an interactive map pin

**What to build:** A resident can find and confirm the dumping location through the prototype-style map and adjustable pin, then see that actual location in Review and the real submission client's payload. Trace: Q1.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Select an appropriate Flutter map package/provider after current compatibility checks. Preserve the prototype's address/intersection, map movement, pin, zoom, and current-location interactions where supported by the agreed flow.
- [x] The selected coordinates become the Report's actual location and feed the real City's validation and submission contract, rather than only changing preview artwork.
- [x] Review reflects the selected location. Permission and network failures remain understandable without manufacturing a valid City location.
- [x] Extend the documented coordinate contract; a new API investigation is not a blanket prerequisite for displaying or adjusting the map.
- [x] Verify selection through Review and the outbound real-client payload with controlled tests and no City write. Preserve the direct edit-return contract when editing the location from Review.
- [x] Preserve anonymous illegal-dumping scope (Q18), native submission through the real client, confirmed Reports and exact SR numbers, durable attachments, and uncertain-attempt markers across restart. Add no other issue type or contact/login flow.
- [x] Create no City write or second Service Request, and never execute historical live-send helpers. Label controlled fixtures explicitly synthetic; they cannot prove a live Submission. Tickets 01, 04, and 09 retain unresolved original native-send proof gaps without blanket-blocking this improvement.
- [x] Introduce no automatic/background send queue, automatic retries, haptics, or persistent manual motion preference. Honor system/session reduced motion wherever motion changes.
- [x] Implement one behavior at a time: a meaningful failing test, the minimal code change, relevant formatter/lint/analysis/test/build checks, then one scoped Conventional Commit. Preserve 100% production line coverage with no exclusions.
- [x] Future execution uses a management-only GPT-6.1 Sol/ultra orchestrator and GPT-6.1 Sol/high implementers, with fast tier requested. Use the maximum genuine parallel frontier with disjoint ownership and serialized Git mutations. Record exposed runtime settings; do not claim fast tier was applied without evidence.

## Comments

### 2026-10-22: first map-point behavior candidate

- Production Location UI now renders `flutter_map` 8.3.2 with OSM raster tiles,
  adjustable tap/center pin selection, panning, zoom controls, visible attribution,
  native caching, and the existing GPS action. Jev selected this approach after
  fresh Dart MCP package discovery and Context7 compatibility/API checks.
- One new controlled scenario drives map interactions through Review and the
  real Portal client's injected HTTP boundary. Exact selected coordinates reach
  `validateAddress` and outbound Case coordinates. All responses and the resulting
  SR are explicitly synthetic; no City request or historical helper is executed.
- Initial meaningful red: the native Location screen contained no `FlutterMap`.
  After implementation, full suite 78 tests passes, with 918/918 production lines
  and no exclusions. Analysis is clean; formatter reports 17 files, zero changes.
  The Dart MCP coverage argument added a spurious positional test path; approved
  CLI fallback produced the successful full coverage run.
- Explicit iOS simulator arm64 `xcodebuild` succeeds after local `pod install`.
  The iOS 15.0 pod override is preserved. Existing plugin deprecation warnings
  remain in the native log. The tracked Podfile.lock is restored to its original
  bytes after the build; generated local Pods are retained.
- Flutter widget tests block real tile HTTP and exercise the displayed tile
  connection error. Package OSM-policy notices and synthetic 400 tile diagnostics
  appear in test logs; no live OSM or City requests occur in the automated checks.
- Shared-flow edits are limited to the import, Location description, and
  `_locationStep()` UI/selection callback. Constructor, Draft lifecycle/storage,
  navigation, and submission implementation remain unchanged. Original tickets
  01–10 and their native-send evidence gaps remain untouched.
- See the coordinate/provider notes below and
  `.scratch/illegal-dump-reporter/evidence/ticket15/map-point/` for full checks.
  Address/intersection lookup is the next ticket15 behavior after this scoped
  candidate passes root's configured review and commit. The later direct edit
  return belongs to ticket18. Ticket15 is not complete yet.
- Root owns serialized Git, review, and integration. Requested worker model policy
  is GPT-6.1 Sol/high; service tier is not exposed and fast tier is unverified.

### Provider, coordinate, and test-isolation notes

- `flutter_map` 8.3.2 and `latlong2` 0.9.1 resolve against Dart 3.11.4. Current
  pub.dev discovery and official package/API sources informed the choice. Jev
  selected the pure Flutter map over an Apple Maps plugin whose retrieved
  compatibility reference was stale. Sources:
  [flutter_map](https://github.com/fleaflet/flutter_map) and
  [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/).
- The initial City Hall camera is orientation only, with no selected Report
  location. Panning/zooming changes the view; tapping or Use map center selects
  coordinates. Full double precision reaches the Report and the real client's
  `validateAddress` input (`City Boundary`, empty filter). Review shows six
  decimals. The City's returned address X/Y govern outbound Case coordinates
  and its full address attributes become `addressDetails`. Existing client
  address-entry metadata is unchanged in this slice. Map choices remain visibly
  unverified until the real City's validation succeeds.
- Native tile caching retains flutter_map's HTTP-header-aware default, app
  User-Agent identification is `org.regisksc.reports`, and the explicit HTTP
  client adds no automatic retry wrapper. No bulk/offline download, background
  prefetch, submission retry, queue, or motion preference is introduced. Camera
  controls move directly and do not introduce programmatic animation.
- `test/flutter_test_config.dart` initializes only a per-suite cache directory
  under ignored `.dart_tool/`. `readOnly:true` prevents synthetic test tiles from
  being persisted; an empty isolated cache still performs the same network path.
  `maxCacheSize:null` avoids a test fixture size-reduction policy. Destruction
  removes only that generated fixture. It does not mock/suppress assertions,
  framework exceptions, tile errors, test results, or production caching. Flutter
  itself blocks test HTTP with 400; the visible error is retained and exercised.
- Original provider/proof note preserved in ignored evidence as
  `ticket15/map-point/location-map-notes.md`; no new standalone documentation
  file remains. Simulator runtime inspection is pending the exclusive native
  slot; successful build is not claimed as simulator UI evidence.

### 2026-10-22: attribution review correction

- Checked the primary [OSMF Attribution Guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines),
  including Requirements, Attribution text, and Interactive maps. The guidance
  requires accessible origin/licence information when it is absent from the
  attribution, identifies the copyright page link as a suitable route, and
  requires an easily located licence link when the attribution cannot link.
  The existing plain URL lacked that access, so the map now has a permanently
  visible, tappable attribution opening the official copyright page.
- `url_launcher` 6.3.3 resolved with iOS implementation 6.4.2 after current
  package/API checks. The action opens only that fixed HTTPS licence URL on
  explicit tap. A failed/throwing launch shows the URL and a clear error. It is
  unrelated to reporting dispatch; the native client remains the only send path.
- Existing single map journey now also checks the real attribution action via
  the platform boundary, including success, false result, and thrown failure.
  Initial red proved there was no tappable attribution. All browser launches in
  tests are synthetic, and no browser or simulator interaction was performed.
- Final corrected candidate: 78 tests pass, **929/929 production lines** with no
  exclusions; clean analysis, 17 formatted files with zero changes, and clean
  `git diff --check`. Fresh explicit arm64 native build succeeds with the
  launcher plugin installed. Tracked Podfile.lock already includes the required
  native entries and is byte-identical to HEAD after this final build. Final
  logs are `full-tests-attribution.log`, `pod-install-attribution.log`,
  `native-arm64-build-attribution.log`, and `gate-summary-attribution.json`.

### 2026-10-22: address/intersection search candidate

- Added explicit Search and keyboard-search actions to the existing native map
  component. `geocoding` 5.0.0 uses the iOS geocoder through Darwin 1.0.3, with no
  provider key or new permission flow. Current official APIs were checked using
  Context7 and the installed package source; Jev selected this native lookup
  over widening the shared Portal client for another Aura session chain.
  Primary source: [geocoding package](https://github.com/Baseflow/flutter-geocoding/tree/main/geocoding).
- Queries are scoped with `Los Angeles, CA`. The first returned point becomes
  the same selected location used by map pin adjustment, Review, and the real
  client. No match and lookup failure show distinct clear messages without
  inventing coordinates. Selection remains labeled not City verified; the real
  City validator still controls outbound normalized address coordinates.
- Pending lookups cannot replace a newer map/GPS choice or update the Report
  after leaving Location. There is no automatic lookup, retry, queue, or send.
  Searches are explicit; a person can still select a map point while one is
  pending. Existing motion, anonymous contact, attachment, and receipt behavior
  is preserved. No shared flow or main/lifecycle/persistence source is changed.
- One new resident scenario begins with the missing search field red, then
  drives empty input, loading, no match, network failure, stale result rejection,
  an intersection result, and leaving Location before a late completion. It
  follows the selected point through Review and the actual Portal client with
  controlled synthetic HTTP, asserting full-precision validation and outbound
  coordinates. Native geocoder responses and the SR are synthetic fixtures.
- Fresh full serial suite: **80 tests pass, 997/997 production lines**, no
  exclusions. Analysis is clean; formatter reports 18 files with zero changes.
  Initial concurrent run hit its 120-second process cap without a functional
  assertion failure; serial execution completed in 94 seconds with all gates
  retained. Earlier LCOV was explicitly treated as stale until that run passed.
- Local pod installation and explicit arm64 iOS simulator build pass with the
  new Darwin dependency and the iOS 15.0 deployment override preserved. Runtime
  simulator interaction remains reserved to the Draft task, so this is build
  evidence, not an observed native search result. No City read/write, historical
  live-send helper, external message, or simulator interaction was performed.
- Evidence: `.scratch/illegal-dump-reporter/evidence/ticket15/address/`, including
  original red output, both full test attempts, fresh coverage/check summary,
  pod log, and native build log. Root owns review, scoped commit, and integration.
- Draft integration adapter: `LocationMap.onSelected` emits the exact point
  immediately for successful search, map tap, and Use map center. The parent
  location callback must persist that changed point immediately, including a
  departure from Location before Continue. Draft owns that persistence adapter;
  it is an integration requirement, not a new prerequisite for this behavior.
  Ticket18 retains direct edit-return behavior, and final native verification
  remains ticket26. Original tickets01/04/09 proof gaps stay unresolved.

- 2026-10-22 acceptance: reviewed map/address changes77b34c3/2c58cc4 preserve actual coordinates and City validation. Reviewed18 (bab0dbb →6bab597) proves Edit Location → Save changes → Review34.060000,-118.250000 and the same controlled PortalSubmissionClient payload. Native address/intersection/OSM evidence: worktrees/photo/.scratch/illegal-dump-reporter/evidence/ticket15. Formatter/analyzer/focused/full gates passed. All criteria inspected; combined native regression remains26. No City write.
