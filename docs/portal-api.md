# MyLA311 Portal API: illegal-dumping Submission

> **File:** `docs/portal-api.md`

Agent-facing endpoint reference for the MyLA311 Portal
(`https://myla311.lacity.gov`), happy path only: a guest files an
**Illegal Dumping Item Pickup** request. Built from real browser traffic
(Playwright MCP, 2026-10-21) plus the Portal's own JavaScript, followed by
read-only HTTP replays and one separately recorded helper submission.

## Status at a glance

- The discovery read calls below worked from a plain HTTP client: no browser, no
  cookies, no CSRF token, no CAPTCHA, no bot check (replayed, HTTP 200).
- Discovery stopped before `submitCase`. Its contract is source-derived.
  A later host-side Flutter test invoked the production client and recorded
  accepted result **C-04955177**. The original successful response envelope
  was not retained. Native UI submission and a current City record remain
  unverified; no further submission is authorized.
- There is no separate photo-upload endpoint. Photos travel inside the
  submit call as base64.

Labels used per endpoint:

- **captured**: seen in real browser traffic.
- **replayed**: re-sent read-only from a plain HTTP client, HTTP 200.
- **from source**: contract derived from the Portal's JavaScript.
- **helper result**: a local execution record, distinct from raw City traffic
  and native UI evidence.

## Reusable workspace and current attachment evidence (2026-10-22)

Import the [read-only Postman collection](api-workspace/myla311-read-only.postman_collection.json)
and follow its [workspace guide](api-workspace/README.md). It bootstraps fresh
guest context and chains discovery, questions, coordinate validation, and
duplicate inspection. Dispatch is absent from the executable collection.
Separate [inert contract examples](api-workspace/contract-examples.json) show
source-derived submit/result shapes with explicitly synthetic values.

Fresh read-only HTTP inspection returned 200 for `GET /s/`,
`fetchInitialDetails`, `fetchCaseTypeDetails`, `validateAddress`, and
`getRelatedCaseLst`. The current illegal-dumping configuration advertises
`sImageCount:5`, `sUploadRequired:false`, `sDisplayUpload:true`, and
`sImageFormats:".heic;.heif;.jpeg;.jpg;.pdf;.png;.webp"`. The retained Portal
source maps every ordered attachment to the submit array; this establishes the
advertised/source-supported contract for up to three native photos. It is not
a captured three-photo acceptance, and the server aggregate request-size limit
remains unknown. No City write was performed.

[Attachment provenance](api-workspace/attachment-contract.json) records current
response/source hashes and exact source excerpts, including byte limits,
filename normalization, image encoding, and array ordering. The workspace guide
distinguishes observed/minimized responses from synthetic examples. The original
successful transaction and native-send evidence gaps remain unresolved.

### Native Dev/API inspector

The Home and Help `Dev / API` utility opens a native sheet with a fixed header
and footer. It exposes named illegal-dumping operations on the fixed MyLA311
guest/Aura routes, not arbitrary method, URL, header, or body controls. Opening
the sheet, selecting an operation, and previewing its arguments do not send a
request; a read runs only after **Run 311 request**. The optional
`getRelatedCaseLst` read is separate from the normal `PortalSubmissionClient`
flow.

Report values seed the inspector snapshot and submit preview, but inspector edits
do not modify the saved Report or draft. A `submitCase` write requires review of
the exact destination and payload, followed by explicit confirmation. A confirmed
Service Request and its saved duplicate lock persist across sessions. An existing
unconfirmed or uncertain attempt remains blocked; the operator can check MyLA311
or call 3-1-1, but no automatic retry or inspector override unlock is promised.
Cancel aborts locally and cannot prove the City did not receive a write. The
60-second timeout reports no response, and the inspector does not retry
automatically. Its latest 12 history summaries stay in memory and omit bodies
and session values. No live City write or acceptance was verified for this
inspector.

## Platform

