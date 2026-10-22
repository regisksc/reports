# Illegal dump reporter: send real Submissions to MyLA311

Status: blocked (original native-send proof)

This spec retains the original challenge baseline. The current native milestone
and later amendments appear under Further Notes. The functionality and motion
interview below records proposed changes only, not implemented behavior or
authorization to implement them.

## Problem Statement

A resident who sees illegal dumping in Los Angeles has to use the MyLA311
Portal, a web app that is awkward on a phone. At the original challenge baseline,
the app copied a summary to the clipboard and opened the Portal, so the
resident still filed the report by hand. It also offered nine Issue Types when
the goal was illegal dumping only.

The point of the app, and of the interview challenge it comes from, is a
native mobile app that does exactly what the Portal does, over the Portal's
existing non-public APIs, so the resident never touches the web app. At that
baseline, browser network discovery had not been attempted, and one guessed URL
returning 404 was wrongly taken as proof that no API existed. The native client
and API reference now exist; the original native-send evidence gap remains.

## Solution

Understand the Portal's API first: drive the illegal-dumping flow in a real
browser with network capture and record every call it makes. Then make small,
targeted changes to the existing app. A resident takes a photo (optional),
confirms their location, describes the dumping, and taps Submit. The app saves
the Report on the phone, sends it to the city through the Portal's own API,
and shows the Service Request number the city returns. If sending fails, the
app says why and keeps the Report so the resident can retry. Nothing else
about the app grows.

**Done** means the app itself performs the whole job against the real city
system. A mock, a clipboard handoff, or opening the browser is not done.

## User Stories

1. As a resident, I want to report illegal dumping from my phone in under a
   minute, so that I do not fight the Portal on a small screen.
2. As a resident, I want the app to be about illegal dumping only, so that I am
   not asked to pick from categories that do not apply.
3. As a resident, I want to take a photo of the dumped items, so that the city
   can see what needs to be picked up.
4. As a resident, I want the photo to be optional, so that I can still report
   when I cannot take one safely.
5. As a resident, I want the app to use my current location, so that I do not
   type an address.
6. As a resident, I want to see where the report will be placed, so that I can
   confirm it is the right spot before sending.
7. As a resident, I want a clear message when location permission is denied, so
   that I know what to change in settings.
8. As a resident, I want to describe the dumping in my own words, so that
   crews know what to expect.
9. As a resident, I want Submit disabled until the details the city requires
   are present, so that I never send a report the city will reject.
10. As a resident, I want to see progress while the Report is sent, so that I
    know it is working.
11. As a resident, I want the Service Request number after a successful
    Submission, so that I have proof the city received it.
12. As a resident, I want a clear reason when the city rejects the Report, so
    that I can fix it.
13. As a resident, I want my Report kept on the phone when sending fails, so
    that I do not lose my photo and description.
14. As a resident, I want to retry sending a failed Report, so that a bad
    connection does not cost me the report.
15. As a resident, I want the app itself to send the Report and never hand me
    off to a browser, so that reporting is one app and one flow.
16. As a resident, I want My reports to show which Reports were submitted (with
    their Service Request numbers) and which were not sent, so that I know what
    the city has.
17. As a resident, I want to see an older Report's photo, description, and
    status, so that I can refer back to it.
18. As a resident, I do not want to create an account, so that reporting stays
    quick.
19. As a developer, I want the Portal's API contract written down from real
    captured traffic, so that the client is built from evidence.
20. As a developer, I want discovery to stop before the final submit, so that no
    accidental real Service Request is created.
21. As a developer, I want the Submission client behind one interface, so that
    tests can replace it with recorded responses.
22. As a developer, I want tests that replay the captured API responses, so that
    the flow is verified without calling the city.
23. As the candidate, I want exactly one real Submission, sent on a real
    dumping location I supply, so that no false report reaches the city.
24. As an interviewer reviewing the work, I want to see the reverse-engineering
    evidence (captured calls and how the session is established), so that I can
    judge the central technical task.
25. As a developer, I want the other eight Issue Types, the clipboard handoff,
    and unused code gone, so that the app matches the goal and nothing is
    over-built.

## Implementation Decisions

These are the original baseline decisions. Later recovery amendments and the
current milestone below take precedence over the original storage and flow
descriptions. Interview intentions remain proposals until separately authorized.

- **Phase order is a hard gate.** Phase 1 is API discovery. Phase 2 is the
  targeted app changes. No Submission code is written until the contract note
  from phase 1 exists.
- **Discovery method.** Drive the illegal-dumping flow on the live Portal with
  Playwright MCP, filling every form step, uploading a photo, and choosing a
  location, while recording the network with Chrome DevTools MCP. REA's
  browser-capture tools are the alternative. Plain HTTP fetches and guessed
  endpoints are not discovery.
- **Speed.** No time box, but go fast: capture the happy path, write it down,
  then report the captured submit request or the exact blocker.
- **Stop before the final submit.** Discovery walks the flow up to the submit
  step and no further. The one real Submission belongs to the live-send
  ticket, on a real dumping location the user supplies.
- **Contract note.** A markdown endpoint reference for agents, Swagger-style,
  happy path only, with personal data redacted. Per endpoint: method, URL,
  headers, body, response shape, and a redacted example. It covers how a
  session or guest context is established (tokens and context ids and where
  they come from), the location or address lookup calls, the photo upload
  calls, the submit call, and the Service Request number in the response.
- **Nothing about the API is assumed.** Endpoints, tokens, and platform
  details are findings of phase 1 only. Earlier guesses count for nothing.
- **If the API cannot be called from outside a browser,** record the blocker
  with evidence and ask the user how to proceed. A mock or a browser handoff is
  never reported as done.
- **Submission client (new module).** One interface: send a Report, get back a
  Service Request number or a typed failure (rejected with a reason, network
  down, session expired). It hides session setup, photo upload, and submit. It
  has no retry loops, and recovering from an expired session is optional. It
  uses the HTTP dependency already in the project.
- **Report.** Keeps location, description, optional photo, and created time.
  Drops Issue Type selection. Gains a submission state (not sent, submitted,
  failed) and the Service Request number. The stored shape changes, so the
  storage version is bumped and old rows are discarded: there are no real users
  yet, so no migration.
- **Issue Type.** The user-facing choice and the list of nine are removed. The
  single illegal-dumping request type the Portal requires becomes a constant
  inside the Submission client.
- **Report flow.** One screen: photo, location, description, Submit. It always
  saves the Report first, then calls the Submission client, then shows the
  result. On failure it shows the reason, keeps the Report, and offers retry.
  The button says Submit.
- **No handoff.** The clipboard-and-browser handoff is deleted with its code.
- **My reports.** Shows each Report's state and Service Request number. No
  editing or deleting.
- **Home screen.** Copy says illegal dumping only.
- **Test seam.** The app root accepts the Portal connection as a replaceable
  part, so tests can plug in recorded responses. The shipped app always uses
  the real connection.

## Testing Decisions

- A good test drives the app as a resident would and asserts what they see and
  what is stored. It does not assert which internal calls were made.
- **One seam: the app's connection to the Portal,** replaceable at the app
  root, the highest point available. Widget tests run the whole app against
  recorded responses captured in discovery.
- Passing tests never count as done. Done needs one live send performed by the
  app on the simulator, driven by an agent.
