import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/build_context_i18n.dart';
import 'app_routes.dart';
import '../../data/repositories/profile_repository.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../features/achievement/presentation/pages/achievements_page.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/data_consent_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/data_consent_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository.dart';
import '../../features/diagnosis/presentation/pages/result_screen.dart';
import '../../features/intervention/data/repositories/intervention_repository.dart';
import '../../features/intervention/presentation/pages/intervention_page.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/privacy/data/repositories/privacy_repository.dart';
import '../../features/privacy/presentation/pages/data_export_page.dart';
import '../../features/privacy/presentation/pages/privacy_policy_page.dart';
import '../../features/privacy/presentation/pages/terms_of_service_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/quiz/data/repositories/quiz_repository.dart';
import '../../features/quiz/presentation/pages/mode_selection_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/recovery/presentation/pages/recovery_screen.dart';
import '../../features/review/presentation/pages/spaced_review_page.dart';
import '../../features/roadmap/presentation/pages/thpt_roadmap_page.dart';
import '../../features/schedule/presentation/pages/smart_schedule_page.dart';
import '../../features/session/data/repositories/session_history_repository.dart';
import '../../features/session/presentation/pages/session_complete_page.dart';
import '../../features/today/presentation/pages/today_page.dart';
import '../../features/wellness/presentation/pages/mindful_break_page.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required QuizRepository quizRepository,
    required DiagnosisRepository diagnosisRepository,
    required InterventionRepository interventionRepository,
    required NotificationRepository notificationRepository,
    required SessionHistoryRepository sessionHistoryRepository,
    required PrivacyRepository privacyRepository,
    required DataConsentRepository dataConsentRepository,
  }) : _authBloc = authBloc,
       _authRepository = authRepository,
       _profileRepository = profileRepository,
       _quizRepository = quizRepository,
       _diagnosisRepository = diagnosisRepository,
       _interventionRepository = interventionRepository,
       _notificationRepository = notificationRepository,
       _sessionHistoryRepository = sessionHistoryRepository,
       _privacyRepository = privacyRepository,
       _dataConsentRepository = dataConsentRepository;

  static const String welcomePath = AppRoutes.welcome;
  static const String loginPath = AppRoutes.login;
  static const String registerPath = AppRoutes.register;
  static const String forgotPasswordPath = AppRoutes.forgotPassword;
  static const String consentPath = AppRoutes.dataConsent;

  static const String homePath = AppRoutes.home;

  static const String todayPath = AppRoutes.today;
  static const String progressPath = AppRoutes.progress;
  static const String profilePath = AppRoutes.profile;
  static const String settingsPath = AppRoutes.settings;
  static const String notificationsPath = AppRoutes.notifications;
  static const String dataExportPath = AppRoutes.dataExport;
  static const String termsOfServicePath = AppRoutes.termsOfService;
  static const String privacyPolicyPath = AppRoutes.privacyPolicy;
  static const String schedulePath = AppRoutes.schedule;
  static const String thptRoadmapPath = AppRoutes.thptRoadmap;
  static const String mindfulBreakPath = AppRoutes.mindfulBreak;

  static const String quizPath = AppRoutes.quiz;
  static const String spacedReviewPath = AppRoutes.spacedReview;
  static const String achievementsPath = AppRoutes.achievements;
  static const String recoveryPath = AppRoutes.recovery;
  static const String diagnosisPath = AppRoutes.diagnosis;
  static const String interventionPath = AppRoutes.intervention;
  static const String sessionCompletePath = AppRoutes.sessionComplete;

  static const Set<String> _authOnlyPaths = <String>{
    welcomePath,
    loginPath,
    registerPath,
    forgotPasswordPath,
  };
  static const Set<String> _consentBypassPaths = <String>{
    consentPath,
    termsOfServicePath,
    privacyPolicyPath,
  };

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final QuizRepository _quizRepository;
  final DiagnosisRepository _diagnosisRepository;
  final InterventionRepository _interventionRepository;
  final NotificationRepository _notificationRepository;
  final SessionHistoryRepository _sessionHistoryRepository;
  final PrivacyRepository _privacyRepository;
  final DataConsentRepository _dataConsentRepository;
  bool _isSessionResolved = false;
  bool _hasAuthenticatedSession = false;

  late final GoRouter router = GoRouter(
    initialLocation: homePath,
    refreshListenable: _GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) async {
      final authState = _authBloc.state;
      _syncAuthSnapshot(authState);

      final currentLocation = state.matchedLocation;
      final visitingAuthFlow = _authOnlyPaths.contains(currentLocation);
      final visitingConsentFlow = currentLocation == consentPath;
      final visitingConsentBypassPath = _consentBypassPaths.contains(
        currentLocation,
      );

      if (!_isSessionResolved) {
        if (visitingAuthFlow) {
          return null;
        }
        return welcomePath;
      }

      final isAuthenticated = _isAuthenticatedForRouting(authState);

      if (!isAuthenticated && !visitingAuthFlow) {
        return welcomePath;
      }

      if (!isAuthenticated && visitingConsentFlow) {
        return welcomePath;
      }

      if (isAuthenticated) {
        final hasConsent = await _dataConsentRepository.isAccepted();

        if (!hasConsent && !visitingConsentBypassPath) {
          return consentPath;
        }

        if (hasConsent && visitingConsentFlow) {
          return homePath;
        }

        if (hasConsent && visitingAuthFlow) {
          return homePath;
        }

        if (!hasConsent && visitingAuthFlow) {
          return consentPath;
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: welcomePath,
        builder: (context, state) {
          return const WelcomePage();
        },
      ),
      GoRoute(
        path: loginPath,
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: registerPath,
        builder: (context, state) {
          return const RegisterPage();
        },
      ),
      GoRoute(
        path: forgotPasswordPath,
        builder: (context, state) {
          return ForgotPasswordPage(authRepository: _authRepository);
        },
      ),
      GoRoute(
        path: consentPath,
        builder: (context, state) {
          return DataConsentPage(dataConsentRepository: _dataConsentRepository);
        },
      ),
      GoRoute(
        path: homePath,
        builder: (context, state) {
          return const TodayPage();
        },
      ),
      GoRoute(
        path: todayPath,
        builder: (context, state) {
          return const TodayPage();
        },
      ),
      GoRoute(
        path: progressPath,
        builder: (context, state) {
          return ProgressPage(
            sessionHistoryRepository: _sessionHistoryRepository,
          );
        },
      ),
      GoRoute(
        path: profilePath,
        builder: (context, state) {
          return ProfileScreen(
            profileRepository: _profileRepository,
            appVersion: '1.0.0+1',
            section: ProfileScreenSection.profile,
          );
        },
      ),
      GoRoute(
        path: settingsPath,
        builder: (context, state) {
          return ProfileScreen(
            profileRepository: _profileRepository,
            appVersion: '1.0.0+1',
            section: ProfileScreenSection.settings,
          );
        },
      ),
      GoRoute(
        path: notificationsPath,
        builder: (context, state) {
          return NotificationPage(
            notificationRepository: _notificationRepository,
          );
        },
      ),
      GoRoute(
        path: dataExportPath,
        builder: (context, state) {
          final userId =
              state.uri.queryParameters['uid']?.trim() ?? 'mock-user';
          final email = state.uri.queryParameters['email']?.trim() ?? '';
          return DataExportPage(
            userId: userId,
            email: email,
            privacyRepository: _privacyRepository,
          );
        },
      ),
      GoRoute(
        path: termsOfServicePath,
        builder: (context, state) {
          return const TermsOfServicePage();
        },
      ),
      GoRoute(
        path: privacyPolicyPath,
        builder: (context, state) {
          return const PrivacyPolicyPage();
        },
      ),
      GoRoute(
        path: schedulePath,
        builder: (context, state) {
          return const SmartSchedulePage();
        },
      ),
      GoRoute(
        path: thptRoadmapPath,
        builder: (context, state) {
          return const ThptRoadmapPage();
        },
      ),
      GoRoute(
        path: mindfulBreakPath,
        builder: (context, state) {
          return const MindfulBreakPage();
        },
      ),
      GoRoute(
        path: quizPath,
        builder: (context, state) {
          return QuizPage(quizRepository: _quizRepository);
        },
      ),
      GoRoute(
        path: AppRoutes.modeSelection,
        builder: (context, state) {
          return const ModeSelectionPage();
        },
      ),
      GoRoute(
        path: spacedReviewPath,
        builder: (context, state) {
          return const SpacedReviewPage();
        },
      ),
      GoRoute(
        path: achievementsPath,
        builder: (context, state) {
          return const AchievementsPage();
        },
      ),
      GoRoute(
        path: recoveryPath,
        builder: (context, state) {
          final reason = state.uri.queryParameters['reason'];
          return RecoveryScreen(reason: reason);
        },
      ),
      GoRoute(
        path: diagnosisPath,
        builder: (context, state) {
          final submissionId = state.uri.queryParameters['submissionId'] ?? '';
          if (submissionId.isEmpty) {
            return _RouteDataErrorPage(
              title: context.t(
                vi: 'Thiếu submissionId',
                en: 'Missing submissionId',
              ),
              message: context.t(
                vi: 'Route /diagnosis cần query parameter submissionId để hiển thị kết quả chẩn đoán.',
                en: 'Route /diagnosis requires query parameter submissionId to display diagnosis result.',
              ),
            );
          }

          return ResultScreen(
            submissionId: submissionId,
            diagnosisRepository: _diagnosisRepository,
          );
        },
      ),
      GoRoute(
        path: interventionPath,
        builder: (context, state) {
          final payload = _resolveInterventionPayload(
            state.extra,
            state.uri.queryParameters,
          );

          final submissionId = payload['submissionId']?.toString() ?? '';
          final diagnosisId = payload['diagnosisId']?.toString() ?? '';
          final finalMode = payload['finalMode']?.toString() ?? 'normal';
          final uncertaintyHigh = payload['uncertaintyHigh'] == true;
          final interventionPlan = _toPlan(payload['interventionPlan']);

          return InterventionPage(
            submissionId: submissionId,
            diagnosisId: diagnosisId,
            finalMode: finalMode,
            interventionPlan: interventionPlan,
            interventionRepository: _interventionRepository,
            uncertaintyHigh: uncertaintyHigh,
          );
        },
      ),
      GoRoute(
        path: sessionCompletePath,
        builder: (context, state) {
          return SessionCompletePage(
            queryParameters: state.uri.queryParameters,
            sessionHistoryRepository: _sessionHistoryRepository,
            notificationRepository: _notificationRepository,
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      return _RouteDataErrorPage(
        title: context.t(vi: 'Route không hợp lệ', en: 'Invalid route'),
        message:
            state.error?.toString() ??
            context.t(
              vi: 'Không tìm thấy trang yêu cầu.',
              en: 'Requested page was not found.',
            ),
      );
    },
  );

  static List<Map<String, dynamic>> _toPlan(Object? value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> _resolveInterventionPayload(
    Object? extra,
    Map<String, String> query,
  ) {
    if (extra is Map<String, dynamic>) {
      return extra;
    }

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final submissionId = query['submissionId']?.trim();
    final diagnosisId = query['diagnosisId']?.trim();
    final finalMode = query['mode']?.trim();
    final uncertaintyRaw = query['uncertainty']?.trim().toLowerCase();

    return <String, dynamic>{
      'submissionId': submissionId == null || submissionId.isEmpty
          ? 'sub_local_$nowMillis'
          : submissionId,
      'diagnosisId': diagnosisId == null || diagnosisId.isEmpty
          ? 'dx_local_$nowMillis'
          : diagnosisId,
      'finalMode': finalMode == null || finalMode.isEmpty
          ? 'normal'
          : finalMode,
      'uncertaintyHigh':
          uncertaintyRaw == '1' ||
          uncertaintyRaw == 'true' ||
          uncertaintyRaw == 'yes',
      'interventionPlan': <Map<String, dynamic>>[],
    };
  }

  void _syncAuthSnapshot(AuthState state) {
    if (state is AuthInitial) {
      _isSessionResolved = false;
      return;
    }

    if (state is AuthAuthenticated) {
      _hasAuthenticatedSession = true;
      _isSessionResolved = true;
      return;
    }

    if (state is AuthUnauthenticated) {
      _hasAuthenticatedSession = false;
      _isSessionResolved = true;
    }
  }

  bool _isAuthenticatedForRouting(AuthState state) {
    if (state is AuthAuthenticated) {
      return true;
    }

    if (state is AuthLoading || state is AuthError) {
      return _hasAuthenticatedSession;
    }

    return false;
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _RouteDataErrorPage extends StatelessWidget {
  const _RouteDataErrorPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(vi: 'Điều hướng', en: 'Navigation')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
