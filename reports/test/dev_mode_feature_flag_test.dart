import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/dev_api/presentation/dev_api_entry_button.dart';
import 'package:reports/features/report/data/local_report_store.dart';

void main() {
  testWidgets('disabled developer mode removes its navigation entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => devApiPill(
            context,
            store: const LocalReportStore(),
            enabled: false,
          ),
        ),
      ),
    );

    expect(find.byType(TextButton), findsNothing);
  });
}