The Portal is a Salesforce Experience Cloud (Aura/LWC) site. There is no
REST or GraphQL API. Every data call is an **Aura Apex action**: one POST
endpoint, with the Apex class and method named inside a form field. Guests
need no login. The page that the browser shows is `/s/report-issue`, a
five-step wizard: Request Type, Contact Details, Request Details, Review
Similar Request, Review and Submit.

## Call order (happy path)

1. `GET /s/`: guest bootstrap (optional but recommended). [captured,
   replayed]
2. `X11_H_ParentController.fetchInitialDetails`: list of request types;
   take the `caseConfigId` of "Illegal Dumping Item Pickup". [captured,
   replayed]
3. `X11_RI_ParentController.fetchCaseTypeDetails`: question config and
   default contact object for that type. [captured, replayed]
4. Location lookup, one of:
   - `LA_AddressController.validateAddress` (latitude and longitude).
     [from source, replayed]
   - `LA_AddressController.validateOriginalAddress` (address text).
     [captured, replayed]
5. `X11_RI_ParentController.getRelatedCaseLst`: duplicate check.
   [captured, replayed]
6. `X11_RI_ParentController.submitCase`: creates the Service Request.
   [from source; later helper result, raw successful envelope unavailable]

Calls 2 to 5 carry no state from one to the next except the values noted
under each endpoint. Photos are only read client-side (step 3 of the
wizard) and sent in call 6.

## Transport: Aura Apex action (all Apex calls)

Common to endpoints 2 to 6.

- Method and URL: `POST https://myla311.lacity.gov/s/sfsites/aura`
  with query `?r=<n>&aura.ApexAction.execute=1`. `r` is a per-page request
  counter (browser starts at 0 and increments). Replays used 1, 2, 3 and
  so on.
- Required header: `Content-Type: application/x-www-form-urlencoded;
  charset=UTF-8`. Nothing else was needed (replayed with only a
  `User-Agent` and `Accept`). The browser also sends `Origin`, `Referer`,
  `x-sfdc-*` and `x-b3-*` headers; none are required.
- Body: four form fields, URL-encoded.

| Field | Value |
| --- | --- |
| `message` | JSON, see below |
| `aura.context` | JSON, see below |
| `aura.pageURI` | `/s/` or the `/s/report-issue?...` path |
| `aura.token` | the literal text `null` (guest) |

`message` (decoded):

```json
{"actions":[{"id":"1;a",
 "descriptor":"aura://ApexActionController/ACTION$execute",
 "callingDescriptor":"UNKNOWN",
 "params":{"namespace":"","classname":"<ApexClass>",
  "method":"<apexMethod>","params":{ "<name>": "<value>" },
  "cacheable":false,"isContinuation":false}}]}
```

`aura.context` (decoded; `fwuid` and the app id come from `GET /s/`):

```json
{"mode":"PROD","fwuid":"<FWUID>","app":"siteforce:communityApp",
 "loaded":{"APPLICATION@markup://siteforce:communityApp":"<APP_ID>"},
 "dn":[],"globals":{},"uad":true}
```

Response (HTTP 200 even for application errors):

```json
{"actions":[{"id":"1;a","state":"SUCCESS",
  "returnValue":{"returnValue":"<JSON TEXT>","cacheable":false},
  "error":[]}],
 "context":{"...":"ignore"}}
```

`returnValue.returnValue` is a **JSON string** that must be parsed again.
It is the Portal envelope:

```json
{"toastPayload":null,"response":<payload>,"message":"<text>",
 "isSuccess":true,"isHTML":null,"errorLogs":null,"ccbCheck":null}
```

`response` is an object for some methods and a second JSON string for
others (noted per endpoint). `isSuccess:false` plus `message` is the
Portal's own error. A non-`SUCCESS` `state` is an Aura error (never seen
in the happy path).

## Endpoint 1: guest bootstrap

- Purpose: mint the guest session values and read the Aura context.
- Label: captured, replayed.
- Request: `GET https://myla311.lacity.gov/s/`, `Accept: text/html`. No
  special headers (replayed with a custom `User-Agent`).
