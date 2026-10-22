# 11: Establish usable skills and the animation authoring/runtime route

**What to build:** establish a documented, executable route for implementing the agreed expressive 2D report-to-letter-to-town-hall scene and native Flutter motion. A later implementer can follow usable guides, author the real asset, integrate it with the current app, and prove the result without pretending that a runtime or skill supplies the artwork. Trace: Q12/Q13/Q14/Q16/Q22/Q23/Q24/Q26/Q27 and the requested skills prerequisite.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] Reconcile the earlier find-skills shortlist with full, accessible Flutter animation, Rive, and Unity-plus-Flutter implementation guides. Retain each usable SKILL.md source and version, and inspect its actual content, access requirements, maintenance, and suitability; the local Flutter skill stub alone is insufficient evidence of a usable guide.
- [x] Record the actual current Flutter/Dart, iOS deployment, runtime/package, and renderer compatibility needed by candidate routes using current primary documentation and Context7 where available. Distinguish verified compatibility from untested assumptions, and record the evidence date.
- [x] Verify the available skill installation model and guide access before recommending use. Avoid concurrent managed read-only and editable copies of the same skill; identify missing access or installation prerequisites honestly. Do not install skills/packages or change runtime configuration in this preflight without later authorization.
- [x] Inspect actual asset-authoring capabilities, including available authoring tools, access, asset rights, export support, and who or what can create the real scene. Verify rights to use, modify, and distribute the artwork and exported assets. Separate authored asset creation from runtime playback, Flutter orchestration, and a guide's instructions. Never claim a tool can create or export assets without evidence.
- [x] Compare viable routes through the independent Jev decision gate before selection, reporting its answer and any fallback used. Rive plus Flutter is the prior recommendation; Unity is an optional alternative, and the full scene may be entirely 2D. Do not make Unity mandatory or silently replace the expressive scene with a simpler effect.
- [x] Produce an executable route with accessible guides, compatible runtime choice, actual artwork/animation authoring steps, an explicit authoring handoff, required inputs and exports, native Flutter orchestration, success-to-Home composition, system/session reduced-motion handling, and verification evidence. Define the asset export format, runtime loading and failure behavior, and completion signals that coordinate the continuous Home handoff. If a required capability is unavailable, name the concrete blocker and the remaining handoff before claiming implementation readiness.
- [x] Preserve every storyboard beat: report becomes a letter, letter travels through the air, arrives at town hall, then the same scene shrinks into the unchanged Home hero while Home and its SR card appear. A loader, checkmark, runtime installation, or placeholder is not an authored scene. Any scope reduction requires an explicit decision.
- [x] Document the preflight result without app implementation or live City traffic. It gates 13: Make reporting controls visibly responsive and motion-aware and 21: Return to Home with a swipe-dismissable confirmation card, reaching 25 through those prerequisites; unrelated work remains unblocked.
- [x] Preserve anonymous illegal-dumping native submission behavior, existing Reports/SR values, attachments, and uncertain-attempt locks. Do not send City requests, invoke historical live-send helpers, add retries/queues, haptics, persistent manual motion preferences, contact flows, or other issue types. Label synthetic evidence and preserve the historical native-send evidence gap.
- [x] Keep later implementation test-first in one behavior per burst with scoped Conventional Commits and meaningful verification; retain the final 100% production line-coverage requirement without exclusions.

## Comments

2026-10-22: Preflight complete, pending root inspection and configured review.
The existing spec's Ticket 11 preflight result records the executable native
Flutter vector-authoring route, complete four-beat storyboard, unchanged measured
Home hero handoff, completion/failure/interruption contract and system/session
reduced motion. Jev `jev-latest` selected native, confidence 0.97; no fallback.
This is route readiness, not authored artwork or observed native motion.

Full Flutter v2.0 and Rive v0.6.0 SKILL.md sources, relevant references, licenses,
pinned repository metadata and published runtime constraints/podspec are retained
in ignored `../evidence/ticket11/`, with hashes in `manifest.json`. The local
Flutter catalogue stub is explicitly insufficient. Rive export entitlement and
Unity Editor/bridge compatibility remain unverified alternatives, not selected
route prerequisites. No skills/packages/configuration were installed or changed.

Verification: `flutter --version --machine` recorded 3.41.6/Dart 3.11.4;
`xcodebuild -version` recorded 27.0/27A266a. Existing source/Podfile inspection
confirmed iOS 15.0 and effective motion seam. Current Context7 and primary-source
checks are cited in the spec. Documentation checks verify all four beats,
original-art authoring and exports, guides, rights boundaries, Receipt access,
reduced motion and completion contract. No app source or City request was run.
Historical native-send provenance remains unverified. All implementation tests,
native scene capture and final 100% production coverage remain later gates.

Read-only review inspection found strict Ketchup, batchCount 3, 20 enabled
validators and Codex's pre-tool hook. Root stages/pins this candidate and runs
`node /Users/regiskian/.agents/plugins/ketchup/dist/bundle/scripts/pre-tool-use.js`
with the JSON candidate commit envelope on stdin; an exit of zero alone does not
prove review approval. No review or commit is claimed here.

2026-10-22, integration: parent inspected the complete preflight, guide/license
manifest, Jev result, and strict-hook source proof. Configured strict review
approved the candidate. Worker commit `9736bfc` is integrated as `cf65315`.
Evidence is retained at `../evidence/ticket11/`. Actual commit review needed
absolute Git `-C` because the tool adapter omitted nested workdir during
candidate extraction. No guardrail was changed. This resolves preflight only;
artwork and native motion verification remain tickets 13/21/25/26.