- Scenarios: the happy path is the priority (photo, location, description,
  Submit, Service Request number shown, Report stored as submitted). Cheap
  extras once it works: a failed send keeps the Report as not sent and offers
  retry; Submit disabled until required details exist; My reports shows state
  and number. Skip a full failure matrix.
- Prior art: the existing widget smoke test, which pumps the app root. Extend
  that style, stubbing camera and location. The smoke test keeps passing.
- Discovery has no automated test. Its gate is that the contract note exists;
  the redacted examples in it feed the stand-in connection. Automated tests
  never call the live Portal.

## Out of Scope

These are the original baseline exclusions. The interview below proposes limited
local removal and reopening for a later scope; it does not authorize those app
changes yet.

- Any Issue Type other than illegal dumping.
- Accounts, login, and push notifications.
- Status tracking of a Service Request after Submission.
- Editing or deleting Reports, and an offline send queue.
- Android, App Store polish, and other cities.
- A browser or clipboard handoff in any form.

## Further Notes

- **Current milestone:** the real native app implements the reporting flow and
  persisted delivery recovery. Ticket 08 records final automated and native
  checks. Tickets 01, 04, and 09 retain the original submission evidence gap;
  a helper recorded C-04955177, but original native-screen send provenance was
  not preserved. Do not create another City request to fill that gap.
- **Delivery recovery amendment:** retry applies to known pre-submit failures
  and explicit rejections without a possible receipt. After dispatch, a lost,
  invalid, or contradictory reply is Submission unconfirmed and blocks sends
  across ordinary app/process restart. A corrupt attempt marker also blocks
  dispatch. Preserve confirmed receipts and legacy `reports_v2` rows. See
  tickets 07 and 08 and client-interface.md Amendment 2.

- Playwright MCP and Chrome DevTools MCP are configured for this repo in the
  project MCP config. They load the next time Claude Code starts in the repo.
- Calling a city portal's internal API may conflict with its terms of use.
  The challenge asks for it; check before any public release.
- Vocabulary comes from the glossary. If Issue Type stops being a user-facing
  concept after this work, update the glossary to match.
- Tickets for this spec are local markdown, one file per ticket under the
  issues folder beside this spec, maintained by agents. No external tracker.
- The repo brief describes the same order of work and the iOS run and build
  gotchas.

## Functionality and motion interview, 2026-10-22

### Boundary and inspected references

- **Interview only.** Record intentions now. Do not change the app, install
  packages, run API investigations, or send City requests during this interview.
  The intended presentation is by email; extended hands-on demo features are not
  a priority.
- Inspected the current native UI and saved OpenDesign Cloud prototype
  `reports-prototype.html` in local project
  `74204d10-326c-44f9-b11a-7d9401baa491`, checking its inline runtime during the
  interview. The OpenDesign connector was unavailable;
  findings refer to the saved local prototype, not a confirmed newer cloud state.
- The prototype already has an interactive map, resumable draft, photo removal,
  Review page, and direct return to Review after an edit. Its demo receipts and
  material choices do not establish City API capabilities or accepted submissions.
- The native app currently has five steps: Location, Items, Photos, Details,
  Review. It uses GPS and one optional camera photo. The prototype additionally
  has optional Contact and up to three photos. The intended native scope keeps
  anonymous reporting and targets three optional photos, subject to later City
  API verification.

### Decision ledger

Question numbers refer to the interview rounds. Agreed below means an agreed
intention, not authorization to implement. Later answers supersede earlier
proposals where noted. Keep this ledger and the execution path current as the
interview continues; do not replace detailed decisions with a summary.

- **Location (Q1, agreed):** provide an interactive map and adjustable pin matching the
  prototype experience. Prefer an existing Flutter package or configuration that
  makes map integration straightforward. Package/provider selection is deferred;
  the City remains the authority for accepted report locations.
- **Draft (Q2, agreed):** retain an unfinished report locally and offer to continue it after
  reopening, following the prototype. This is not an offline send queue.
- **Photos (Q3/Q17, agreed):** add library selection and removal of a selected photo. Keep photos
  optional and target up to three, matching the prototype. Confirm the City's
  actual attachment support during the later API investigation before promising
  three accepted attachments.
- **Identity (Q18, agreed):** reporting is always anonymous. Omit the prototype's Contact step
  and any contact-saving preference; no account or identity flow is intended.
- **Known failed send (Q4/Q19, agreed):** reopen a retained Not sent report for manual correction
  and retry. Keep this minimal, with no automatic retry or background queue.
  This does not authorize retrying an unconfirmed submission attempt.
- **Review (Q5, agreed through the inspected prototype):** follow the existing Review page. An edit returns directly
  to Review through Save changes instead of replaying subsequent steps.
- **Receipt (Q6, agreed):** allow copying the Service Request number and sharing the receipt.
  A receipt represents confirmed City acceptance, never a demo or unconfirmed
  attempt.
- **Help (Q7, agreed):** provide a Call 311 action for an unconfirmed outcome, using the
  prototype's Help/recovery presentation where applicable. The inspected prototype
  has recovery guidance but no working telephone action.
- **Local removal (Q8, agreed):** allow removal of drafts and confirmed local receipts.
  Removing a local record does not cancel the City's Service Request and must
  not clear an unresolved submission attempt or permit a duplicate send.
- **Scroll hint (Q9/Q20, agreed):** show a very light blur at the bottom while more content is
  below the viewport; remove it at the end. Keep the hint no more than five
  Flutter logical pixels high and visually unobtrusive. Retain the current home
  hero proportions and apply the hint to pages with more content below.
- **Statuses (Q10/Q25, agreed):** green Submitted, amber Submission unconfirmed,
  and neutral Not sent, always accompanied by text labels. Color never determines
  delivery state.
- **Dates (Q11/Q21, agreed):** use US date presentation, a 12-hour clock with AM/PM, and Los Angeles
  time (`America/Los_Angeles`), including the applicable PST/PDT offset.
- **Motion (Q12, agreed):** make step/page animations more obvious. Do not carry forward the
  earlier suggestion of subtle 220 ms transitions as an agreed requirement.
- **Button press (Q13, agreed):** pressing a raised button should visibly compress
  it and reduce its shadow.
- **Confirmation (Q14/Q22/Q23, agreed concept):** a report becomes a letter,
  travels through the air to town hall, and reaches it. The complete scene can
  be 2D; actual 3D or Unity is not required. Keep the requested expressive,
  complex motion, then flow continuously back into Home without the normal
  lateral Flutter navigation transition. The earlier Send-to-loader-to-receipt
  morph proposal was rejected. A success animation requires a confirmed Service
  Request. The letter is a visual metaphor for the real API Submission, not a
  new email delivery mechanism or proof that cleanup has been completed.
- **Home confirmation card (Q24, agreed):** after the automatic return, show the
  confirmed SR number with Copy and View receipt. Swipe left to dismiss the
  card. Its opacity changes only after a drag threshold; an incomplete or
  cancelled gesture recenters the card and restores its opacity. Q26 fixes the
  fade threshold at 20% of card width and dismissal on release at or above 40%.
  Dismissing this notice does not delete the
  saved Receipt, cancel the City's request, or change its delivery state.
- **Home composition (Q27, agreed):** after letter delivery, shrink the town-hall
  scene smoothly into the existing Home hero while the rest of Home and the
  confirmation card appear around it. Preserve the hero's agreed proportions.
  This is one continuous composition, with no standard lateral page slide.
- **Haptics (Q15, excluded):** none requested, given the email presentation.
- **Reduced motion (Q16, persistence upgrade excluded):** do not add persistent manual preferences for this scope.
  Retain the existing system preference and session accessibility setting.

