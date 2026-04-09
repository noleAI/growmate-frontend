import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/network/api_service.dart';
import 'core/network/mock_api_service.dart';
import 'core/services/real_api_service.dart';
import 'core/services/supabase_hybrid_api_service.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/diagnosis/data/repositories/diagnosis_repository.dart';
import 'features/inspection/presentation/cubit/inspection_cubit.dart';
import 'features/intervention/data/repositories/intervention_repository.dart';
import 'features/quiz/data/repositories/quiz_repository.dart';

const bool useMockApi = true;
const bool useSupabaseRpcDataPlane = true;
const String _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Khong tim thay .env, se fallback qua --dart-define neu co.');
  }

  final supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? _supabaseUrlFromDefine)
      .trim();
  final supabaseAnonKey =
      (dotenv.env['SUPABASE_ANON_KEY'] ?? _supabaseAnonKeyFromDefine).trim();

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } else {
    debugPrint(
      'SUPABASE_URL hoặc SUPABASE_ANON_KEY chưa được cấu hình. '
      'AuthRepository sẽ chạy mock mode.',
    );
  }

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
  late final ProfileRepository _profileRepository;
  InspectionCubit? _inspectionCubit;
  late final AuthBloc _authBloc;

  late final QuizRepository _quizRepository;
  late final DiagnosisRepository _diagnosisRepository;
  late final InterventionRepository _interventionRepository;
  late final AppRouter _appRouter;

  InspectionCubit get _resolvedInspectionCubit =>
      _inspectionCubit ??= InspectionCubit();

  @override
  void initState() {
    super.initState();

    final mockApiService = MockApiService(
      scenario: MockDiagnosisScenario.autoCycle,
    );

    _apiService = useMockApi
        ? (useSupabaseRpcDataPlane
              ? SupabaseHybridApiService(fallbackApiService: mockApiService)
              : mockApiService)
        : RealApiService(baseUrl: 'https://api.example.com/v1');

    _authRepository = AuthRepository();
    _profileRepository = ProfileRepository();
    _inspectionCubit = InspectionCubit();
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
      profileRepository: _profileRepository,
      quizRepository: _quizRepository,
      diagnosisRepository: _diagnosisRepository,
      interventionRepository: _interventionRepository,
    );
  }

  @override
  void dispose() {
    _inspectionCubit?.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<InspectionCubit>.value(value: _resolvedInspectionCubit),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'GrowMate',
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
