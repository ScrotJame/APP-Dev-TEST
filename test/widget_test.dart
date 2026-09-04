import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test for basic UI rendering', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('VIMES WMS')),
        ),
      ),
    );

    expect(find.text('VIMES WMS'), findsOneWidget);
  });
}
