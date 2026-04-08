// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/main.dart';

void main() {
  testWidgets('GrowMate starts at welcome auth route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GrowMateApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Chào bạn đến với GrowMate'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
  });
}
