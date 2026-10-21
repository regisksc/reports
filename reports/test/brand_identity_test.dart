import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/app/report_app.dart';

void main() {
  testWidgets('home header displays the accessible Report Pop logo', (
    tester,
  ) async {
    await tester.pumpWidget(const ReportApp());

    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('reports-brand-logo')),
    );

    expect(
      logo.image,
      isA<AssetImage>().having(
        (asset) => asset.assetName,
        'assetName',
        'assets/brand/reports-pop-horizontal-color.png',
      ),
    );
    expect(logo.semanticLabel, 'Reports');
  });
}