### Future API investigation intention

- Plan a Postman-style inspection of request and response traffic across the
  reporting flow. Reuse existing work, complete gaps, and derive useful product
  constraints from the evidence. This is future work, not an action for this
  interview.
- `docs/portal-api.md` already covers Aura transport, guest session bootstrap,
  call order, location validation, question configuration, duplicate checks,
  photo payloads, and submission shapes. Client tests contain synthetic fixtures.
  No Postman collection/environment, HTTP request collection, or HAR was found
  in the inspected repository. Some private evidence remains, but the original
  raw-capture directory referenced by the API note is missing.
- Reconcile the existing reference and available captures before creating any
  collection. Distinguish captured responses, synthetic fixtures, and unverified
  assumptions. Useful gaps include attachment limits, required fields and answer
  encoding, authentic error responses, and duplicate handling. Preserve the
  existing submission evidence gap honestly. Never send another City request
  merely to fill it, and keep submission requests excluded from unattended runs.

### Skill research and implementation dependencies

- The user requested find-skills research delegated to GPT-6 Luna with xhigh
  reasoning. Research may inspect public skill sources and animation runtime
  documentation; app implementation, skill/package installation, and City API
  calls remain outside this interview.
- The 2D report-to-letter-to-town-hall concept and Home confirmation card are
  agreed, including the scene-to-Home composition and numeric gesture thresholds
  accepted in Q26/Q27. The authoring/runtime approach remains an implementation
  dependency. No Rive, Unity, Lottie, or other animation technology is selected
  yet; Rive plus Flutter is the researched recommendation.

#### Research results, 2026-10-22

Delegated with the requested `gpt-6-luna` model and `xhigh` reasoning. The searches
`npx skills find flutter animation`, `npx skills find rive flutter`,
`npx skills find unity animation flutter`, and
`npx skills find rive animation state machine` completed with results. No skill
or package was installed, and no City endpoint was called.

