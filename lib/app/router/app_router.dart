import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository.dart';
import '../../features/diagnosis/presentation/pages/diagnosis_page.dart';
import '../../features/intervention/data/repositories/intervention_repository.dart';
import '../../features/intervention/presentation/pages/intervention_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/quiz/data/repositories/quiz_repository.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/session/presentation/pages/session_complete_page.dart';
import '../../features/today/presentation/pages/today_page.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required AuthRepository authRepository,
    required QuizRepository quizRepository,
    required DiagnosisRepository diagnosisRepository,
    required InterventionRepository interventionRepository,
  }) : _authBloc = authBloc,
       _authRepository = authRepository,
       _quizRepository = quizRepository,
       _diagnosisRepository = diagnosisRepository,
       _interventionRepository = interventionRepository;

  static const String welcomePath = AppRoutes.welcome;
  static const String loginPath = AppRoutes.login;
  static const String registerPath = AppRoutes.register;
  static const String forgotPasswordPath = AppRoutes.forgotPassword;

  static const String homePath = AppRoutes.home;

  static const String todayPath = AppRoutes.today;
  static const String progressPath = AppRoutes.progress;
  static const String profilePath = AppRoutes.profile;

  static const String quizPath = AppRoutes.quiz;
  static const String diagnosisPath = AppRoutes.diagnosis;
  static const String interventionPath = AppRoutes.intervention;
  static const String sessionCompletePath = AppRoutes.sessionComplete;

  static const Set<String> _authOnlyPaths = <String>{
    welcomePath,
    loginPath,
    registerPath,
    forgotPasswordPath,
  };

  final AuthBloc _authBloc;
  final AuthRepository _authRepository;
  final QuizRepository _quizRepository;
  final DiagnosisRepository _diagnosisRepository;
  final InterventionRepository _interventionRepository;
  bool _isSessionResolved = false;
  bool _hasAuthenticatedSession = false;

  late final GoRouter router = GoRouter(
    initialLocation: homePath,
    refreshListenable: _GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authState = _authBloc.state;
      _syncAuthSnapshot(authState);

      final currentLocation = state.matchedLocation;
      final visitingAuthFlow = _authOnlyPaths.contains(currentLocation);

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

      if (isAuthenticated && visitingAuthFlow) {
        return homePath;
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
          return const ProgressPage();
        },
      ),
      GoRoute(
        path: profilePath,
        builder: (context, state) {
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: quizPath,
        builder: (context, state) {
          return QuizPage(quizRepository: _quizRepository);
        },
      ),
      GoRoute(
        path: diagnosisPath,
        builder: (context, state) {
          final submissionId = state.uri.queryParameters['submissionId'] ?? '';
          if (submissionId.isEmpty) {
            return const _RouteDataErrorPage(
              title: 'Thiếu submissionId',
              message:
                  'Route /diagnosis cần query parameter submissionId để hiển thị kết quả chẩn đoán.',
            );
          }

          return DiagnosisPage(
            submissionId: submissionId,
            diagnosisRepository: _diagnosisRepository,
          );
        },
      ),
      GoRoute(
        path: interventionPath,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const _RouteDataErrorPage(
              title: 'Thiếu dữ liệu intervention',
              message:
                  'Route /intervention cần extra dạng Map<String, dynamic> chứa submissionId, diagnosisId, finalMode và interventionPlan.',
            );
          }

          final submissionId = extra['submissionId']?.toString() ?? '';
          final diagnosisId = extra['diagnosisId']?.toString() ?? '';
          final finalMode = extra['finalMode']?.toString() ?? 'normal';
          final uncertaintyHigh = extra['uncertaintyHigh'] == true;
          final interventionPlan = _toPlan(extra['interventionPlan']);

          if (submissionId.isEmpty || diagnosisId.isEmpty) {
            return const _RouteDataErrorPage(
              title: 'Thiếu khóa điều hướng',
              message:
                  'Intervention cần đủ submissionId và diagnosisId để tạo BLoC đúng ngữ cảnh.',
            );
          }

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
          return const SessionCompletePage();
        },
      ),
    ],
    errorBuilder: (context, state) {
      return _RouteDataErrorPage(
        title: 'Route không hợp lệ',
        message: state.error?.toString() ?? 'Không tìm thấy trang yêu cầu.',
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
      appBar: AppBar(title: const Text('Điều hướng')),
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