- Response: HTTP 200, `text/html`, about 120 KB. The page is a shell, but
  the HTML contains the Aura context.
- Where each value comes from (URL-decode the HTML first, then match):
  - `fwuid`: regex `"fwuid":"([^"]+)"`. Example `<base64 text, about
    70 chars>` (a framework version id that changes with Salesforce
    releases).
  - `APP_ID`: regex
    `"loaded":\{"APPLICATION@markup://siteforce:communityApp":"([^"]+)"`.
    Example `1893_<22 chars>`.
- Cookies set (all optional, see verdict): `CookieConsentPolicy`,
  `LSKey-c$CookieConsentPolicy`, `renderCtx`. Values redacted.
- Capture ids: browser `003`; plain HTTP `H01` (see Captures index).

## Endpoint 2: request types

- Purpose: list request types; find the Illegal Dumping type id.
- Label: captured, replayed.
- Apex: `X11_H_ParentController.fetchInitialDetails`
- `params`: none. `cacheable`: `true`. `aura.pageURI`: `/s/`.
- `response` (object): `popularCaseList[]`, `isPortalUser`,
  `caseConfigurationList[]` (groups with `caseConfigurations[]`). The
  Illegal Dumping tile is in `popularCaseList` and again in
  `caseConfigurationList`.
- Pick the entry whose `uxType` is `Illegal Dumping Item Pickup`.

Redacted example (one entry):

```json
{"uxType":"Illegal Dumping Item Pickup",
 "uxGroup":"Refuse & Collection Services",
 "uxDescription":"Illegal Dumping refers to high volume ...",
 "pSequence":2,"iconName":"truck-ramp-couch-light",
 "casePopularType":true,"caseEstimation":"0",
 "caseConfigId":"<ENCRYPTED_ID, percent-encoded>"}
```

- `caseConfigId` is an opaque encrypted string (about 64 chars,
  percent-encoded, containing `%2F` and `%2B`). It **differs on every
  call** (random IV) and any fresh value was accepted by endpoint 3, so
  do not cache or hard-code it. The browser puts it in the page URL as
  `c__IssueTypeId` and then URL-decodes it before use.
- Capture ids: browser `011`; plain HTTP `H02`.

## Endpoint 3: case type details (the question form)

- Purpose: the server-driven form: every question, its type, options and
  parent/answer dependency, plus the default contact object.
- Label: captured (response truncated at 300000 chars in the browser
  capture), replayed in full (329 KB).
- Apex: `X11_RI_ParentController.fetchCaseTypeDetails`
- `aura.pageURI`:
  `/s/report-issue?c__IssueTypeId=<percent-encoded id>&c__IsPortalUser=true`
- `params`:

```json
{"caseTypeId":"<caseConfigId, URL-DECODED (raw / and +)>",
 "parentWorkOrderId":"","isSNC":false}
```

- `cacheable`: `false`.
- `response` (object) keys: `scaseTypeLst` (all request type names),
  `objCaseConfigWrapper`, `mapLabels`, `inStages`, `allStages`,
  `contactWrapperResponse`.
- `objCaseConfigWrapper` (important keys): `sId`, `sCaseType`
  (`Illegal Dumping Item Pickup`), `sCasePriority` (`Normal`),
  `sCaseDefaultStatus` (`New`), `sCaseCategory`, `sBoundary`
  (`City Boundary`), `sReportAnonymously` (`true`), `sUploadRequired`
  (`false`), `sImageCount` (`5`), `sImageFormats`
  (`.heic;.heif;.jpeg;.jpg;.pdf;.png;.webp`), `locatorRequired`
  (`false`), `sMapOptional` (`false`), `lstCaseQuestion[]` (210 items),
  `lstBeforeCaseQuestion[]` (empty), `dwpContainerLst` (`null`).
