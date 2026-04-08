import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/network/api_service.dart';
import 'core/network/mock_api_service.dart';
import 'core/services/real_api_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/diagnosis/data/repositories/diagnosis_repository.dart';
import 'features/intervention/data/repositories/intervention_repository.dart';
import 'features/quiz/data/repositories/quiz_repository.dart';

const bool useMockApi = true;

void main() {
  runApp(const GrowMateApp());
}

class GrowMateApp extends StatefulWidget {
  const GrowMateApp({super.key});

  @override
  State<GrowMateApp> createState() => _GrowMateAppState();
}

class _GrowMateAppState extends State<GrowMateApp> {
  late final ApiService _apiService;
  late final AuthRepository _authRepository;
  late final AuthBloc _authBloc;

  late final QuizRepository _quizRepository;
  late final DiagnosisRepository _diagnosisRepository;
  late final InterventionRepository _interventionRepository;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _apiService = useMockApi
        ? MockApiService(scenario: MockDiagnosisScenario.autoCycle)
        : RealApiService(baseUrl: 'https://api.example.com/v1');

    _authRepository = AuthRepository();
    _authBloc = AuthBloc(authRepository: _authRepository)
      ..add(const AppStarted());

    _quizRepository = QuizRepository(
      apiService: _apiService,
      sessionId: 'session_demo_001',
    );

    _diagnosisRepository = DiagnosisRepository(
      apiService: _apiService,
      sessionId: 'session_demo_001',
    );

    _interventionRepository = InterventionRepository(
      apiService: _apiService,
      sessionId: 'session_demo_001',
    );

    _appRouter = AppRouter(
      authBloc: _authBloc,
      authRepository: _authRepository,
      quizRepository: _quizRepository,
      diagnosisRepository: _diagnosisRepository,
      interventionRepository: _interventionRepository,
    );
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'GrowMate',
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
