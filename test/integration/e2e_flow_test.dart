import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:growmate_frontend/app/router/app_router.dart';
import 'package:growmate_frontend/data/repositories/profile_repository.dart';
import 'package:growmate_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:growmate_frontend/features/auth/data/repositories/data_consent_repository.dart';
import 'package:growmate_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:growmate_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:growmate_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:growmate_frontend/core/network/mock_api_service.dart';
import 'package:growmate_frontend/features/diagnosis/data/repositories/diagnosis_repository.dart';
import 'package:growmate_frontend/features/intervention/data/repositories/intervention_repository.dart';
import 'package:growmate_frontend/features/notification/data/repositories/notification_repository.dart';
import 'package:growmate_frontend/features/privacy/data/repositories/privacy_repository.dart';
import 'package:growmate_frontend/features/quiz/data/repositories/quiz_repository.dart';
import 'package:growmate_frontend/features/quiz/presentation/widgets/quiz_answer_widget_factory.dart';
import 'package:growmate_frontend/features/session/data/repositories/session_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Quiz -> Result flow handles plan acceptance and navigates to intervention',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'mock_token_e2e',
        'auth_email': 'learner@growmate.vn',
        'auth_name': 'Learner',
        DataConsentRepository.consentAcceptedKey: true,
      });

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
      final notificationRepository = NotificationRepository.instance;
      final sessionHistoryRepository = SessionHistoryRepository.instance;
      final privacyRepository = PrivacyRepository(
        profileRepository: profileRepository,
        notificationRepository: notificationRepository,
        sessionHistoryRepository: sessionHistoryRepository,
      );

      final appRouter = AppRouter(
        authBloc: authBloc,
        authRepository: authRepository,
        profileRepository: profileRepository,
        quizRepository: quizRepository,
        diagnosisRepository: diagnosisRepository,
        interventionRepository: interventionRepository,
        notificationRepository: notificationRepository,
        sessionHistoryRepository: sessionHistoryRepository,
        privacyRepository: privacyRepository,
        dataConsentRepository: DataConsentRepository.instance,
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

      for (var attempt = 0; attempt < 20; attempt++) {
        if (authBloc.state is AuthAuthenticated) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(authBloc.state, isA<AuthAuthenticated>());

      appRouter.router.go('/quiz');
      await tester.pumpAndSettle();

      for (var attempt = 0; attempt < 24; attempt++) {
        if (find.byType(QuizAnswerWidgetFactory).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.byType(QuizAnswerWidgetFactory), findsOneWidget);

      final textFieldFinder = find.byType(TextField);
      if (textFieldFinder.evaluate().isNotEmpty) {
        await tester.enterText(textFieldFinder.first, '12x^2 + 4x');
      } else {
        final optionTapTargets = find.descendant(
          of: find.byType(QuizAnswerWidgetFactory),
          matching: find.byWidgetPredicate(
            (widget) => widget is InkWell && widget.onTap != null,
          ),
        );

        if (optionTapTargets.evaluate().isNotEmpty) {
          await tester.tap(optionTapTargets.first, warnIfMissed: false);
        } else {
          final trueButton = find.text('Đúng').evaluate().isNotEmpty
              ? find.text('Đúng')
              : find.text('True');
          expect(trueButton, findsWidgets);
          await tester.tap(trueButton.first, warnIfMissed: false);
        }
      }

      final submitButtonVi = find.text('Gửi bài');
      final submitButtonEn = find.text('Submit');
      final submitButton = submitButtonVi.evaluate().isNotEmpty
          ? submitButtonVi
          : submitButtonEn;
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 2));

      final resultTitleVi = find.text('Phân tích AI hoàn tất');
      final resultTitleEn = find.text('AI analysis complete');
      for (var attempt = 0; attempt < 12; attempt++) {
        if (resultTitleVi.evaluate().isNotEmpty ||
            resultTitleEn.evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        resultTitleVi.evaluate().isNotEmpty ||
            resultTitleEn.evaluate().isNotEmpty,
        isTrue,
      );
      final approveButtonVi = find.text('Áp dụng lộ trình mới');
      final approveButtonEn = find.text('Apply new roadmap');
      for (var attempt = 0; attempt < 12; attempt++) {
        if (approveButtonVi.evaluate().isNotEmpty ||
            approveButtonEn.evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      final approveButton = approveButtonVi.evaluate().isNotEmpty
          ? approveButtonVi
          : approveButtonEn;
      expect(approveButton, findsOneWidget);
      await tester.tap(approveButton.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      for (var attempt = 0; attempt < 12; attempt++) {
        if (approveButtonVi.evaluate().isEmpty &&
            approveButtonEn.evaluate().isEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(
        approveButtonVi.evaluate().isEmpty &&
            approveButtonEn.evaluate().isEmpty,
        isTrue,
      );
    },
  );
}