- Each `lstCaseQuestion` item (30 keys). The ones that matter:
  `sFieldtoUpdate` (the target field name and the answer key),
  `sQuestion` (label), `sQuestionType` (`Picklist`, `MultiPicklist`,
  `Text`, `TextArea`, `Phone`, `NumberIncrement`), `brequired`,
  `sDisplay` (visible now), `sHidden`, `sReadOnly`, `sDefaultValue`,
  `sAnswer` (the value the client fills in), `lstOptions[]`
  (`{value,label}`), `iOrder`, `sQuestionConfigId`,
  `sQuestionParentConfigId`, `sParentQuestion`, `sParentAnswer`
  (`;`-separated list of parent answers that make this question appear),
  `lstValidations[]` (`maximumLimit`, `minimumLimit`, `required`).
- `contactWrapperResponse`: the default contact object (all null except
  `sUserName` = the guest user, `bIsLogin:false`, `isAnonymously:null`).

Redacted question example:

```json
{"sQuestionType":"Picklist","sFieldtoUpdate":
 "Provide_Information_On_Suspect__c","brequired":true,"sDisplay":true,
 "sQuestion":"Will you be able to provide information on the Illegal
  Dumping suspect?","lstOptions":[{"value":"","label":"Select any one
  picklist option"},{"value":"No","label":"No"},{"value":"Yes",
  "label":"Yes"}],"iOrder":4,"sAnswer":null,
 "sQuestionConfigId":"a3Req0000004VbdEAE","sParentAnswer":""}
```

- The form is data-driven: answering a question can make child
  questions visible (their `sParentQuestion`/`sParentAnswer` match). See
  "Questions for the happy path" below.
- Capture ids: browser `038` and `039` (both truncated); plain HTTP
  `H03` (full response).

## Endpoint 4a: location by coordinates

- Purpose: resolve a latitude and longitude to a City-verified address
  and its service districts. This is the Portal's pin-drop path.
- Label: from source (laGoogleMap component), replayed with HTTP 200. The
  browser walk used 4b instead.
- Apex: `LA_AddressController.validateAddress`
- `params`:

```json
{"latitude":34.054047,"longitude":-118.24317,
 "addressType":"City Boundary","filterCriteria":""}
```

- `cacheable`: `false`. `aura.pageURI`: any `/s/...` path.
- `response`: a **JSON string** `{"address":{...78 attributes},"location":
  {"x":<lng>,"y":<lat>,"z":0,"spatialReference":{...}}}`. Envelope
  `message` is `Locator Success` and `isSuccess` is `true`.
- `address` keys used by the submit call: `ShortLabel`, `LongLabel`,
  `City`, `Postal`, `X`, `Y`, `Addr_type`. The other attributes are
  district data (council district, sanitation, police, and so on) and
  are forwarded unchanged inside `addressDetails`.
- Failure: `isSuccess:false`, `message` is `Locator Address Invalid`
  (the point is outside the City or has no address) or `Locator Is-Down`.
- The browser then uses `address` as `locatorDetails`, with
  `locatorStatus` set to the envelope `message`.
- Capture id: plain HTTP `H04`. The test point returned a residential
  street address, not reproduced here.

## Endpoint 4b: location by address text

- Purpose: validate a typed or Google-geocoded address against the City
  locator (this is what the Portal's search box and device-location path
  call).
- Label: captured, replayed.
- Apex: `LA_AddressController.validateOriginalAddress`
- `params`: `{"address":"200 N Spring St, Los Angeles, CA 90012"}`
- `response`: a **JSON string** in ArcGIS locator format:
  `{"spatialReference":{...},"candidates":[{"address","location":{"x",
  "y","z"},"score","attributes":{...},"extent":{...}}]}`. The Portal uses
  `candidates[0].attributes` as `locatorDetails`.
- Failure example (captured): `isSuccess:false`, `message` =
  `Locator Address Invalid`, `response` = `Unable to find address for
  the specified location.`
- Redacted success (City Hall, a public address), attributes trimmed:

