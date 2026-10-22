# 01: Portal API doc

**What to build:** A markdown endpoint reference for agents, in the style of
Swagger, for everything the Portal's illegal-dumping flow calls to send a
Submission. Per endpoint: purpose, method, URL, required headers, request
body, response shape, and a redacted real example. Also the order of calls and
how any session, token, or context id is obtained. Build it from real network
traffic: drive the flow on the live Portal with Playwright MCP, filling every
step with a photo and a location, while Chrome DevTools MCP records the
network. Walk to the submit step and stop there. Go fast: no time box, happy
path only, no error responses or edge cases. Write the doc as soon as the
happy path is clear. If the API cannot be called from outside a browser,
record the exact blocker with evidence and ask the user.

**Blocked by:** None (can start immediately).

**Status:** blocked

- [x] The doc lists every happy-path endpoint in call order, each with method,
  URL, headers, request body, response shape, and a redacted example. (The
  submit call is from source, so its example is reconstructed, not real.)
- [x] It says how a session or guest context is established and where each
  token or id comes from. (`GET /s/` gives `fwuid` and app id; `aura.token`
  is `null`; no cookies needed, replay H07.)
- [x] It covers the location or address lookup, the photo upload, the submit
  call, and the Service Request number in the response. (Photos have no
  endpoint: base64 inside `submitCase`. Number is `response.sCaseNumber`,
  from source.)
- [ ] Every endpoint came from captured traffic. Nothing is guessed.
  Read calls were captured/replayed. The submit contract is source-derived;
  one production-client helper recorded SR C-04955177, but its successful
  response envelope and native-send provenance were not preserved.
- [x] The final submit was not sent and no Service Request was created.
  (0 `submitCase` requests among the 106 calls captured; the walk stopped
  on Review & Submit and left the page.)
- [x] No personal data appears in the doc. (Test address is City Hall; the
  gate grep for emails, phones, cookies and tokens returned no hits.)

**Result:** Doc written at `/Users/regiskian/Git/reports/docs/portal-api.md`.
Portal is Salesforce Aura; all read calls work from a plain HTTP client (no
cookies, CSRF or CAPTCHA). The submit contract is source-derived with a later
helper result; native delivery and current City verification remain unverified.

**Orchestrator:** verified the doc by reading it, a gate grep, and a scan of
the 40 saved captures (no `submitCase` request among them). The user's
live-send coordinates were redacted from the examples. Box 4 stays open on
purpose: capturing `submitCase` would mean sending it. Ticket 04 was reopened
after its helper execution was incorrectly described as native UI delivery.
The follow-up evidence and corrected read-only lookup are recorded in ticket
09 and the API reference. Do not create another request to fill the gap.
