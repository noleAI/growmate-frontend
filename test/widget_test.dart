// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:growmate_frontend/features/auth/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('Welcome page renders core auth actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
    await tester.pump();

    final welcomeTitleVi = find.textContaining('Chào bạn đến với GrowMate');
    final welcomeTitleEn = find.textContaining('Welcome to GrowMate');
    expect(
      welcomeTitleVi.evaluate().isNotEmpty ||
          welcomeTitleEn.evaluate().isNotEmpty,
      isTrue,
    );
    expect(
      find.text('Đăng nhập').evaluate().isNotEmpty ||
          find.text('Log in').evaluate().isNotEmpty,
      isTrue,
    );
    expect(
      find.text('Tạo tài khoản').evaluate().isNotEmpty ||
          find.text('Create account').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