```json
{"address":"200 N SPRING ST, LOS ANGELES, CA, 90012",
 "location":{"x":-118.24317,"y":34.054047,"z":0.0},"score":100,
 "attributes":{"Status":"M","Score":100,"Addr_type":"PointAddress",
  "LongLabel":"200 N SPRING ST, LOS ANGELES, CA, 90012",
  "ShortLabel":"200 N SPRING ST","AddNum":"200","StName":"SPRING",
  "City":"LOS ANGELES","Postal":"90012","X":-118.24317,"Y":34.054047,
  "SRCouncilDistrictNo":14,"In_City":"YES","...":"~70 more fields"}}
```

- Capture ids: browser `099` (success), `081` (invalid address), `082`
  (coordinates typed as text, success); plain HTTP `H05`.
- Not needed by a native app: the Google Maps JS in the iframe
  (`/GoogleMapPage`, Places Autocomplete and Geocoder, with the Portal's
  own browser key) only turns what the user types into an address string
  and a Google-formatted address. The app has its own coordinates and can
  call 4a directly.

## Endpoint 5: duplicate check

- Purpose: find existing open requests of the same type near the point
  (the "Review Similar Request" step).
- Label: captured, replayed.
- Apex: `X11_RI_ParentController.getRelatedCaseLst`
- `params`:
  `{"caseType":"Illegal Dumping Item Pickup","caseLatitude":34.054047,
  "caseLongitude":-118.24317}` (the `X`/`Y` of the locator result).
- Response when nothing is nearby (captured): `response:null`,
  `message:"No Data Available"`, `isSuccess:false`. The browser then
  skips to Review. The shape when duplicates exist was not seen.
- Capture ids: browser `106`; plain HTTP `H06`.

## Endpoint 6: submit (creates the Service Request)

- Purpose: create the Case and attach photos in one call.
- Label: **from source; later helper result recorded**. No browser submit
  capture or original successful response envelope was recovered. Source:
  LWC `c/laCaseCreationFlow.submitRequest()`, Apex
  import `@salesforce/apex/X11_RI_ParentController.submitCase`.
- Apex: `X11_RI_ParentController.submitCase`. `cacheable`: `false`.
  `aura.pageURI`:
  `/s/report-issue?c__IssueTypeId=<id>&c__IsPortalUser=true`.
- `params` (names exact; types as the Portal sends them):

```json
{"sObjCase":{ "...Case fields, see below..." },
 "sObjContact":"<JSON TEXT>",
 "sCaseQuestionJSON":"<JSON TEXT>",
 "sFileLinks":"<JSON TEXT>",
 "isSNC":false,
 "addressDetails":"<JSON TEXT>"}
```

`sObjCase` is an **object** (not a string) with these fields:

- `Type`: `objCaseConfigWrapper.sCaseType`
  (`Illegal Dumping Item Pickup`).
- `Priority`: `Normal`. `Status`: `New`. (From `sCasePriority` and
  `sCaseDefaultStatus`.) `Hide_from_Web__c`: `sHideFromWeb` (null).
- `Origin`: `Self Service` (set for portal users).
- `Created_From_SNC__c`: `No`. `Tech_SNC_CaseNumber__c`: `""`.
- Location, from the locator result (`locatorDetails`):
  `Street_Address__c` = `ShortLabel`, `City__c` = `City`,
  `Zipcode__c` = `Postal`, `Geolocation__Longitude__s` = `X`,
  `Geolocation__Latitude__s` = `Y`, `State__c` = `CA`,
  `Country__c` = `US`.
- `Address_Status__c`: the envelope `message` of the lookup
  (`Locator Success`; `Locator Is-Down` if the locator failed).
- `Google_Address__c`: for `City Boundary` the Google-formatted address
  string from the map. The app has no Google address; whether the server
  requires it is unknown (see Unknowns).
- `Address_Entry_Method__c`: one of `Device Location`, `Manual Entry`,
  `Autocomplete Suggestion`, `Map Pin`, `Unknown` (set by the map
  iframe).
