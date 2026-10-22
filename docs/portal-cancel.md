# MyLA311 Portal: can a requester cancel a Service Request?

> **File:** `/Users/regiskian/Git/reports/docs/portal-cancel.md`

Initial read-only inspection of the Portal (`https://myla311.lacity.gov`) on
2026-10-21, as a guest. Nothing was created, edited, cancelled or
submitted. No login, no account, no form submitted, no Service Request
number looked up during that inspection. A later read-only lookup of the
existing SR is recorded in the companion API reference. Companion to
`/Users/regiskian/Git/reports/docs/portal-api.md`.

Labels used per fact:

- **page**: seen in the Portal pages in a real browser.
- **captured**: seen in real browser traffic.
- **source**: read in the Portal's own JavaScript, never called.
- **probed**: plain HTTP GET of a Portal page (status code only).
- **FAQ**: published City text (not the Portal's code).

## Verdict

**No.** A guest who filed an anonymous illegal-dumping request through
the API has **no way to cancel or withdraw it through the Portal**. No
cancel, withdraw, close or "no longer needed" control exists for a
requester anywhere in the pages or in the JavaScript that those pages
load, for guests or for logged-in users. "Cancelled" is a status that
City staff set; the requester cannot set it.

Confidence: high for the Portal UI and the client JavaScript. The
server side cannot be proven absent without calling it (see Unknowns).

What the person can do instead: phone 3-1-1 and ask a call-center agent
(see "What the person can do instead"). Whether an agent will cancel on
request is **not stated anywhere the Portal shows**.

## Where a submitted request is looked up or managed

Every place found, and what a guest needs to reach it.

- **All Requests**, `/s/view-service-request` (nav: "All Service
  Requests"). Guest: **yes**. Asks for nothing: no login, no SR number,
  no phone, no email. [page, captured]
  - Public list and map of the first 2000 requests the Portal returns.
    Filters: start date, end date, Request Status, Request Type, Neighborhood
    Council, Council District. Status filter values: `New`, `Workorder
    Created`, `In Progress`, `Potential Duplicate`, `Cancelled`, `Closed`,
    `Reported`. A search box takes a request number.
  - Selecting a request opens a detail card (SR number, reported on,
    closed on, description, location, photos, closure comments,
    resolution). Its only actions are **Follow Request** and **Unfollow
    Request**. Follow asks for an email address in a modal (a logged-in
    user's account email is used instead). The component class defines
    only these handlers: follow, unfollow, photo preview, open case
    number. [source]
- **My Requests**, `/s/view-service-request?q=true` (nav: "My
  Requests"). Guest: **no**. The page code sends a guest back to the
  public All Requests page, and the URL changes to
  `/s/view-service-request`. [source, page, probed] Logged-in users get
  the same component with a "Followed Cases" checkbox. No extra actions
  were found in the code.
- **My Account**, `/s/comm-my-account` (header account menu, logged-in
  only). Guest: **no** (HTTP 404 for a guest). Not inspected: it sits
  behind login. [source, probed]
- **Login**, `/login`. Redirects to Angeleno Account sign-in
  (`login.account.lacity.gov`): an email field, "Continue", "Create an
  Angeleno Account". Not used. [page] The City says an account is "not
  required to use 311" (FAQ below).
- **Submit confirmation** (last step of `/s/report-issue`). Shows
  "Thank you. Your request has been submitted!" and the reference number,
  plus buttons "Create New Request" and "Create New Request At Same
  Address/Location" and an FAQ link. **No cancel, status or follow
  button.** [source: component `c/laRiSubmit`]
- **Review Similar Request** step (`/s/report-issue`). Offers "follow
  an existing request to receive updates" (email) or "create a new
  request". No cancel. [source]
- **City Services Directory**, `/s/faq` (knowledge base). Searches for
  `cancel`, `status` and `withdraw` returned no article about cancelling
  or checking a Service Request (only unrelated items such as LAX flight
  cancellations and claim status). [page]
- **311 Call Center article**, `/s/faq/311-call-center`: phone, hours
  and email, no cancel text. [page]
- **Who To Call**, `/s/who-to-call`: department phone list. The only
  "cancel" is LADBS building inspections, unrelated. [page]
- **Survey**, `/s/survey`: needs parameters. Without them it shows
  "Cannot proceed with this survey. Invalid Details." A satisfaction
  survey, not a request control. [page]
- **Chat button** on every page: "Hello, have a question? Let's chat."
  Not opened (opening could start a messaging session). What an agent
  can do through it is unknown. [page]

Other routes probed over HTTP (guest GET): `/s/` 200, `/s/report-issue`
200, `/s/view-service-request` 200, `/s/faq` 200, `/s/who-to-call` 200,
`/s/survey` 200, `/s/login` 200. HTTP 404: `/s/my-requests`,
`/s/check-status`, `/s/request-status`, `/s/cancel-request`,
`/s/cancel`, `/s/case-detail`, `/s/service-request`, `/s/track-request`,
`/s/my-account`, `/s/profile`, `/s/contact-us`, `/s/help`,
`/s/comm-my-account`. A 404 on a guessed path proves only that the
guest has no page there. [probed]

## Portal JavaScript evidence

Bundles read (all fetched by plain HTTP GET, unescaped, searched, never
executed):

- Page bundle for `/s/view-service-request`: components
  `c/laServiceRequests`, `c/laRiDuplicateCaseDetails`,
  `c/laRiCaseCard`, `c/laMapView`, `c/laPagination`,
  `c/la311FollowRequestModal`, `c/laUtils`, `c/labelsAndConstants`.
- Page bundle for `/s/report-issue` (already held for
  `portal-api.md`): 29 `c/` modules including `c/laCaseCreationFlow`,
  `c/laRiSubmit`, `c/laRiViewSimilarCases`.
- Bootstrap bundle (header, footer): `c/laHeader`,
  `c/laHeaderNavigation`, `c/laFooter`.

Apex methods the Portal's own components import (complete list across
these bundles):

- View page: `X11_ViewServiceRequestsController.intialDetails`,
  `.getSearchRequests`, `.getServiceRequestDetail`;
  `LA_FollowController.createNewFollowRequest`, `.unFollowRequest`.
- Report page: `X11_RI_ParentController.fetchCaseTypeDetails`,
  `.submitCase`, `.getRelatedCaseLst`, `.getCaseTypeId`,
  `.getCaseTypeIdPortalUsr`, `.decryptCaseId`, `.verifyPermitNumber`;
  `LA_AddressController.validateAddress`, `.validateOriginalAddress`,
  `.validateLADWPAddress`, `.getPropertyDetails`, `.getCCBCheck`,
  `.logAddressValidationError`;
  `LA_ArticlesController.getArticleForCaseType`,
  `.getPublishedKnowledgeIdByUrlName`;
  `LA_CustomLookupController.fetchLookupInputResult`, `.fetchRecords`;
  `LA_SncEligibilityService.getCreateEligibility`.
- Header: `LA_HeaderController.getUserDetails`.
- Also seen in traffic on page load: `LA_BannerController.getBannerData`,
  `EmbeddedMessagingController.getBootstrapData` (the chat widget).

**None of them cancels, withdraws, closes or changes the status of a
request.** The only write methods on a Service Request are `submitCase`
(create) and the follow pair (email subscription).

Search results:

- No Apex method, event or handler named like cancel, withdraw, close,
  `updateCase`, `updateStatus` or reopen in the Portal's `c/` modules.
- Every "Cancel" button in the report flow only leaves the wizard, a
  review edit or a modal (for example `handleCancel() { this.close() }`
  in the follow modal) before anything is submitted.
- The word `Cancelled` appears only as a **status constant**
  (`caseStatusConstants.Cancelled`) used to pick the status badge colour,
  and in the status filter list. Other statuses in the same constant:
  `New`, `In Progress`, `Closed`, `Closed Ext-Referred`, `Duplicate
  Confirm`, `Potential Duplicate`, `Workorder Created`, `Reported`.
- The label bundle holds staff-looking labels: `LA311_CloseCase` ("Update
  Case"), `LA311_SelectStatus`, `LA311_ChangeRequestType`,
  `LA311_UpdateDepartment`, `LA311_CaseUpdateSuccess`, `LA311_QuickText`,
  `LA311_ExtDeptContactInfo`. They appear only in the shared
  `c/labelsAndConstants` label list (import, group, map, value). **No
  component loaded by a guest page uses them.** They point to a
  staff-side case screen that this Portal does not expose to guests.
- The report flow has an `isEditCase` flag, but it only keeps the map in
  edit mode when the user goes back to change the location during the
  wizard. It is not an edit of a submitted request.
- The generic Salesforce framework bundle (`aura_prod`/`app.js`, 5.8 MB)
  mentions `cancelRequest` only for unrelated platform actions
  (Analytics query, asset renewal). Not a Portal feature.

## Where the "Cancelled" status comes from

- **FAQ** (page `/myla311/myla311-frequently-asked-questions` on
  `www.lacity.gov`): an anonymous request "may be
  canceled (not completed)" **if the City needs more information and has
  no way to contact you**. A requester who gives an email "will receive an
  email notification for that request when it opens and when it gets
  closed or canceled". So the City cancels, and anonymous requests are
  the ones at risk. [FAQ]
- **Portal text** (graffiti request): "any requests containing
  inaccurate information or failing to meet these specific criteria will
  be cancelled". City action again. [source]
- **Captured data**: the public listing the page loads at start returned
  2000 records; 36 had status `Cancelled` (30 Containers, 4 Service Not
  Complete, 1 recycLA Complaint, 1 Dead Animal Removal; none Illegal
  Dumping Item Pickup). They carry a closed date but **no closure
  comment and no resolution message**, so the Portal does not say who
  cancelled or why. This is one default listing, not a full count.
  [captured]
- Duplicates are handled by the City too: `Potential Duplicate` and
  `Duplicate Confirm` statuses, and the Portal's duplicate step steers
  the requester to "follow" the existing request instead.

## What the person can do instead

- **Phone 3-1-1, or (213) 473-3231** from outside the City. Hours per the
  Portal and the FAQ: Monday to Friday 7:00 am to 7:00 pm; weekends and
  holidays 8:00 am to 4:45 pm; closed Thanksgiving Day and Christmas Day.
  (The City's MyLA311 page says weekends 8 am to 5 pm, and the Portal
  article's hours table shows Sunday as "No Hours" although its text says
  weekends are open. Treat the exact weekend hours as unconfirmed.)
  Give the agent the SR number and ask to withdraw it. The Portal does
  not say agents can cancel by phone; the status exists City-side, which
  makes it likely but unproven. [page, FAQ]
- **Email <311@lacity.org>** (published in the FAQ and in the Portal's 311
  Call Center article). [page, FAQ]
- **Illegal-dumping contacts the Portal shows** (for reporting, not
  documented as cancel paths): LA Sanitation Customer Care
  1-800-773-2489, 24 hours; Illegal dumping in progress: BOSS Enforcement
  Division (213) 847-6000 in business hours, (877) ASK-LAPD after hours.
  [page]
- **Do not file a second request** to withdraw the first. The Portal has
  a "Feedback - General" request type that asks for the Service Request
  number, but it is a feedback form, not a documented cancel path.

## Implications for the app

- Do not offer an in-app Cancel. State before the send that a
  Submission cannot be withdrawn through the Portal.
- After a successful send, show the SR number and the 3-1-1 phone and
  email above as the way to ask for a change.
- Status is readable without login: the public list call
  `X11_ViewServiceRequestsController.getSearchRequests` takes
  `{"userSearch":"<JSON text>"}` with keys `isViewAllRequest`,
  `startDate`, `endDate`, `requestStatus`, `requestType`, `requestId`,
  `councilDistrict`, `neighbourhoodCouncilName`, `isFollowRequest`.
  The call without `requestId` was captured. The follow-up audit called the
  `requestId` search for C-04955177 through HTTP and the official browser;
  neither completed successfully. Response records from the initial list carry
  `caseDetailsObj.caseStatus` among others.
- An optional email on the Submission would give the person "opens,
  closed, cancelled" emails, but it gives up anonymity. Decide with the
  person; the Portal allows both (`Request Anonymously` Yes or No).

## Unknowns

- Whether the server exposes any guest-callable path to change a Case
  status that the UI never uses (a hidden Apex method, or a generic
  Salesforce record update). Not enumerable without calling, and nothing
  was called. General Salesforce platform policy (not verified for this
  org) limits guest profiles to read and create, which would block it.
- Whether a 3-1-1 agent will cancel on request, and what proof they ask
  for from an anonymous requester.
- What the chat widget can do.
- The logged-in My Account page, and whether a logged-in Angeleno user
  sees any extra control on a request they own. No account was created.
- The mobile app (iOS id 6740093512). It is the same Salesforce
  community, so it likely has the same components; not checked.
- Who set `Cancelled` on the 36 listed records, and why.

## Evidence index

Raw files hold public data of other people's requests and Portal
session values, so they stay outside the repo. Folder:

```text
/private/tmp/claude-501/-Users-regiskian-Git-reports/1db0d6d5-e0e6-4607-abe3-13197d0bcd92/scratchpad/cancel/
```

- `g15.txt`, `g15.unescaped.js`: page bundle for
  `/s/view-service-request` (`auraCmpDef` GET).
- `g14.txt`, `g14.unescaped.js`: `bootstrap.js` (header and footer).
- `g4.txt`: `app.js` (Salesforce framework bundle).
- `g3.txt`: `resources.js`.
- `viewsr-list-resp.json`: captured public list response (2000 records).
- `net-viewsr.txt`: network list of the view page load.

Report-issue bundle, unescaped (also used by `portal-api.md`):

```text
/private/tmp/claude-501/-Users-regiskian-Git-reports/1db0d6d5-e0e6-4607-abe3-13197d0bcd92/scratchpad/bundle-reportissue.unescaped.js
```

Browser snapshots (Playwright MCP logs, left in place):
`/Users/regiskian/Git/reports/.playwright-mcp/page-2026-10-21T20-33-05-090Z.yml`
(All Requests), `.../page-2026-10-21T20-35-01-955Z.yml` (Resources
menu), `.../page-2026-10-21T20-35-10-816Z.yml` (login),
`.../page-2026-10-21T20-36-31-084Z.yml` (311 Call Center article).
