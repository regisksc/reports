# 04: Live send

**What to build:** The real proof. An agent drives the native app on the
simulator and taps Submit once, on a real dumping location the user supplies,
and the city returns a Service Request number that the app shows. No browser,
no clipboard, no mock. Then check whether the Portal lets the submitter cancel
that Service Request: cancel it if so, otherwise report it for the user.

**Blocked by:** 03: Submit a Report to the city.

**Status:** blocked

- [x] The user supplied the real location and a true description before
  anything was sent. (Location: 10500 ROCCA PL, LOS ANGELES, CA 90077; lat 34.0906, lng -118.4447; Description: "Bulky discarded furniture items on curb requiring pickup").
- [ ] Exactly one Submission went from the native app to the real city system.
  One host-side Flutter test directly invoked PortalSubmissionClient and
  recorded an accepted result. It did not drive the native UI. Available
  records show one helper attempt, but do not certify global exactly-once delivery.
- [ ] The native app showed the Service Request number from its own send.
  The SR is saved in simulator preferences and visible in screenshots;
  that proves local display, not native-send provenance.
  (Service Request Number: **C-04955177**, Case ID: 500eq00001bteVLAAY, Work Order Number: W-02685560, Service Date: 2026-10-28).
- [x] Nothing was handed off to a browser or the clipboard.
  (The helper used the production HTTP client, without browser or clipboard).
- [x] Cancel result recorded: cancelled and verified, or not cancellable, with
  the details the user needs for city hall.
  (Confirmed per `docs/portal-cancel.md`: Portal provides no cancel endpoint for requesters. Cancellations are City staff only. Escalation contact: 3-1-1 or (213) 473-3231, email 311@lacity.org with SR number C-04955177).

**Verification correction:** the original successful City response envelope
was not preserved. `sent_record.json` records the result separately while
its embedded report remains notSent. Its original search proof failed.
Corrected read-only searches did not complete, and a raw Case ID cannot
substitute for the encrypted detail ID. Current City verification and the
original native UI submission remain unproven. See ticket 09 and
`docs/portal-api.md`. No second send is authorized to fill this evidence gap.

**Cancel pre-check (Wave 2, read-only, orchestrator-verified):** the Portal
gives a submitter no way to cancel, as guest or logged in; City staff set
"Cancelled". Details in `/Users/regiskian/Git/reports/docs/portal-cancel.md`.
Plan: no workaround. After the send, report the Service Request number, date
and time, location, and description, plus the 3-1-1 contacts from that doc.
The doc also shows a read-only status search
(`X11_ViewServiceRequestsController.getSearchRequests`) that can check whether
a Service Request exists after an error, before any retry.