1. **Rive-specific workflow:**
   [uianimation/rive-skill@rive](https://skills.sh/uianimation/rive-skill/rive),
   with its [source repository](https://github.com/uianimation/rive-skill).
   Covers artwork authoring, State Machines/data binding, runtime integration
   including Flutter, accessibility, and handoff. No local Rive-specific skill
   was found. If selected later, its discovered installation command is
   `npx skills add uianimation/rive-skill@rive`. It provides guidance, not an
   authored `.riv` success scene.
2. **Existing local Flutter skill:**
   `/Users/regiskian/.agents/skills/flutter-animating-apps/SKILL.md` advertises
   native Flutter animation but is currently an OpenDesign catalogue stub
   pointing to the upstream `flutter/skills` material. Do not count the stub as
   a complete installed workflow or install a duplicate copy without resolving
   the installation model.
3. **Native Flutter implementation reference:**
   [madteacher/mad-agents-skills@flutter-animations](https://skills.sh/madteacher/mad-agents-skills/flutter-animations).
   Covers explicit, implicit, staggered/Interval, Hero, and physics patterns with
   Flutter examples. If selected later, the discovered installation command is
   `npx skills add madteacher/mad-agents-skills@flutter-animations`. It overlaps
   the local Flutter skill's advertised scope.

**Advisory direction, not an approved stack:** author a Rive scene in the app's
orange/cream visual language. On confirmed City acceptance, present it in an
overlay above Home, reveal Home underneath, and choreograph the same artwork
into the final Home composition. Keep the scene continuous through the handoff
instead of substituting a lateral route transition. Rive's
[official Flutter runtime](https://rive.app/docs/runtimes/flutter/flutter)
supports authored files, controllers, State Machines, and data binding. Actual
artwork, animation states, asset rights, and the visual endpoint still need to
be defined and created. A custom Flutter timeline is an alternative if a suitable
Rive asset cannot be authored; that would require an explicit scope decision,
not a silent downgrade of the requested complex animation. See the
[Flutter animation overview](https://docs.flutter.dev/ui/animations/overview).

**Unity trade-off:** the documented
[Unity as a Library iOS path](https://docs.unity3d.com/Manual/UnityasaLibrary-iOS.html)
adds `UnityFramework` and native host lifecycle integration. The official
[Unity as a Library limitations](https://docs.unity3d.com/Manual/UnityasaLibrary.html#Limitations)
include full-screen rendering only. This adds another project/build/lifecycle
boundary for the proposed Home handoff. The later Q23 answer permits an entirely
2D scene, so actual Unity or true 3D is not a requirement. The research
recommendation remains Rive plus Flutter for the illustrated scene; authoring
feasibility and the final implementation approach still need verification.

**Device motion preference verification dependency:** the audited checkout uses
Flutter 3.41.6 and currently reads `MediaQuery.disableAnimationsOf(context)` plus
the session setting. Current unversioned
[disableAnimations documentation](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html)
distinguishes iOS Reduce Motion from Android's Remove animations and points to
[`AccessibilityFeatures.reduceMotion`](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures/reduceMotion.html).
Before implementation, verify the iOS behavior and API availability against the
installed SDK and simulator settings. Record a focused regression if the system
choice is not honored, then fix it as a prerequisite to accepting the complex
animation. The session setting alone does not prove the device-setting path.
This research did not change the app or establish an observed native failure.

**Interview decisions settled through Q27:** the user accepted both remaining
recommendations with “rec to all.” The letter/town-hall scene shrinks into the
Home hero while Home content and the confirmation card appear. Fading starts
after 20% of card width; dismissal commits on release at or above 40%, with
recentering/full-opacity restoration on an incomplete or cancelled gesture.
These are agreed interaction values, not claims about Flutter defaults.
Artwork authoring, runtime/package selection, API capability checks, and motion
timing/easing remain later implementation work. No unresolved product question
from this interview round remains, and no implementation is authorized by
closing the interview.

### Planned path to the final state

This is an execution plan for later authorization. No step below is a claim of
implementation or permission to begin. Update the decision ledger, dependencies,
evidence, and remaining work whenever a choice changes. Never silently substitute
an easier behavior for an agreed intention.

#### Target resident journey

1. Home offers a new anonymous report and continuation of an unfinished Draft.
2. Location supports the agreed map/pin experience. The selected location feeds
   the real City's validation, rather than only changing an illustration.
3. Items captures the City's required debris answers. Photos offers optional
   camera/library attachments and removal, targeting three subject to verified
   API support. Details retains the description.
4. Review shows the final values. Edit opens the chosen section; Save changes
   returns directly to Review with the updated values.
5. An explicit send uses the existing real Submission client and retained
   delivery-safety state. Animation does not determine whether sending succeeded.
6. Confirmed City acceptance produces a Receipt and the expressive 2D sequence:
   the report becomes a letter, flies through the air, and reaches town hall.
   The sequence then transforms continuously into Home, with no normal lateral
   route animation. Home shows the confirmed SR number, Copy, and View receipt.
   The Receipt remains available afterward, including after card dismissal.
7. A known Not sent report can reopen for manual correction/retry. An unconfirmed
   attempt follows the existing blocked recovery path with Help/Call 311 and
   never enters the success sequence or automatic retry.
8. The Home confirmation card can be dragged left. Its fading starts only after
   the agreed threshold. Releasing short of dismissal or cancelling the gesture
   restores the centered, fully opaque card. Completing dismissal removes only
   this Home notice; the saved Receipt stays accessible.

#### Success storyboard and Home gesture contract

The agreed story has these acceptance beats, without an agreed numeric duration
or easing curve yet:

1. **Acceptance boundary:** retain the official SR/Receipt before presenting
   success. A rejected, missing, or unconfirmed response never starts this story.
2. **Transformation:** the report visibly becomes a letter. This should be an
   authored transformation, not merely replacing the text with a checkmark.
3. **Airborne delivery:** the letter travels through the air toward the town-hall
   illustration. Preserve the complex, expressive quality requested in Q22.
4. **Arrival:** visibly establish that the letter reaches town hall. This depicts
   report acceptance, not collection of dumped items or completion of cleanup.
5. **Home handoff (Q27, agreed):** the same visual sequence continues into Home;
   settle/shrink the town-hall scene into the Home hero while the rest of Home
   and the SR confirmation card appear around it. Do not insert a standard page
   slide or alter the hero's agreed proportions.

For the Home notice, the agreed gesture behavior is distinct from the prohibited
default lateral page transition: left dragging dismisses a card, not a route.
Treat displacement and opacity as separate quantities so that the card moves
with the gesture before fading begins.

| Gesture state | Required presentation | Delivery/Receipt effect |
| --- | --- | --- |
| Rest, or left drag before fade threshold | Centered at rest; follows left drag while retaining full opacity before the threshold | None |
| Left drag beyond fade threshold | Continues moving left; opacity decreases progressively with displacement | None |
| Release below dismissal threshold, or gesture cancellation | Animates back to center and restores full opacity, including after a partial fade | None |
| Release at/above dismissal threshold | Completes leftward exit and fade; removes the Home notice | Saved Receipt and City SR remain unchanged |

**Agreed parameters (Q26):** normalize leftward
displacement by the card width, with rightward displacement clamped to zero.
Start fading after 20% of the card width. Commit dismissal on release at or above
40%. Once fading has started, reduce opacity progressively to zero at a full
card-width displacement; completing dismissal continues the exit/fade. Below
40%, return to zero displacement and opacity 1. A cancelled gesture always
recenters, even if it crossed the threshold before cancellation. These are
agreed interaction values, not claims about Flutter widget defaults. A
velocity-only dismissal is outside the agreed distance-on-release rule; exact
animation timing/easing remains implementation tuning.

Later tests must separately prove the no-fade region, progressive fade, a
release short of dismissal, cancellation after partial fade, committed dismissal,
and continued availability of the saved Receipt. A native recording must show
the recentering and full success-to-Home sequence; a static screenshot cannot
establish either motion behavior.

#### A. Settle the design contract

- Dependencies: the interview answers and the skill research.
- Preserve the agreed 2D letter/town-hall story, SR/Copy/View receipt Home card,
  status colors, 20% fade/40% release gesture thresholds, and town-hall-to-Home
  hero composition. Keep engine/runtime selection separate from the visual
  intention.
- Preserve exclusions: always anonymous, illegal dumping only, no haptics, no
  automatic/background send queue, no persistent manual motion-setting upgrade,
  no other platforms or issue types added for this scope.
- Exit evidence: Q1-Q27 agreements are recorded, with later technical dependencies
  explicitly distinguished from product decisions. The latest answers complete
  the product-decision frontier. Implementation still requires a subsequent
  instruction to begin; this interview authorized documentation and research.

#### B. Reconcile API evidence before expanding capabilities

- Dependencies: later authorization for the API investigation.
- Inventory the existing API reference, available raw captures, synthetic client
  fixtures, and missing capture paths. Record provenance per example rather than
  treating synthetic test responses as network captures.
- Create or complete the requested Postman-style request/response workspace from
  those artifacts. Document bootstrap/session lifecycle, call dependencies,
  required headers and fields, location/question validation, duplicate behavior,
  attachment constraints, and result/error interpretation. Keep personal data and
  session values out of shareable exports.
- Investigate three-photo support and the relationship between map selection,
  coordinates, and City address validation. Do not silently drop extra photos or
  label unsupported attachments as sent. If the City only supports fewer than
  three, bring the demonstrated constraint back to the decision ledger.
- Submission requests stay excluded from unattended collection runs. Never
  execute historical live-send helpers or create another SR to fill evidence
  gaps. The existing C-04955177 record is not authorization for another send.
- Exit evidence: an endpoint/field coverage list distinguishes captured,
  synthetic, and still-unverified behavior; accepted constraints are reflected
  in the implementation plan before feature work.

#### C. Implement data and reporting behavior in small verified steps

- Dependencies: A; B for capabilities that rely on unknown City constraints.
- Keep the existing domain/storage/client separation. Add only the state needed
  by the behavior being implemented; tests drive changes instead of designing a
  new model or framework upfront.
- Draft persistence comes before Resume and failed-report reopening. Preserve
  existing `reports_v2` submitted rows, exact SR numbers, durable photo data, and
  uncertain-attempt markers when extending storage. A restart must not erase the
  duplicate-prevention boundary.
- Map work connects the user's selected pin/location to the real report values
  and validation. Choose a Flutter map package/provider after checking current
  compatibility and the intended prototype experience; no package is chosen by
  this interview record.
- Photo work adds library selection and removal, then the agreed verified
  attachment count. Required format/size handling follows actual API evidence.
- Review editing must return directly to Review, preserve other answers, and
  display the updated values that will be submitted.
- History work adds minimal manual reopening for known Not sent records,
  copying/sharing a confirmed Receipt, and permitted local removal. Local
  removal never cancels the City's SR or clears an unresolved send marker.
- Home work presents the accepted SR notice after the success sequence, with
  Copy and View receipt, and implements the agreed left-drag/fade/cancel behavior.
  Notice dismissal remains separate from deleting a saved local Receipt.
- Date presentation consistently uses US dates, AM/PM, and Los Angeles time.
  Help uses the agreed Call 311 action for unresolved delivery.
- For each behavior: first reproduce the missing behavior with one failing test,
  implement the smallest change, run its required checks, review the candidate,
  and make one scoped Conventional Commit after the gates pass. A failed code
  test reverts only that burst and triggers a rethink. An inconclusive review
  service response preserves the tested candidate and blocks publication until
  a valid review is obtained.
- Exit evidence: every agreed reporting behavior has its resident-visible
  acceptance check, current test evidence, and a recorded commit. No feature is
  marked done solely because it appears in the prototype.

#### D. Author and integrate the success sequence

- Dependencies: A's agreed visual direction; C's confirmed-acceptance and Receipt
  behavior. Skill discovery is preparation, not an animation asset.
- Author the actual artwork/animation, define its loading/success/completion
  signals, and plan its continuous visual handoff into Home. Match the agreed
  report-to-letter transformation, airborne travel, and arrival at town hall.
  A skill or runtime installation alone does not supply the finished scene.
- Trigger success only from confirmed City acceptance. The scene celebrates
  receipt of a report, not completion of the City's physical cleanup work.
- Keep the accepted Receipt available even if the animation cannot load or the
  app is interrupted. Animation state never changes delivery state or authorizes
  another send.
- Apply the existing system/session reduced-motion choice to both the scene and
  the return to Home. Verify the actual iOS preference mapping during later work
  instead of assuming a particular Flutter accessibility flag is sufficient.
- Make step/page motion more obvious and raised-button press states visible,
  while retaining the agreed faint scroll hint and home hero proportions.
- Exit evidence: inspect a recorded sequence from confirmed-success presentation
  through the final Home state, plus the reduced-motion outcome. Verify that no
  normal right-to-left route transition appears in that flow.

#### E. Verify and prepare the email review artifact

- Dependencies: completed C and D, with all required reviews valid.
- Run the project's formatter, static analysis, focused and full test suites,
  and coverage gate. Keep production line coverage at 100% without exclusions;
  test titles and assertions must prove the same behavior.
- Build and inspect the iOS simulator app, including Draft restart/resume,
  changed map location, camera/library/remove, direct Review return, known-failure
  reopening, unconfirmed blocking, local removal, Los Angeles dates, and motion
  with the system/session preference. Use the actual app and preserve real
  stored receipts. No verification step sends another City request.
- Synthetic test responses may prove controlled scenarios but must stay labeled
  as synthetic. They never establish a new live City acceptance or repair the
  original native-send provenance gap.
- Retain check commands/results, reviewed commits, screenshots, and an animation
  recording with their environment and provenance. Prepare the useful links and
  artifacts for review by email; sending an email is not part of this interview.
- Final state is reviewable native behavior plus truthful evidence. The missing
  original native-send proof remains explicitly unresolved unless independently
  recovered; a green build or a polished animation does not resolve it.

### Existing implementation seams and later verification commands

These are current files to extend, not claims that the proposed features already
exist or are covered. Recheck their state before implementation because other
work may advance the app during the interview.

| Responsibility | Existing production files, relative to `reports/` | Existing test seams, relative to `reports/test/` |
| --- | --- | --- |
| Location/map, photos, Review editing, retry, success presentation | `lib/src/mobile_report_flow.dart` | `platform_flow_test.dart`, `flow_design_test.dart`, `submit_flow_test.dart` |
| Draft/storage, retained reports, protected removal | `lib/src/report.dart`, `lib/src/storage.dart`, `lib/src/history_page.dart` | `report_storage_test.dart`, `history_page_test.dart` |
| Home, Help, scroll hint, motion preference | `lib/main.dart`, `lib/src/reports_design.dart` | `reports_design_test.dart`, platform/flow tests above |
| Package/platform configuration and actual City transport | `pubspec.yaml`, `ios/Runner/Info.plist`, `lib/src/portal_submission_client.dart` | `portal_submission_client_test.dart` |

Use Dart MCP for test, analysis, formatter, launch, and runtime inspection when
available. The following are verified command forms for later execution through
context-mode from `/Users/regiskian/Git/reports/reports`; none were run as part
of this interview update:

```sh
rtk proxy flutter test --coverage test/
rtk proxy flutter analyze
rtk proxy dart format --output=none --set-exit-if-changed lib test
rtk proxy flutter build ios --simulator --debug
```

Inspect `coverage/lcov.info` from that working directory for 100% production line coverage without
exclusions. Run focused tests during each small behavior change, then the full
suite for final integration. A successful test command alone does not establish
the required coverage percentage or live City provenance.

Use Dart MCP launch or a detached `flutter run` process with captured output for
simulator `C4E392DE-D493-40CD-881A-2F6729C93E45`. Keep the iOS Podfile's existing
15.0 deployment-target override. Never replace a blocked native check with an
assumed pass.

The existing native permission-description test is in
`reports/ios/RunnerTests/RunnerTests.swift`; it does not prove the planned
reporting interactions or animation. Its recorded command form, from
`/Users/regiskian/Git/reports/reports/ios`, is:

```sh
rtk proxy xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination id=C4E392DE-D493-40CD-881A-2F6729C93E45 -parallel-testing-enabled NO -destination-timeout 30 -only-testing:RunnerTests/RunnerTests/testRequiredPermissionDescriptionsArePresent
```

No reusable native journey verification script was found. Native visual and
interaction checks therefore need explicit execution/evidence when authorized.
Never run the archived `execute_live_send.dart`, `preflight_live_test.dart`, or
`dry_run_main.dart` under
`.scratch/illegal-dump-reporter/evidence/original-workspace-20261022/paths/tool/`.

## Approved ticket breakdown and publication contract

The user's current approval of the 15-ticket draft adds a skills-first
prerequisite and an explicit parallel orchestration policy. This approved
16-ticket breakdown is the source for local publication as tickets 11-26;
no further granularity approval is needed for those requested additions.
Tickets 01-10, their statuses, comments, and evidence remain unchanged. The
series already starts at 01; no existing issue is a parent being modified.
This is ticket preparation/publication only. Further execution requires an
instruction to begin; app implementation, skill/package installation, API
investigation, City sends, and actual email delivery are not started here.

Each ticket is a complete, independently demonstrable behavior and can contain
several small test-first bursts. One behavior per burst/commit still applies;
a ticket is not a license for a single large commit. Current architecture needs
no speculative prefactoring or wide refactor before these slices.

### Parallel orchestration and implementation contract

- The desired orchestrator is `gpt-6.1-sol` with `ultra` reasoning and manages
  only. It owns the dependency frontier, dispatch, explicit disjoint ownership,
  worktree coordination, candidate review, integration, serialized Git/index
  mutations, and concise progress/evidence reporting. It does not implement
  application code, tests, or assets itself.
- Implementers use the requested `gpt-6.1-sol` with `high` reasoning. Fast service
  tier is requested for later execution. The current spawn API exposes model
  and effort but no service-tier field; do not claim fast tier was applied or
  verified, or infer the actual parent model from the desired policy. Runtime
  metadata must establish any claim about the provider, model, or tier used.
- Maximize concurrent work across the genuinely independent, unblocked
  frontier. Ticket 11 gates animated implementation in 13 and 21, and thereby
  25. It does not gate unrelated Draft, map, photo, Review, Receipt, recovery,
  Help, or status/date work. Shared source files require explicit ownership and
  small sequenced integrations, not artificial blocking edges or concurrent
  conflicting edits.
- Implementers own code, tests, and authored assets on isolated task branches
  and worktrees. Each burst is one test-first behavior and one passing,
  independently reviewed TCR cycle per scoped Conventional Commit. A failed
  code test reverts only that burst; the implementer rethinks and retries.
  Required checks and 100% production line coverage without exclusions remain
  gates, including during integration.
- An inconclusive or unavailable required review service preserves the tested
  candidate and blocks commit/publication until valid review is obtained.
  Do not discard healthy work, fabricate review, weaken gates, or treat review
  infrastructure failure as a product-test failure. The orchestrator inspects
  delegated evidence before accepting completion and serializes integration
  and Git mutations rather than implementing a worker's fix.
- Current parallel workers publish documentation only. Preserve existing
  tickets 01-10, submitted rows/SR values, private evidence, and unresolved
  native-send provenance. No new City send, historical live-send helper, or
  actual email is authorized by this publication or the later verification
  tickets.

### Shared acceptance boundaries

- Always anonymous (Q18), illegal dumping only, native real-client submission
  retained. This already-working scope is a regression boundary, not a new
  contact/login implementation ticket.
- Preserve existing submitted Reports, exact SR numbers, durable attachments,
  and uncertain-attempt protection across restart. No second City submission,
  no historical live-send helpers, no automatic/background send queue.
- Controlled response fixtures are labeled synthetic and never presented as
  proof of a new live Submission. Existing original native-send proof remains
  unresolved; tickets 01, 04, and 09 are not silently closed or used to block
  unrelated native improvements.
- Every slice includes meaningful behavior tests and relevant checks; final
  integration retains 100% production line coverage without exclusions.
- No haptics, persistent manual motion preference, new contact flow, or other
  issue types. System/session reduced motion applies wherever motion is added.
- A shared source file or a convenient implementation order is not a blocker.
  The blocking edges below describe required working behavior or evidence.

### 11: Establish usable skills and the animation authoring/runtime route

**Blocked by:** None.

**Delivers:** animation implementers can follow complete, usable guidance and
an evidence-backed authoring/runtime route for the agreed expressive 2D scene
and native Flutter orchestration before animated work begins. Trace: Q9,
Q12-Q16, Q20, Q22-Q27, skill research, and the user's skills-first approval.

- Treat existing find-skills research as a shortlist, not installed/verified
  capability. The local Flutter animation skill is a catalogue stub. Confirm
  the full usable SKILL.md, its source/version, and version-sensitive APIs
  against the installed Flutter/iOS and chosen runtime before using them.
- Resolve one installation model, managed read-only plugin or editable local
  skill copy. Never install duplicate managed/editable workflows. Ticket
  publication itself installs no skills or packages.
- Confirm the actual asset-authoring route, available tools, asset rights,
  export/loading/completion signals, and a feasible continuous handoff into the
  existing Home hero. A skill or runtime is not authored artwork or a finished
  scene. Preserve the full report-to-letter, airborne travel, town-hall arrival,
  and scene-to-Home composition rather than reducing it to a loader/checkmark.
- Select a viable 2D scene stack with native Flutter orchestration using
  evidence. Compare native Flutter animation and authored-scene approaches such
  as Rive; Unity plus Flutter remains an alternative, not a mandate. Record
  authoring feasibility, iOS embedding/lifecycle constraints, reduced-motion
  control, and the rationale. Later coding choices with distinct paths still
  require the independent Jev decision gate before choosing.
- Publish the usable guidance, version/API evidence, route decision, and
  authoring handoff for 13, 21, and 25. This skills-first gate blocks animated
  implementation, not unrelated Draft/map/photo/recovery work. It does not
  claim final artwork or native motion verification is complete.

#### Ticket 11 preflight result, 2026-10-22

**Selected route: original vector artwork authored in native Flutter.** This
preserves the entire agreed 2D scene. It replaces the earlier advisory Rive
recommendation, without reducing the storyboard. Jev, exposed model
`jev-latest`, selected `native` with confidence 0.97 and probabilities native
0.98, Rive 0.02, Unity 0.00. No fallback was used. This establishes an executable
route for 13, 21, and 25, not completed artwork or verified native motion.

**Usable guides and access.** The complete public
[Flutter animations SKILL.md v2.0](https://github.com/MADTeacher/mad-agents-skills/blob/2fb67e384c6d91f32025bd96400d33b73f21bdc7/flutter-animations/SKILL.md)
and its `references/explicit.md`, `staggered.md`, and `curves.md` are retained
under ignored `evidence/ticket11/`, with the MIT license. Its controller
ownership/disposal, Interval sequencing, narrow rebuilds, reduced motion, and
behavioral verification guidance fits this app. Source last pushed 2026-05-01;
examples still need validation against the installed SDK before adaptation.
The local `flutter-animating-apps` SKILL.md is only a catalogue stub. Its upstream
redirects to `flutter/agent-plugins`; tree
`f813a46b18456a20f37eb5784c091b7d945c3b4b`, pushed 2026-10-21, contains no
animation SKILL.md. Do not claim that stub is full guidance.

The complete public
[Rive SKILL.md v0.6.0](https://github.com/uianimation/rive-skill/blob/a1f8a1cb2f45c3352cb9c6ce5a2c7d076cdcfd04/SKILL.md)
and its editor-authoring, runtime-integration-patterns, runtime-handoff-checklist,
and runtimes-performance-accessibility references are retained with MIT license.
The source, pushed 2026-09-09 and researched 2026-09-04, distinguishes editor
access from runtime integration and requires current renderer/API verification.
It supplies practical hierarchy/timeline/state-machine and export handoff
guidance, not a `.riv` asset. The existing full local `unity-cli/SKILL.md` is
retained by SHA-256
`ca4cc5a92df7d22d8e17c45d9937a7aa21fa04c204eec04110f65e9e8b2a94a4`;
it describes Unity CLI beta.11, Editor/Pipeline scene authoring and builds.
It is not a Flutter bridge guide. Pair it, only for the optional route, with the
actual [Flutter Unity setup guide](https://pub.dev/packages/flutter_unity_widget)
and [Unity as a Library iOS guide](https://docs.unity3d.com/6000.0/Documentation/Manual/UnityasaLibrary-iOS.html).

These are reference snapshots, outside skill discovery directories, not installed
skills. No package, skill, account, or configuration was installed or changed.
For this route use the retained full Flutter guide directly. If later installing
a workflow, choose one editable project copy, first resolving the overlapping
catalogue entry; do not also enable a managed copy. Public source access needs no
credential. A reference file's presence does not establish editor access.

**Compatibility evidence.** Installed `flutter --version --machine` reports
Flutter 3.41.6, revision `db50e20168db8fee486b9abf32fc912de3bc5b6a`, Dart 3.11.4.
The app requires Dart `^3.11.4`; `xcodebuild -version` reports Xcode 27.0
`27A266a`. Podfile deployment and its all-pods override remain iOS 15.0.
The selected route adds no runtime/package: Canvas/Path/CustomPainter,
AnimationController, Tween, Interval, AnimatedBuilder and layout transforms are
framework APIs. Context7 `/flutter/website` confirms one controller plus Interval
sequencing; `/websites/api_flutter_dev` was also queried. Current primary
[CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html),
[AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html),
and [MediaQuery.disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html)
docs define repaint/listener/disposal and preference-change behavior. Check the
installed SDK source before coding where current docs differ. Current
[iOS renderer documentation](https://docs.flutter.dev/perf/impeller) requires
Impeller; do not propose an iOS Skia fallback. Actual scene performance and native
system-preference propagation are unverified until 13/25.

Rive remains technically possible, but is not selected: pub.dev reports stable
`rive 0.14.11` with `rive_native 0.1.11`, declared Dart >=3.6.0 and Flutter
>=3.28.0. Context7's current migration guide corrects the actual Flutter floor to
3.32.0/Dart 3.8.0, while master autodocs describe newer constraints. The installed
SDK meets both floors; this is constraint compatibility, not a native build.
The published native podspec declares iOS 9.0, not proof of every binary feature;
retain the project's iOS 15 override and require a target build if reconsidered.
`Factory.rive` and `Factory.flutter` have different feature/renderer behavior.
`RiveWidgetBuilder` exposes loading/failed/loaded states, but cannot author art.
Rive.app is installed; no `rive` CLI is on PATH and usable signed-in authoring,
export entitlement, actual `.riv`, and editor automation were not verified.
[Current pricing](https://rive.app/pricing) reserves runtime exports for paid
plans. No entitlement or purchase is assumed.

Unity CLI and Hub are installed, but no Editor was found in the usual Hub Editor
directory. The inspected `flutter_unity_widget 2022.2.1` is discontinued; its
guide requires an exported Unity project and warns of simulator limitations.
Unity as a Library adds UnityFramework, host lifecycle and memory concerns;
official full-screen limitations require separate investigation before any hero
embedding claim. Neither SDK constraints nor a Unity skill establish compatibility
with this Flutter/iOS build. No Unity editor/license/bridge build is verified.

**Executable authoring handoff to 25.** The implementer authors original
source-controlled Dart vector geometry and choreography, not a loader, checkmark,
stock animation, or placeholder. Inputs are the accepted storyboard, existing
ReportsStyle palette, current native Home layout, and exact confirmed Receipt.
Draw an original Report sheet and folds, envelope front/flap, airborne letter,
cloud layers and an original illustrated town hall/foreground. Use local paths,
fills, strokes, gradients and transforms; no external seals, logos, photos,
downloaded artwork or fonts are required. This route uses no third-party art
license or export account. Original geometry is created for this project under
the authorized implementation; record any added external asset's use/modification/
distribution license before including it. Retained MIT guides do not grant rights
to arbitrary example artwork. Preserve their notices if copying licensed code.

The runtime export is the authored `.dart` vector scene and timeline checked into
the app's existing source structure. There is no `.riv`, UnityFramework, remote
asset URL, or binary exporter. Review exports are synthetic storyboard PNG frames
and a native simulator video; they are evidence, not playback assets. First
produce inspectable full-scene frames for each beat, then animate those actual
paths. A programmatic drawing API alone does not meet the authored-art criterion.

Use a single normalized composition and explicit controller timeline: Report
folds into the letter, letter follows a curved airborne path with layered cloud
movement, letter arrives at town hall, then that same town-hall composition
shrinks continuously into the measured existing `home-hero` bounds. Define
keyframes/Intervals for all four beats and inspect each before tuning duration.
Render Home beneath the composition before the last interval, reveal Home and its
SR card during the shrink, and remove the overlay only once its final frame
matches the Home hero. Keep existing hero constraints, padding, radius, border,
shadow and text proportions; measure the actual laid-out target rather than
copying the web prototype's 326px mobile minimum into native code. Do not use the
default lateral Navigator transition or swap unrelated illustrations mid-shrink.

Flutter owns the confirmed Receipt, Home/card visibility, controller lifetime and
once-only presentation completion. Start only after confirmed City acceptance is
retained. Pass normalized progress to the painter; keep SR text and actions as
accessible Flutter widgets outside the drawing. A controller completed status,
not a delay guessed from playback, emits the one presentation completion after
the matching hero frame is installed. Interruption/cancellation must also leave
Home and View receipt reachable without resubmitting or replaying on restart.
Dispose controllers/listeners; handle TickerCanceled if awaiting `.orCancel`.

There is no asynchronous artwork load in the selected vector route. While the
City result is pending, retain ordinary sending feedback and never show success.
For missing target layout, interrupted composition or a rendering/setup failure,
settle directly to the static Home hero and confirmed SR card with Receipt access;
never change delivery state or retry the Submission. Compute the target after
layout before flight; a missing target must not leave a permanent overlay.

Read the existing effective `MediaQuery.disableAnimationsOf(context)` seam, which
ORs the session choice with the device preference. With reduced motion, bypass
fold/flight/shrink and show the same final Home, exact SR, and Receipt actions.
If the preference changes during playback, stop and settle once. No haptics or
persistent manual preference is added. Ticket 13 must prove iOS Settings Reduce
Motion reaches this seam; injected widget preferences prove only synthetic logic.

**Verification handoff.** In 13 verify raised-button compression/shadow,
observable step movement, <=5 logical-pixel faint bottom hint, and device/session
motion behavior. In 21 verify no lateral return and the exact 20%/40% left-swipe
card contract, including cancellation and rightward clamp. In 25 test confirmed
acceptance gating, each authored frame, continuous final bounds, completion once,
interruption, failure/static Receipt path, preference changes, and disposal.
Record the complete normal sequence and reduced-motion outcome on iPhone 18 Pro
simulator `C4E392DE-D493-40CD-881A-2F6729C93E45`, labeled synthetic acceptance.
Use one behavioral test-first burst at a time; run Dart MCP format/analyze/focused
tests before scoped reviewed commits. Final integration still requires 100%
production line coverage without exclusions, all tests and iOS build. This
preflight ran no app implementation, native scene verification or City calls.
The historical C-04955177 native-send provenance gap remains unchanged.

### 12: Inspect the reporting API in a reusable request workspace

**Blocked by:** None.

**Delivers:** a developer can follow the anonymous reporting request/response
chain in a Postman-style workspace and distinguish observed behavior from
synthetic examples or missing evidence. Trace: Q6 and the API-investigation
intention.

- Reuse the existing reference, captures, and fixtures before creating exports.
- Document session setup, location/questions, duplicate checks, attachment
  constraints, and result/error interpretation with per-example provenance.
- Establish the supported attachment contract or explicitly document the
  unsupported/unverified boundary; do not infer three-photo support from a UI.
- Shareable examples are sanitized, and dispatch requests are excluded from
  unattended runs. No City write is authorized to complete the investigation.
- Missing original transaction/native provenance remains explicit.

### 13: Make reporting controls visibly responsive and motion-aware

**Blocked by:** 11: Establish usable skills and the animation authoring/runtime route.

**Delivers:** a resident sees stronger step/page movement, raised-button press
feedback, and a faint cue when content continues below, with system/session
reduced motion honored. Trace: Q9/Q12/Q13/Q15/Q16/Q20.

- Verify the installed iOS/Flutter system preference path; fix it if a focused
  reproduction shows that Follow device settings does not receive Reduce Motion.
- Pressing a raised button visibly compresses it and reduces its shadow.
  Step/page motion is more obvious than the rejected subtle-transition proposal.
- The bottom hint is at most five logical pixels high, remains very light, and
  disappears at the end. Keep the Home hero's existing proportions.
- Both system and session motion choices retain usable feedback without the
  expressive transitions. No haptics or preference-persistence upgrade.
- Demonstrate this through the existing report journey without a City send.

### 14: Continue an unfinished Draft after reopening the app

**Blocked by:** None.

**Delivers:** a resident can leave an unfinished Report and continue it from Home
after reopening, with their answers and optional photo retained. Trace: Q2.

- Follow the prototype's Draft continuation behavior without adding a queue.
- Resume the retained input and reporting position, including attachment access.
- Existing submitted rows, receipts, and uncertain-attempt protection survive
  the persistence extension and restart.
- Continuing a Draft never dispatches it automatically.

### 15: Choose the dumping location with an interactive map pin

**Blocked by:** None.

**Delivers:** a resident can find and confirm the dumping location through the
prototype-style map and adjustable pin instead of GPS alone. Trace: Q1.

- Select an appropriate Flutter map package/provider after current compatibility
  checks; preserve the prototype's address/intersection, map movement, pin, zoom,
  and current-location interactions where supported by the agreed flow.
- The chosen coordinates become the Report's actual location and feed the real
  City's validation and submission contract, not only the preview artwork.
- Review reflects the selected location, and permission/network failures remain
  understandable without manufacturing a valid City location.
- This extends the documented coordinate contract; a new API investigation is
  not a blanket prerequisite for displaying or adjusting the map.

### 16: Select and remove an optional photo from camera or library

**Blocked by:** None.

**Delivers:** a resident can use the photo library as well as the camera and
remove the selected optional attachment before sending. Trace: Q3.

- Keep the currently supported one-photo contract working end to end.
- Selection/removal updates the visible Report/Review and retained attachment
  data; cancelled pickers and permission failures do not erase other answers.
- A removed attachment is absent from the actual outbound Report payload.
- Photo-free reporting remains available.

### 17: Retain and send up to three optional photos

**Blocked by:** 12: Inspect the reporting API in a reusable request workspace;
14: Continue an unfinished Draft after reopening the app;
16: Select and remove an optional photo from camera or library.

**Delivers:** a resident can build, resume, review, and explicitly submit a Report
with up to three photos under the City's verified attachment rules. Trace: Q17.

- Add/remove up to three attachments and retain them through Draft restart and
  known-failure correction, without breaking legacy saved Reports.
- All retained attachments reach the real client payload in the verified format
  and within verified constraints; no silent truncation or fabricated upload.
- If 12 establishes fewer supported photos or cannot verify support, this ticket
  remains blocked for an evidence-backed scope decision. A resolved research
  file alone does not establish the required capability.
- Controlled tests cover no-photo, supported multi-photo, removal, persistence,
  and outbound payload behavior without creating a City request.

### 18: Save a Review edit directly back to Review

**Blocked by:** None.

**Delivers:** a resident can edit a selected Review section and return directly
to the updated Review instead of traversing the remaining steps. Trace: Q5.

- Save changes returns to Review with the new values; unrelated answers survive.
- Required-field validation still applies, and cancellation/back does not
  silently dispatch or erase the Report.
- Each later location/photo feature preserves this same edit-return contract.

### 19: Reopen a known Not sent Report for manual correction

**Blocked by:** 14: Continue an unfinished Draft after reopening the app.

**Delivers:** a resident can reopen a retained Not sent Report from saved reports,
correct its contents, and explicitly retry through the resumable editing flow.
Trace: Q4/Q19.

- Preserve the retained Report and attachments instead of losing the failed
  entry or creating duplicates for each correction.
- Only known Not sent outcomes enter this path. Submitted and unconfirmed
  records do not become sendable Drafts.
- An unconfirmed attempt remains blocked across restart; no automatic retry,
  queue, or clearing of its protected marker is introduced.

### 20: Copy and share a confirmed Receipt

**Blocked by:** None.

**Delivers:** a resident can copy a confirmed SR number and share its Receipt
from the existing saved-Report/Receipt experience. Trace: Q6.

- Actions use the exact retained City SR and accurate Report details.
- Unconfirmed/Not sent records never produce a fabricated successful Receipt.
- Native copy/share works independently of the new Home card or animation;
  a dismissed share sheet does not change delivery state or delete the Receipt.

### 21: Return to Home with a swipe-dismissable confirmation card

**Blocked by:** 11: Establish usable skills and the animation authoring/runtime route.

**Delivers:** after confirmed acceptance, Home presents the exact SR number,
Copy, and View receipt, with the agreed left-swipe interaction. Trace: Q24/Q26.

- Return without a standard lateral route slide; the full authored letter scene
  is added by 25, not required to demonstrate this usable endpoint.
- Keep full opacity through 20% of card width; fade progressively afterward.
  Release at or above 40% completes dismissal. Release below 40% recenters and
  restores full opacity. Gesture cancellation always restores the card, even
  after crossing the threshold or partially fading.
- Clamp rightward displacement to zero. Opacity reaches zero at one full
  card-width displacement; no velocity-only dismissal overrides the release
  distance rule.
- Recenter/dismiss behavior responds to the existing motion-preference seam.
  Controlled tests do not claim observed iOS system-setting compliance; native
  preference-path verification remains part of 13 and final integration.
- Card dismissal only hides the notice. The saved Receipt, City request,
  delivery state, and uncertain-attempt protection remain unchanged.
- Copy/View receipt are usable here without waiting for share-sheet support.
  Controlled acceptance evidence is labeled synthetic; no live send is required.

### 22: Remove a local Draft or confirmed Receipt safely

**Blocked by:** 14: Continue an unfinished Draft after reopening the app.

**Delivers:** a resident can remove permitted local records while understanding
that this does not cancel a City Service Request. Trace: Q8.

- Remove an unfinished Draft or confirmed local Receipt through clear local
  removal actions, preserving other saved Reports and exact SR values.
- Unconfirmed attempts and protected markers cannot be removed to unlock a send.
- The result survives reopening, and local removal never calls a City cancellation
  endpoint or changes the City's record.

### 23: Reach Call 311 from unconfirmed-submission Help

**Blocked by:** None.

**Delivers:** a resident with an unconfirmed submission can find the existing
recovery guidance and invoke the verified 311 phone action. Trace: Q7.

- Follow the prototype's Help/recovery presentation and verified City contact
  information, while keeping the unresolved SR/attempt context visible.
- The action does not clear the lock, retry dispatch, or imply cancellation.
- Verify the OS handoff and any simulator limitation without placing a call.

### 24: Read truthful statuses and Los Angeles dates consistently

**Blocked by:** None.

**Delivers:** saved Reports, Receipts, and confirmation surfaces consistently
communicate delivery state and display US dates in Los Angeles time. Trace:
Q10/Q11/Q21/Q25.

- Green Submitted, amber Submission unconfirmed, and neutral Not sent include
  text labels and never infer delivery from color alone.
- Use US date presentation and AM/PM in America/Los_Angeles, including PST/PDT
  as applicable, regardless of the device's different timezone.
- Preserve stored timestamps, actual delivery states, and exact City SR values;
  verify daylight-saving boundaries with fixed test data.

### 25: Deliver the Report as a 2D letter into the Home hero

**Blocked by:** 13: Make reporting controls visibly responsive and motion-aware;
21: Return to Home with a swipe-dismissable confirmation card.

**Delivers:** confirmed acceptance plays the authored expressive 2D story:
Report becomes letter, flies through the air, reaches town hall, then the
town-hall scene shrinks into the existing Home hero while Home and its SR card
appear. Trace: Q14/Q22/Q23/Q27.

- Author the actual artwork and animation as part of this complete slice. Rive
  plus Flutter is a researched recommendation, not a forced engine choice or
  a substitute for creating the requested scene. Verify the feasible authoring
  route before committing to a runtime; any scope reduction needs a decision.
- Keep one continuous composition, retain hero proportions, and avoid the
  default lateral page transition. A checkmark/loader alone is not this scene.
- Only confirmed City acceptance starts success. The letter depicts acceptance,
  not a new email API or completion of physical cleanup.
- Retain Receipt access if interrupted or an asset fails, and honor the proven
  system/session reduced-motion path without haptics.
- Record the complete accepted-success presentation and reduced-motion outcome
  with truthful provenance and no new City submission.

### 26: Verify the complete native experience and prepare email review evidence

**Blocked by:** 15, 17, 18, 19, 20, 22, 23, 24, 25. These are the remaining leaf
deliverables; their prerequisites are already reached through those edges.

**Delivers:** an interviewer can inspect the complete native reporting experience
and its evidence through a prepared email review package. Trace: all Q1-Q27 and
the agreed email presentation boundary.

- Verify the integrated anonymous flow, Draft restart/resume, selected map pin,
  attachments/removal, direct Review editing, safe retry, protected uncertainty,
  local removal, Receipt actions, statuses, dates, and success/Home gesture motion.
- Run formatter, static analysis, full meaningful tests, 100% production line
  coverage without exclusions, iOS build, and native interaction checks.
- Preserve check results, reviewed changes, screenshots, and the full motion
  recording with their environment/provenance. Synthetic scenarios remain labeled.
- Make links/artifacts reviewable for an email; do not send an email as part of
  this ticket without explicit messaging authorization.
- Report the historical original native-send evidence gap honestly. No new City
  request is allowed to manufacture missing proof.