- `Session_Tracking_ID__c`: a client-made UUID (the Portal keeps it in
  `sessionStorage` under `MyLA311_Portal_Session_ID`).
- Client info (free text; Portal fills them from the browser):
  `Browser_Info__c` (`"<browser> <version>"`), `Platform_Info__c`,
  `Device_Info__c` (`Desktop`, `Mobile` or `Tablet`),
  `Application_Info__c`, `Access_Source__c` (full user agent),
  `CCB_SA_Types__c` (`""` for this type).

`sObjContact` is `JSON.stringify` of the contact object:
`contactWrapperResponse` from endpoint 3, with `isAnonymously` set to
`true` for an anonymous request. Example:

```json
{"sUserName":"<guest user>","sSuite":null,"sStreet":null,"sState":null,
 "sPostalCode":null,"sPhone":null,"sOrganization":null,"sLastName":null,
 "sFirstName":null,"sExtension":null,"sEmail":null,"sCountry":null,
 "sContactId":null,"sCity":null,"sAddress":"","lstValidations":[],
 "isAnonymously":true,"bIsLogin":false}
```

`sCaseQuestionJSON` is `JSON.stringify` of `objCaseConfigWrapper` from
endpoint 3 **without `dwpContainerLst`**, where `lstCaseQuestion` keeps
only items whose `sFieldtoUpdate` is not null, each `iOrder` floored to an
integer, sorted by `iOrder`, and `sAnswer` (and `sDisplay`) filled in. The
browser sends all 210 questions, answered or not.

`sFileLinks` is `JSON.stringify` of an array, one object per photo:

```json
[{"fileData":"<BASE64, no data: prefix>","fileName":"photo.jpg",
  "showImage":true,"showPdf":false,"fileType":"jpg",
  "position":{"lat":34.054047,"lng":-118.24317},"dateTime":"<EXIF date>"}]
```

`position` is `null` when the image has no EXIF GPS; `dateTime` is only
present when EXIF has it. `[]` means no photos.

`addressDetails` is `JSON.stringify(locatorDetails)`, the `address` object
(4a) or `candidates[0].attributes` (4b).

Response (from source): `returnValue.returnValue` parses to the envelope:

```json
{"isSuccess":true,"message":"...",
 "response":{"sCaseNumber":"<SR NUMBER>","sCaseId":"<RECORD ID>",
  "sAppointmentDates":"<JSON TEXT or empty>"}}
```

