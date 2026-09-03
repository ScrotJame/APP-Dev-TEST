// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vimes_test/main.dart';

void main() {
  testWidgets('Entry note smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the title and basic elements are rendered.
    expect(find.text('Phiếu Nhập Kho'), findsOneWidget);
    expect(find.text('Thêm dòng'), findsOneWidget);
    expect(find.text('Lưu phiếu'), findsOneWidget);
  });
}
