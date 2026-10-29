import 'package:reports/features/report/data/local_report_store.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as gc;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reports/features/report/presentation/report_flow_page.dart';
import 'package:reports/features/report/presentation/location_map.dart';
import 'package:reports/features/report/data/portal_submission_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const testStore = LocalReportStore();

void main() {
  late PathProviderPlatform originalPaths;
  late Directory support;
  late UrlLauncherPlatform originalLauncher;
  late _Launcher launcher;
  late _Lookup lookup;
  setUp(() {
    originalPaths = PathProviderPlatform.instance;
    Directory('.dart_tool').createSync(recursive: true);
    support = Directory('.dart_tool').createTempSync('map-test-');
    PathProviderPlatform.instance = _Paths(support.path);
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    lookup = _Lookup();
    gc.GeocodingPlatformFactory.instance = _LookupFactory(lookup);
  });
  tearDown(() {
    PathProviderPlatform.instance = originalPaths;
    UrlLauncherPlatform.instance = originalLauncher;
    support.deleteSync(recursive: true);
  });
  testWidgets('address search waits two seconds after the final edit', (
    tester,
  ) async {
    lookup.pending = Completer<List<gc.Location>>();
    final selected = <({double latitude, double longitude})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMap(
            position: null,
            enabled: true,
            onSelected: selected.add,
          ),
        ),
      ),
    );
    final address = find.byKey(const Key('report-address'));
    final outcomes = <String, Object?>{
      'searchButton': find
          .widgetWithText(OutlinedButton, 'Search')
          .evaluate()
          .length,
    };
    await tester.enterText(address, '200 N Spring');
    await tester.pump(const Duration(milliseconds: 1999));
    outcomes['beforeFirstDeadline'] = List<String>.of(lookup.requests);
    await tester.enterText(address, '200 N Spring St');
    await tester.pump(const Duration(milliseconds: 1999));
    outcomes['beforeResetDeadline'] = List<String>.of(lookup.requests);
    await tester.pump(const Duration(milliseconds: 1));
    outcomes['atResetDeadline'] = List<String>.of(lookup.requests);
    lookup.pending.complete([
      gc.Location(latitude: 34.053722, longitude: -118.242810),
    ]);
    await tester.pumpAndSettle();
    outcomes['selected'] = selected;
    expect(outcomes, {
      'searchButton': 0,
      'beforeFirstDeadline': <String>[],
      'beforeResetDeadline': <String>[],
      'atResetDeadline': ['200 N Spring St, Los Angeles, CA'],
      'selected': [(latitude: 34.053722, longitude: -118.242810)],
    });
  });

  testWidgets('editing during lookup ignores the superseded result', (
    tester,
  ) async {
    lookup.pending = Completer<List<gc.Location>>();
    final first = lookup.pending;
    final selected = <({double latitude, double longitude})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMap(
            position: null,
            enabled: true,
            onSelected: selected.add,
          ),
        ),
      ),
    );
    final address = find.byKey(const Key('report-address'));
    final outcomes = <String, Object?>{};
    await tester.enterText(address, '200 N Spring St');
    await tester.pump(const Duration(seconds: 2));
    outcomes['editableDuringLookup'] = tester
        .widget<TextField>(address)
        .enabled;
    lookup.pending = Completer<List<gc.Location>>();
    await tester.enterText(address, 'Main St & 1st St');
    first.complete([gc.Location(latitude: 35, longitude: -119)]);
    await tester.pump();
    outcomes['afterSupersededResponse'] = List.of(selected);
    await tester.pump(const Duration(seconds: 2));
    lookup.pending.complete([gc.Location(latitude: 34.05, longitude: -118.24)]);
    await tester.pumpAndSettle();
    outcomes['requests'] = lookup.requests;
    outcomes['selected'] = selected;
    expect(outcomes, {
      'editableDuringLookup': true,
      'afterSupersededResponse': <Object>[],
      'requests': [
        '200 N Spring St, Los Angeles, CA',
        'Main St & 1st St, Los Angeles, CA',
      ],
      'selected': [(latitude: 34.05, longitude: -118.24)],
    });
  });

  testWidgets('disabling the map cancels a scheduled address lookup', (
    tester,
  ) async {
    final selected = <({double latitude, double longitude})>[];
    Widget map(bool enabled) => MaterialApp(
      home: Scaffold(
        body: LocationMap(
          position: null,
          enabled: enabled,
          onSelected: selected.add,
        ),
      ),
    );
    await tester.pumpWidget(map(true));
    await tester.enterText(
      find.byKey(const Key('report-address')),
      '200 N Spring St',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(map(false));
    await tester.pump(const Duration(seconds: 2));
    expect(
      {
        'requests': lookup.requests,
        'selected': selected,
        'error': tester.takeException(),
      },
      {'requests': <String>[], 'selected': <Object>[], 'error': null},
    );
  });

  testWidgets('disposing the map cancels a scheduled address lookup', (
    tester,
  ) async {
    final selected = <({double latitude, double longitude})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationMap(
            position: null,
            enabled: true,
            onSelected: selected.add,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('report-address')),
      '200 N Spring St',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(
      {
        'requests': lookup.requests,
        'selected': selected,
        'error': tester.takeException(),
      },
      {'requests': <String>[], 'selected': <Object>[], 'error': null},
    );
  });

  testWidgets(
    'a resident chooses a map point that reaches Review and the City contract',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      rootBundle.evict('assets/illegal_dumping_items.json');
      await tester.runAsync(
        () => rootBundle.loadString('assets/illegal_dumping_items.json'),
      );
      final portal = _SyntheticPortal();
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFlowPage(
            store: testStore,
            client: PortalSubmissionClient(httpClient: portal.client),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var turn = 0; turn < 100; turn++) {
          await Future<void>(() {});
          await tester.pump();
          if (tester
                  .widget<OutlinedButton>(
                    find.widgetWithText(OutlinedButton, 'Use my location'),
                  )
                  .onPressed !=
              null) {
            break;
          }
        }
      });
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, '© OpenStreetMap contributors'),
        findsOneWidget,
      );
      final attribution = find.widgetWithText(
        TextButton,
        '© OpenStreetMap contributors',
      );
      await tester.ensureVisible(attribution);
      await tester.pumpAndSettle();
      await tester.tap(attribution);
      await tester.pumpAndSettle();
      expect(launcher.url, 'https://www.openstreetmap.org/copyright');
      expect(launcher.mode, PreferredLaunchMode.externalApplication);
      launcher.opened = false;
      await tester.tap(attribution);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not open map licence.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      launcher.failure = true;
      await tester.tap(attribution);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not open map licence.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      await tester.ensureVisible(find.byType(FlutterMap));
      final originalZoom = MapCamera.of(
        tester.element(find.byType(TileLayer)),
      ).zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(
        MapCamera.of(tester.element(find.byType(TileLayer))).zoom,
        originalZoom + 1,
      );
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(
        MapCamera.of(tester.element(find.byType(TileLayer))).zoom,
        originalZoom,
      );
      await tester.tapAt(
        tester.getTopLeft(find.byType(FlutterMap)) + const Offset(80, 80),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(FlutterMap), const Offset(80, 30));
      await tester.pumpAndSettle();
      final center = MapCamera.of(
        tester.element(find.byType(TileLayer)),
      ).center;
      expect(center.latitude, isNot(34.054047));
      await tester.ensureVisible(find.text('Use map center'));
      await tester.tap(find.text('Use map center'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}',
        ),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join('\n'),
      );
      final retained = await tester.runAsync(testStore.loadDraft);
      expect(retained, isNotNull);
      expect(retained!.latitude, center.latitude);
      expect(retained.longitude, center.longitude);
      expect(retained.step, 0);
      expect(portal.submitted, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFlowPage(
            store: testStore,
            client: PortalSubmissionClient(httpClient: portal.client),
            draft: retained,
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var turn = 0; turn < 100; turn++) {
          await Future<void>(() {});
          await tester.pump();
          if (tester.widget<FilledButton>(continueButton).onPressed != null) {
            break;
          }
        }
      });
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}',
        ),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 6 · Items'), findsOneWidget);
      await _waitFor(
        tester,
        () => find.text('Loose / miscellaneous debris').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Loose / miscellaneous debris'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loose / miscellaneous debris'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Curb').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('item-quantity-Loose/Miscellaneous Debris')),
        '1',
      );
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic map contract test',
      );
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Without contact details'));
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      final coordinates =
          '${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}';
      expect(find.text(coordinates), findsOneWidget);
      await tester.tap(find.text('Submit'));
      await tester.runAsync(() async {
        for (
          var turn = 0;
          turn < 10000 && find.text('SR-SYNTHETIC-MAP-ONLY').evaluate().isEmpty;
          turn++
        ) {
          await Future<void>(() {});
          await tester.pump();
        }
      });
      expect(find.text('SR-SYNTHETIC-MAP-ONLY'), findsOneWidget);
      expect(portal.validation!['latitude'], center.latitude);
      expect(portal.validation!['longitude'], center.longitude);
      expect(portal.submitted!['Geolocation__Latitude__s'], center.latitude);
      expect(portal.submitted!['Geolocation__Longitude__s'], center.longitude);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a resident can search an address or intersection before Review',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      rootBundle.evict('assets/illegal_dumping_items.json');
      await tester.runAsync(
        () => rootBundle.loadString('assets/illegal_dumping_items.json'),
      );
      final portal = _SyntheticPortal();
      await tester.pumpWidget(
        MaterialApp(
          home: ReportFlowPage(
            store: testStore,
            client: PortalSubmissionClient(httpClient: portal.client),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var turn = 0; turn < 100; turn++) {
          await Future<void>(() {});
          await tester.pump();
          if (tester
                  .widget<OutlinedButton>(
                    find.widgetWithText(OutlinedButton, 'Use my location'),
                  )
                  .onPressed !=
              null) {
            break;
          }
        }
      });
      await tester.pumpAndSettle();

      final address = find.byKey(const Key('report-address'));
      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(address, findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Search'), findsNothing);
      await tester.enterText(address, '');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(lookup.requests, isEmpty);

      lookup.pending = Completer<List<gc.Location>>();
      await tester.enterText(address, '200 N Spring St');
      await tester.pump();
      await tester.enterText(
        address,
        '${tester.widget<TextField>(address).controller!.text} ',
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Searching…'), findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
      lookup.pending.complete([]);
      await tester.pumpAndSettle();
      expect(find.textContaining('No match found.'), findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      lookup.pending = Completer<List<gc.Location>>();
      await tester.enterText(
        address,
        '${tester.widget<TextField>(address).controller!.text} ',
      );
      await tester.pump(const Duration(seconds: 2));
      lookup.pending.completeError(StateError('Synthetic network unavailable'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Address search is unavailable.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      lookup.pending = Completer<List<gc.Location>>();
      await tester.enterText(
        address,
        '${tester.widget<TextField>(address).controller!.text} ',
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.ensureVisible(find.text('Use map center'));
      await tester.pump();
      await tester.tap(find.text('Use map center'));
      await tester.pumpAndSettle();
      lookup.pending.complete([gc.Location(latitude: 35, longitude: -119)]);
      await tester.pumpAndSettle();
      expect(find.text('34.054047, -118.243170'), findsOneWidget);

      await tester.ensureVisible(address);
      await tester.pumpAndSettle();
      await tester.enterText(address, 'W 1st St & S Main St');
      lookup.pending = Completer<List<gc.Location>>();
      await tester.pump(const Duration(seconds: 2));
      lookup.pending.complete([
        gc.Location(latitude: 34.061234567, longitude: -118.245678912),
      ]);
      await tester.pumpAndSettle();
      expect(lookup.requests.last, 'W 1st St & S Main St, Los Angeles, CA');
      expect(find.text('34.061235, -118.245679'), findsOneWidget);
      expect(
        find.text('Selected location · not City verified'),
        findsOneWidget,
      );

      lookup.pending = Completer<List<gc.Location>>();
      await tester.enterText(
        address,
        '${tester.widget<TextField>(address).controller!.text} ',
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      lookup.pending.complete([gc.Location(latitude: 36, longitude: -120)]);
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 6 · Items'), findsOneWidget);
      await _waitFor(
        tester,
        () => find.text('Loose / miscellaneous debris').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(find.text('Loose / miscellaneous debris'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loose / miscellaneous debris'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Curb').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('item-quantity-Loose/Miscellaneous Debris')),
        '1',
      );
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip photo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Synthetic intersection lookup test',
      );
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Without contact details'));
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('34.061235, -118.245679'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      await tester.runAsync(() async {
        for (
          var turn = 0;
          turn < 10000 && find.text('SR-SYNTHETIC-MAP-ONLY').evaluate().isEmpty;
          turn++
        ) {
          await Future<void>(() {});
          await tester.pump();
        }
      });
      expect(find.text('SR-SYNTHETIC-MAP-ONLY'), findsOneWidget);
      expect(portal.validation!['latitude'], 34.061234567);
      expect(portal.validation!['longitude'], -118.245678912);
      expect(portal.submitted!['Geolocation__Latitude__s'], 34.061234567);
      expect(portal.submitted!['Geolocation__Longitude__s'], -118.245678912);
      expect(tester.takeException(), isNull);
    },
  );
}

class _SyntheticPortal {
  Map<String, Object?>? validation;
  Map<String, Object?>? submitted;
  late final http.Client client = MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(
        '{"fwuid":"synthetic-fwuid","loaded":{"APPLICATION@markup://siteforce:communityApp":"synthetic-app"}}',
        200,
      );
    }
    final form = Uri.splitQueryString(request.body);
    final message = jsonDecode(form['message']!) as Map<String, Object?>;
    final action = (message['actions']! as List).single as Map<String, Object?>;
    final call = action['params']! as Map<String, Object?>;
    final params = call['params']! as Map<String, Object?>;
    Object? payload;
    switch (call['method']) {
      case 'fetchInitialDetails':
        payload = {
          'popularCaseList': [
            {
              'uxType': 'Illegal Dumping Item Pickup',
              'caseConfigId': 'synthetic-type',
            },
          ],
        };
      case 'fetchCaseTypeDetails':
        payload = {
          'objCaseConfigWrapper': {
            'sCaseType': 'Illegal Dumping Item Pickup',
            'lstCaseQuestion': [
              {
                'sQuestionId': 'residential',
                'sFieldtoUpdate': 'Residential_Commercial__c',
                'sQuestionType': 'Picklist',
                'sParentQuestionId': null,
                'sParentAnswer': '',
                'sAnswer': 'Residential',
                'sDefaultValue': 'Residential',
                'sReadOnly': true,
                'sHidden': true,
              },
              {
                'sQuestionId': 'suspect',
                'sFieldtoUpdate': 'Provide_Information_On_Suspect__c',
                'sQuestionType': 'Picklist',
                'sParentQuestionId': null,
                'sParentAnswer': '',
                'lstOptions': [
                  {'value': 'No'},
                ],
              },
              {
                'sQuestionId': 'family',
                'sFieldtoUpdate': 'Illegally_Dumped_Item_Type__c',
                'sQuestionType': 'Picklist',
                'sParentQuestionId': 'suspect',
                'sParentAnswer': 'Yes;No',
                'lstOptions': [
                  {'value': "I'm not sure"},
                ],
              },
              {
                'sQuestionId': 'selection',
                'sFieldtoUpdate': 'Illegally_Dumped_Pickup_Options__c',
                'sQuestionType': 'MultiPicklist',
                'sParentQuestionId': 'family',
                'sParentAnswer': "I'm not sure",
                'lstOptions': [
                  {'value': 'Loose/Miscellaneous Debris'},
                ],
              },
              {
                'sQuestionId': 'placement',
                'sFieldtoUpdate': 'Location_of_Loose_Miscellaneous_Debris__c',
                'sQuestionType': 'Picklist',
                'sParentQuestionId': 'selection',
                'sParentAnswer': 'Loose/Miscellaneous Debris',
                'lstOptions': [
                  {'value': 'Curb'},
                  {'value': 'Alley'},
                ],
              },
              {
                'sQuestionId': 'quantity',
                'sFieldtoUpdate': 'No_of_Loose_Miscellaneous_Debris__c',
                'sQuestionType': 'NumberIncrement',
                'sParentQuestionId': 'selection',
                'sParentAnswer': 'Loose/Miscellaneous Debris',
              },
              {
                'sQuestionId': 'description',
                'sFieldtoUpdate': 'Description',
                'sQuestionType': 'TextArea',
                'sParentQuestionId': null,
                'sParentAnswer': '',
              },
            ],
          },
          'contactWrapperResponse': <String, Object?>{},
        };
      case 'validateAddress':
        validation = params;
        payload = jsonEncode({
          'address': {
            'X': params['longitude'],
            'Y': params['latitude'],
            'LongLabel': 'SYNTHETIC LOCATION',
            'ShortLabel': 'SYNTHETIC LOCATION',
            'City': 'LOS ANGELES',
            'Postal': '90012',
          },
        });
      case 'submitCase':
        submitted = params['sObjCase']! as Map<String, Object?>;
        payload = {'sCaseNumber': 'SR-SYNTHETIC-MAP-ONLY'};
      default:
        throw StateError('Unexpected synthetic Portal method');
    }
    return http.Response(
      jsonEncode({
        'actions': [
          {
            'state': 'SUCCESS',
            'returnValue': {
              'returnValue': jsonEncode({
                'isSuccess': true,
                'message': 'Synthetic fixture',
                'response': payload,
              }),
            },
          },
        ],
      }),
      200,
    );
  });
}

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String> getApplicationSupportPath() async => path;
}

class _Launcher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  String? url;
  PreferredLaunchMode? mode;
  bool opened = true;
  bool failure = false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    mode = options.mode;
    if (failure) throw StateError('Synthetic unavailable browser');
    return opened;
  }
}

class _Lookup extends gc.Geocoding {
  _Lookup() : super.implementation(const gc.GeocodingCreationParams());
  final requests = <String>[];
  Completer<List<gc.Location>> pending = Completer<List<gc.Location>>();

  @override
  Future<List<gc.Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) {
    requests.add(address);
    return pending.future;
  }
}

class _LookupFactory extends gc.GeocodingPlatformFactory {
  _LookupFactory(this.lookup);
  final _Lookup lookup;

  @override
  gc.Geocoding createGeocoding(gc.GeocodingCreationParams params) => lookup;
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var turn = 0; turn < 10000 && !ready(); turn++) {
      await Future<void>(() {});
      await tester.pump();
    }
  });
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}
