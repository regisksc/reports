# LA Dump Report

An iOS-first Flutter app for anonymous illegal-dumping reports to MyLA311.
The production app uses the City's guest Aura API directly. Photo is optional;
location, description, debris location, and quantity are required.

The native interface follows the Reports design: an orange home, five guided
steps (Location, Items, Photos, Details, Review), and saved report cards with
receipts. Mona Sans is bundled for offline use. Motion follows device settings;
the home gear can reduce motion for the current session. Help explains anonymous
reporting, optional photos, and safe handling of unconfirmed submissions.

## Run and check

From this directory, with Flutter providing Dart >=3.11.4 and <4.0.0:

```sh
flutter pub get
flutter test --coverage test/
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter run -d C4E392DE-D493-40CD-881A-2F6729C93E45
```

Offline tests replace the Portal connection and device plugins. The production
app sends a real City request when Submit is pressed. Keep the Podfile's iOS
15.0 deployment-target override.

## Submission recovery

The app retains reports and receipts locally. An exclusive attempt marker is
written and flushed before dispatch. An unconfirmed result stays distinct from
Not sent and Submitted across ordinary app/process restarts and blocks another
send. A damaged marker also blocks dispatch. This does not guarantee survival
of device power loss.

Known pre-submit failures and explicit rejections without a possible receipt
remain editable. The Portal offers no requester cancellation; contact 3-1-1
when a submitted or unconfirmed request needs investigation.

