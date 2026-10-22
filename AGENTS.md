# reports

The Flutter app is in `reports/`, with Git initialized at the repository root.
iOS simulator is the default development target. Preserve local untracked
files when switching branches.

## Challenge

Interview challenge, one-hour budget: redesign the MyLA311 illegal-dumping web
portal as a mobile-first app that does exactly what the portal does, over the
portal's existing non-public APIs, by reverse-engineering them. The app sends
real submissions to the city. Scope is **illegal dumping only**; other issue
types need an explicit ask.

**Done** means the native app itself performs the whole job against the real
city system. A mock, a clipboard handoff, or opening the browser is not done.

## Deliverable first

The deliverable is one real illegal-dumping Submission, built from the portal's
own network traffic. Order of work:

1. Open the illegal-dumping flow in a browser with network capture on
   using the available browser tools. Walk it
   to the submit step and stop there. Go fast, happy path only: no time box,
   no edge cases. Report the captured submit request or the exact blocker.
2. Write `docs/portal-api.md`: a Swagger-style endpoint reference in markdown
   for agents (method, URL, headers, body, response, call order, and how
   session or auth tokens are minted).
3. Build the smallest app screen that calls it through one Submission client,
   and delete the clipboard handoff.
4. Send exactly one real Submission, performed by the app itself (an agent may
   drive it), on a real dumping location the user supplies. Never send a
   second without checking first whether the first created a Service Request.

Until step 2 exists, report Submission as **unverified**. A green
`flutter analyze` or `xcodebuild` proves the build, not the product.

## Working rules

- Questions the portal can answer (does an endpoint exist, what does the page
  call) are investigated in the browser, never put to the user. Skip grilling
  interviews: the challenge, scope, and deliverable are stated above.
- The user's latest correction overrides the plan until revoked. A bare
  "continue" resumes the order under Deliverable first, not the last thread.
- Read the log or process list right before reporting status. Report what ran,
  not what should have.
- Speed over polish: build the happy path first and prove it with the live
  send. Other cases only if cheap.
- No `sleep` polling. Stop processes by PID after listing what matches; never
  use a broad `pkill -f`.

## Portal facts

- Browser traffic and Portal JavaScript establish Salesforce Aura guest
  actions. Read calls replay successfully; see docs/portal-api.md for exact
  transport, bootstrap, location, questions, photo payload, and submit contract.
- One host-side test helper recorded accepted SR C-04955177. Its original
  successful response and native UI send provenance were not preserved.
  Corrected City read-only verification remains blocked. See tickets 04/09.
- Do not send another request to fill this evidence gap. Never execute the
  historical live-send helpers during tests or verification.

## App state

- The shipped entry point uses PortalSubmissionClient for anonymous illegal
  dumping, with optional photo, GPS, required debris answers, and description.
  No category picker, browser handoff, or clipboard handoff remains.
- Reports use the `reports_v2` shared_preferences shape. Preserve existing
  submitted rows and SR numbers when extending submission state.
- Ticket 07 covers interrupted-send recovery and duplicate prevention;
  ticket 08 covers full coverage, formatting, analysis, and native verification.

## Run and build gotchas

- iOS is the target; skip Android builds unless asked.
- `reports/ios/Podfile` forces every pod to deployment target 15.0 in
  `post_install`. Plugin podspecs declare 11.0 to 13.0 and Xcode rejects those.
  Keep the override.
- Select an available simulator with `flutter devices`.
  `flutter run -d <device-id>` stays attached and blocks the shell, so start it
  detached with output to a log file and read the log. macOS has no `timeout`
  command.

## Agent skills

### Issue tracker

Local markdown under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five roles (`needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at root. See
`docs/agents/domain.md`.
