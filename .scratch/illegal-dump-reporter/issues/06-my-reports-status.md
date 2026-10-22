# 06: My reports shows status

**What to build:** My reports lists each Report with its state (Submitted,
Not sent, or Submission unconfirmed) and any Service Request number. Opening one shows its photo,
description, and status. No editing or deleting.

**Blocked by:** 03: Submit a Report to the city.

**Status:** resolved

- [x] Each Report in the list shows its state and, when submitted, its Service
  Request number.
  (History distinguishes all three states and displays confirmed receipts.)
- [x] Opening a Report shows its photo, description, and status.
  (Tapping navigates to `ReportDetailPage` with status banner, Service Request number, description, photo if available, debris location, item count, and coordinates. Read-only: no edit or delete options.)
- [x] The list and the detail view are covered by a widget test.
  (Public history tests include unreadable storage and missing-photo fallbacks.)

Result: Fully implemented in `history_page.dart`. History exposes the three
submission states, and storage errors remain readable to the resident rather
than being silently discarded.