- **The Service Request number is `response.sCaseNumber`.** The Portal
  treats the call as failed unless `isSuccess` is true **and**
  `response.sCaseNumber` is present; it then shows `message` (or "No error
  details returned") as "Submission failed".
- `sAppointmentDates` is a JSON text array of `{serviceDate,
  workOrderNumber, workType}` (can be empty).

## Photo upload

- There is **no upload endpoint**. Selecting a file in the browser made
  no network call; the file is read in the page (`FileReader`, canvas) and
  held in memory until submit (verified in the walk: only a `blob:` URL
  request, no POST).
- Limits (from source and the `fetchCaseTypeDetails` config):
  - Up to 5 files (`sImageCount`), at most 1 of them a PDF.
  - Extensions: `.jpg .jpeg .png .heic .heif .webp` and `.pdf`.
  - Image up to 10 MB (10,000,000 bytes); PDF up to 3 MB (3,000,000);
    file name at most 60 characters.
  - Encoding the Portal applies: images are redrawn to a canvas and
    re-encoded as JPEG quality 0.5 (`image/jpeg`); if the original is over
    500,000 bytes the longest side is scaled down to 600 px. HEIC/HEIF is
    converted to JPEG in the browser. The base64 payload has the
    `data:...;base64,` prefix removed. `fileType` keeps the original
    extension. PDFs are sent as base64 unchanged.
- Photos are optional for this request type: `sUploadRequired` is `false`
  and no question carries an `imageUpload` validation.
- A client-side image-recognition POST (`AWS_Image_Recognition_URL`) exists
  in the source but was not triggered and is not part of the happy path.

## Questions for the happy path

Fill `sAnswer` on the matching `lstCaseQuestion` item (and set its
`sDisplay` to `true`, as the browser does). Answers used in the walk
(shown on the Review page), as `sFieldtoUpdate` = answer:

- `Residential_Commercial__c` = `Residential` (hidden read-only default,
  already in `sAnswer`).
- `Provide_Information_On_Suspect__c` = `No` (required).
- `Illegally_Dumped_Item_Type__c` = `I'm not sure` (required).
- `Illegally_Dumped_Pickup_Options__c` = `Loose/Miscellaneous Debris`
  (required multi-select; several values are `;`-joined).
- `Location_of_Loose_Miscellaneous_Debris__c` = `Curb` (required, one per
  selected item).
- `No_of_Loose_Miscellaneous_Debris__c` = `1` (required, min 1, max 999).
- `Description` = free text (optional, "Additional Comments", limit 750).
- `ADA_Question__c` = `Decline to Answer` (optional).

Rules found in the config:

- `Provide_Information_On_Suspect__c` = `Yes` reveals required
  `Owner_Phone_Number__c` (a phone number) and optional suspect, vehicle
  and plate fields. Answer `No` to avoid collecting a phone number.
- `Illegally_Dumped_Item_Type__c` options: `Bulky Items`,
  `Electronic Waste`, `Metal/Household Appliances`, `I'm not sure`. Each
  option reveals a required multi-select of item names; every selected
  item then reveals a required `Location_of_<Item>__c` picklist and a
  required `No_of_<Item>__c` number. `I'm not sure` offers 20 generic
  items (Auto Parts, Brush, Clothes, Loose/Miscellaneous Debris, Tires,
  Trash Bags, Wood, and others).
- Location picklist options (same for all items): `Alley`,
  `Center Median`, `Cul-de-Sac`, `Curb`, `Dead End`,
  `Easement/Pedestrian Walk`, `On Bridge`, `Side Street`, `Stairway`,
  `Under Bridge`, `Under Freeway`.
- The two gated-community and mobile-home questions (`Problem_Details_
  Sub_Type__c`, `Marking__c`) appear only for a parent answer that this
  flow never produced; leave them empty.

## Required fields (what the Portal enforces)

- Contact step: **Request Anonymously** must be chosen (`Yes` or `No`).
  - `Yes`: no name, email or phone is needed (`isAnonymously:true`).
  - `No`: first name, last name and email become required; phone is
    optional (source: `contactName:true, contactEmail:true,
    contactPhone:false`).
- Location: a locator-verified address inside the City (`isSuccess:true`).
- Questions: the required ones in the table above, plus any child
  questions revealed by the chosen answers.
- Photo: not required.

## Callable outside a browser: verdict

**Discovery reads replayed successfully; one production-client helper send
reported acceptance. Native UI delivery is unverified.** Read evidence (plain
Python `urllib`, honest `User-Agent`, no browser, 2026-10-21):

- `GET /s/` returned HTTP 200 with the Aura context (capture `H01`).
- Endpoints 2, 3, 4a, 4b and 5 returned HTTP 200 and the same JSON the
  browser got (captures `H02` to `H06`).
- **No cookies needed**: the same call with every cookie dropped returned
  200 and the full payload (capture `H07`).
- **No CSRF token**: `aura.token` is the text `null` for a guest.
- **Framework id not enforced on reads**: a made-up `fwuid` still returned
  200 (capture `H08`). Still extract the real one from `GET /s/`;
  Salesforce can reject a stale value after a release.
- **No CAPTCHA or bot check**: the flow's JavaScript has no reCAPTCHA,
  Turnstile or hCaptcha reference; the home HTML mentions reCAPTCHA only
  inside a Content-Security-Policy allow-list. No Cloudflare or Akamai
  header or challenge appeared.
- The later `reports/tool/execute_live_send.dart` was a host-side
  `flutter_test` script that directly called `PortalSubmissionClient.send`.
  Its log and `sent_record.json` record SR C-04955177, work order W-02685560,
  and service date 2026-10-28. They are helper evidence, not a preserved raw
  successful response or proof that the native screen sent the request.
- Simulator preferences and screenshots show that SR saved locally. A saved
  SR does not establish how it was originally submitted.

## Existing request verification

No City mutation was performed during the follow-up audit. The original
`search_verification.json` failed with `Input details are null`; it did not
verify the request. The Portal actually supplies `params.userSearch` as JSON
text to `X11_ViewServiceRequestsController.getSearchRequests`, with
`isViewAllRequest`, `startDate`, `endDate`, `requestStatus`, `requestType`,
`requestId`, `councilDistrict`, `neighbourhoodCouncilName`, and
`isFollowRequest`.

The corrected HTTP search timed out. The official browser independently
generated that request and its search also remained pending. The detail
action requires the encrypted `caseId` from a search result; the recorded
raw Salesforce ID returned an initialization-vector error. A nearby-open-case
query returned no data, which does not prove the SR is absent.

Current authoritative City verification is therefore blocked. Private
read-only artifacts are in `.playwright-mcp/city-receipt-*`; the helper record
is in `.scratch/illegal-dump-reporter/evidence/live_send/sent_record.json`.
These files contain private/session data and are excluded from Git. No raw
successful response was recovered from the preserved project, browser, or
agent records. Do not resend to resolve missing evidence.

Terms-of-use caution: this is the Portal's non-public API.

## Unknowns

- Original successful `submitCase` request/response, native-send provenance,
  and current authoritative verification of C-04955177. Exact types of
  `NumberIncrement` and `MultiPicklist` answers (source implies a string
  for numbers and `;`-joined text for multi-select).
- Whether the server requires `Google_Address__c`, `Access_Source__c` and
  the other client-info fields, or validates them.
- Whether the server drops answers whose `sDisplay` is false, or needs
  them removed.
- The helper result supports the production client's guest transport, but
  its missing original successful envelope prevents independent replay of
  that evidence without another write.
- `getRelatedCaseLst` response when duplicates exist, and whether a
  duplicate blocks the submit.
- Aura `ERROR` state shape (expired context, stale `fwuid`, request too
  large) and request size limit for five photos.
- `fileName` normalisation helper (`c/laUtils`) was not inspected.
- Rate limits and abuse controls.
- What the City does with `position` EXIF data (the app may send `null`).

## Captures index

Raw captures hold session values and are outside the repo, one file per
call (request and response). Folder:

```text
/private/tmp/claude-501/-Users-regiskian-Git-reports/1db0d6d5-e0e6-4607-abe3-13197d0bcd92/scratchpad/captures/
```

Each id is the filename prefix: `<id>-*.json`.

- Browser (numbers follow the capture order): `003` GET `/s/`, `011`
  `fetchInitialDetails`, `038` and `039` `fetchCaseTypeDetails`, `041`
  map iframe page, `081`, `082` and `099` `validateOriginalAddress`, `106`
  `getRelatedCaseLst`.
- Plain HTTP replays: `H01` GET `/s/`, `H02` `fetchInitialDetails`, `H03`
  `fetchCaseTypeDetails`, `H04` `validateAddress`, `H05`
  `validateOriginalAddress`, `H06` `getRelatedCaseLst`, `H07`
  `fetchInitialDetails` with no cookies, `H08` `fetchInitialDetails` with
  a made-up `fwuid`.
- Portal JavaScript used for the "from source" parts (unescaped LWC
  bundle for the report-issue page):
  `/private/tmp/claude-501/-Users-regiskian-Git-reports/1db0d6d5-e0e6-4607-abe3-13197d0bcd92/scratchpad/bundle-reportissue.unescaped.js`
  (components `c/laCaseCreationFlow`, `c/laFileUpload`, `c/laGoogleMap`,
  `c/laRiContactInformation`, `c/sessionStorage`).
