import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lvtn_mobile_app/main.dart';

void main() {
  testWidgets('LVTN Restaurant App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LVTNRestaurantApp());

    // Verify that our app starts correctly
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
