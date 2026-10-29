import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'home header displays the accessible canonical reports wordmark',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ReportApp());
      final logo = find.byKey(const ValueKey('reports-brand-logo'));
      expect(
        {
          'name': tester.widget<Semantics>(logo).properties.label,
          'wordmark': find
              .descendant(of: logo, matching: find.text('reports.'))
              .evaluate()
              .length,
          'pin': find
              .descendant(
                of: logo,
                matching: find.byIcon(Icons.location_on_outlined),
              )
              .evaluate()
              .length,
        },
        {'name': 'Reports', 'wordmark': 1, 'pin': 1},
      );
    },
  );
}
