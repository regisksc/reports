# Submission client interface (fixed)

> **File:** `/Users/regiskian/Git/reports/.scratch/illegal-dump-reporter/client-interface.md`

The client hides session setup, location validation, photo payload, and submit.

**Contract.** `send(Report)` returns a Service Request number or a typed
failure. It never throws for expected failures (rejected, network down,
session expired, unconfirmed delivery), has no retry loops, and mutates nothing: the screen updates
the stored Report from the result.

**Files** (under `/Users/regiskian/Git/reports/reports`):

- `lib/src/portal_submission_client.dart`, co-located with its implementation:

  ```dart
  abstract interface class SubmissionClient {
    Future<SubmissionResult> send(Report report);
  }

  sealed class SubmissionResult {}

  final class SubmissionAccepted extends SubmissionResult {
    SubmissionAccepted(this.serviceRequestNumber);
    final String serviceRequestNumber;
  }

  final class SubmissionFailed extends SubmissionResult {
    SubmissionFailed(this.kind, this.message);
    final SubmissionFailureKind kind;
    final String message; // rejected: the city's reason
  }

  enum SubmissionFailureKind { rejected, network, sessionExpired, uncertain }
  ```

- `lib/src/portal_submission_client.dart`: `PortalSubmissionClient`
  implements `SubmissionClient`, with an optional `http.Client` constructor
  argument. It implements the captured Aura transport documented in
  `/Users/regiskian/Git/reports/docs/portal-api.md`.
- `lib/main.dart`: `ReportApp({SubmissionClient? client})`, default
  `PortalSubmissionClient()`, passed down by constructor to `ReportFlowPage`.
  Offline tests supply a stand-in at `ReportApp`.
- Fakes for tests live in `test/` and are built from the redacted examples in
  the doc.

**Report input.** Location (lat/lng), description, optional photo path, created
time. Contact details are not in the interface unless discovery shows the
Portal requires them; the orchestrator amends this file before Wave 2 if so.

## Amendment 1 (after discovery)

The Portal's `submitCase` requires answers beyond location, description and
photo (see "Questions for the happy path" in
`/Users/regiskian/Git/reports/docs/portal-api.md`). Decision: two real
inputs from the resident plus fixed generic answers. The app never invents a
fact about the dump.

- `Report` gains two nullable fields: `String? debrisLocation` (one of the 11
  Portal labels: Alley, Center Median, Cul-de-Sac, Curb, Dead End,
  Easement/Pedestrian Walk, On Bridge, Side Street, Stairway, Under Bridge,
  Under Freeway) and `int? quantity` (1 to 999). The screen requires both
  before Submit enables. If either is null the client returns
  `SubmissionFailed(SubmissionFailureKind.rejected, 'Missing debris details')`.
- The client fixes these answers: anonymous request (`isAnonymously: true`),
  `Provide_Information_On_Suspect__c` = `No`,
  `Illegally_Dumped_Item_Type__c` = `I'm not sure`,
  `Illegally_Dumped_Pickup_Options__c` = `Loose/Miscellaneous Debris`,
  `Location_of_Loose_Miscellaneous_Debris__c` = `report.debrisLocation`,
  `No_of_Loose_Miscellaneous_Debris__c` = `report.quantity` as text,
  `Description` = `report.description` (max 750 characters).
- No contact data is stored or sent. The photo is optional and travels as
  base64 inside `submitCase`.
- Wave 2 ownership: the client agent owns
  `lib/src/portal_submission_client.dart` and its tests; the flow agent owns
  `lib/src/mobile_report_flow.dart`, `lib/src/report.dart`,
  `lib/src/storage.dart`, and the widget and storage tests.
- Safety: tests and agents never call the live Portal. The only real send is
  the live-send ticket, performed by the app once.

## Amendment 2 (delivery recovery)

After `submitCase` dispatch, a timeout, dropped connection, malformed response,
missing receipt, or contradictory rejection with a receipt is unconfirmed.
The app stores this separately from Not sent and Submitted and offers no retry.
An exclusive, flushed attempt marker precedes dispatch and survives ordinary
app/process restarts. A damaged marker blocks dispatch as well.

Known pre-submit failures and explicit rejections (`isSuccess: false` with
`response: null`)
remain editable and retryable using the same saved row and creation time.
Confirmed receipts are preserved even when marker cleanup fails. Storage errors
block dispatch; unreadable history displays an error instead of an empty list.
Existing `reports_v2` submitted rows and Service Request numbers remain valid.

The historic helper recorded C-04955177, but native-screen send provenance was
not preserved. Ticket 04 remains blocked; this recovery work must not submit
another City request to fill that evidence gap.
