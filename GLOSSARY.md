# Reports

A mobile app that lets a person report illegal dumping in Los Angeles and send
it to the city's MyLA311 system.

## Language

**Report**:
The record a person creates in the app for one dumping problem: what it is,
where it is, when, and optionally a photo. It stays on the phone with its
delivery state and any confirmed Service Request number.
_Avoid_: Ticket, request, case

**Draft**:
An unfinished Report that a person can continue before sending it to the city.
_Avoid_: Submission, queued request

**Submission**:
A Report accepted by MyLA311. A Report becomes a Submission only when the
city's system confirms it.
_Avoid_: Filing, upload

**Submission unconfirmed**:
The app retained an attempt whose City acceptance was not confirmed. The
person must check the existing request before another send. This state also
survives an ordinary app restart.
_Avoid_: Not sent, failed (neither proves the City did not receive it)

**Service Request**:
The city's own record of a Submission, identified by an SR number. The city
creates it; the app never does.
_Avoid_: Report (that word is the app's local record)

**Receipt**:
The confirmation of an accepted Submission, including its Service Request
number.
_Avoid_: Service Request (the city's record), unconfirmed attempt

**Illegal Dumping Pickup**:
The one MyLA311 request type the app sends. The Submission client holds it as a
constant, so a person never picks a type. There is no Issue Type choice.
_Avoid_: Issue Type, category

**Portal**:
The MyLA311 web app at myla311.lacity.gov, the city's public way to file a
Service Request.
_Avoid_: Website
