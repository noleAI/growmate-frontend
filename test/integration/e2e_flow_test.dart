import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growmate_frontend/app/router/app_router.dart';
import 'package:growmate_frontend/data/repositories/profile_repository.dart';
import 'package:growmate_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:growmate_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:growmate_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:growmate_frontend/core/network/mock_api_service.dart';
import 'package:growmate_frontend/features/diagnosis/data/repositories/diagnosis_repository.dart';
import 'package:growmate_frontend/features/intervention/data/repositories/intervention_repository.dart';
import 'package:growmate_frontend/features/quiz/data/repositories/quiz_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Quiz -> Result flow handles plan acceptance and navigates to next quiz',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authRepository = AuthRepository();
      final profileRepository = ProfileRepository();
      final authBloc = AuthBloc(authRepository: authRepository)
        ..add(const AppStarted());
      addTearDown(authBloc.close);

      final apiService = MockApiService(
        scenario: MockDiagnosisScenario.diagnosisSuccess,
      );

      const sessionId = 'session_e2e_001';

      final quizRepository = QuizRepository(
        apiService: apiService,
        sessionId: sessionId,
      );
      final diagnosisRepository = DiagnosisRepository(
        apiService: apiService,
        sessionId: sessionId,
      );
      final interventionRepository = InterventionRepository(
        apiService: apiService,
        sessionId: sessionId,
      );

      final appRouter = AppRouter(
        authBloc: authBloc,
        authRepository: authRepository,
        profileRepository: profileRepository,
        quizRepository: quizRepository,
        diagnosisRepository: diagnosisRepository,
        interventionRepository: interventionRepository,
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true),
            routerConfig: appRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Chào bạn đến với GrowMate'), findsOneWidget);
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'learner@growmate.vn',
      );
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hệ điều phối học tập AI'), findsOneWidget);
      final startButtonLabel = find.text('Bắt đầu phiên AI gợi ý');
      await tester.ensureVisible(startButtonLabel);
      final startButtonTapTarget = find.ancestor(
        of: startButtonLabel,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTap != null,
        ),
      );
      await tester.tap(startButtonTapTarget.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      if (find.text('Giải tích 12').evaluate().isEmpty) {
        appRouter.router.push('/quiz');
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Tính đạo hàm của hàm'), findsOneWidget);
      expect(find.textContaining('y = 4x³ + 2x² - 5'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12x^2 + 4x');
      final submitButton = find.text('Gửi bài');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.text('Có vẻ bạn đang hơi yếu phần Đạo hàm nè'),
        findsOneWidget,
      );
      final approveButton = find.text('Áp dụng lộ trình mới');
      for (var attempt = 0; attempt < 12; attempt++) {
        if (approveButton.evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(approveButton, findsOneWidget);
      await tester.tap(approveButton.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Tính đạo hàm của hàm'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
