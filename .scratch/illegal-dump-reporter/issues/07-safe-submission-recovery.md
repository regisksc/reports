# 07: Safe submission recovery

Status: resolved
Blocked by: 03

## Acceptance

- Distinguish an unsuccessful pre-submit request from an uncertain outcome after submitCase was dispatched. A timeout, dropped connection, invalid reply, or lost response must never be labelled definitely not sent.
- An uncertain outcome disables further sends, survives navigation and app restart, and remains visible in My reports. Never infer no City case from an empty/error lookup alone.
- Retry remains available for a failure known to occur before the City submission. Rejected inputs can be corrected and the saved draft updated without duplicating local rows.
- Preserve the spec's one SubmissionClient, real shipped client, report-first persistence, fixed happy-path answers, and reports_v2 backward compatibility.
- Test each new behavior through the existing public app/client/storage seams before implementing. No live City calls in tests.
- No comments, dead code, fabricated receipts, or new live submission helpers.

## Comments

Audit context: /Users/regiskian/Git/reports/ketchup-plan.md. Original SR C-04955177 may already exist; this ticket must not send it again.

## Current milestone amendment

The implementation now uses a durable, exclusive, flushed attempt marker that
survives ordinary process restart. Corrupt marker data fails closed. A known
receipt is preserved even when cleanup fails. This does not claim power-loss
durability or establish a new City receipt; the historical native-send proof
remains blocked by tickets 04 and 09.
