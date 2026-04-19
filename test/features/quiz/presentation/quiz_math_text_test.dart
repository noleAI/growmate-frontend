import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growmate_frontend/features/quiz/presentation/widgets/quiz_math_text.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets(
    'renders mixed prose and math question stems as plain text when requested',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          const QuizMathText(
            text: 'Cho y = 2 sin x + 3 cos x. Xét tính đúng sai.',
            preferPlainTextForMixedContent: true,
          ),
        ),
      );

      expect(find.byType(Math), findsNothing);
      expect(
        find.text('Cho y = 2 sin x + 3 cos x. Xét tính đúng sai.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('keeps rendering pure math expressions with Math widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(const QuizMathText(text: 'f(x) = x^2 + 1')),
    );

    expect(find.byType(Math), findsOneWidget);
  });
}
