# 05: Light failure handling

**What to build:** A known pre-submit failure or explicit rejection without a
possible receipt shows a plain message, retains an editable Not sent Report,
and offers Retry. An unconfirmed post-dispatch result stays locked under 07.

**Blocked by:** 03: Submit a Report to the city.

**Status:** resolved

- [x] A known failure shows a message and keeps the Report as not sent.
  (Failure text displayed with error styling; saved report state remains `notSent` in storage.)
- [x] Retry sends the same Report again.
  (A "Retry" button resends the same saved row and creation time, including
  corrected description and quantity.)
- [x] One test covers a failed send followed by a retry.
  (Covered by "a known $kind failure allows corrected retry in the same saved
  row" in `submit_flow_test.dart`.)

Result: public flow tests cover correction and same-row retry for known
failures, including `isSuccess: false` with `response: null`. Lost or
contradictory post-submit replies remain unconfirmed and locked.
