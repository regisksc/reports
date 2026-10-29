import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('resumes a saved draft with its answers', (tester) async {
    SharedPreferences.setMockInitialValues({
      'service_previews_v1':
          '[{"id":"1","service":"Graffiti Removal","group":"Graffiti","evidence":"anonymous available; optional attachments; advertised limit 5","step":1,"description":"Wall","address":"Main Street","confirmed":false,"named":false,"photos":0}]',
    });
    await tester.pumpWidget(const MaterialApp(home: ServiceHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graffiti Removal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume draft'));
    await tester.pumpAndSettle();
    expect(find.text('Place it on the map.'), findsOneWidget);
    expect(find.text('Main Street'), findsOneWidget);
    await tester.tap(find.text('Save and close'));
    await tester.pumpAndSettle();
    expect(find.text('Resume draft'), findsOneWidget);
  });
}
