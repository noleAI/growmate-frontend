import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/i18n/app_language_cubit.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/color_palette_cubit.dart';
import 'app/theme/theme_mode_cubit.dart';
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
import 'features/notification/data/repositories/notification_repository.dart';
import 'features/offline/data/repositories/offline_mode_repository.dart';
import 'features/privacy/data/repositories/privacy_repository.dart';
import 'features/quiz/data/repositories/quiz_repository.dart';
import 'features/session/data/repositories/session_history_repository.dart';

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
  late final NotificationRepository _notificationRepository;
  late final OfflineModeRepository _offlineModeRepository;
  late final SessionHistoryRepository _sessionHistoryRepository;
  late final PrivacyRepository _privacyRepository;
  InspectionCubit? _inspectionCubit;
  late final AuthBloc _authBloc;
  ThemeModeCubit? _themeModeCubit;
  ColorPaletteCubit? _colorPaletteCubit;
  AppLanguageCubit? _appLanguageCubit;

  late final QuizRepository _quizRepository;
  late final DiagnosisRepository _diagnosisRepository;
  late final InterventionRepository _interventionRepository;
  late AppRouter _appRouter;
  bool _didInitializeDependencies = false;

  AppRouter _buildAppRouter() {
    return AppRouter(
      authBloc: _authBloc,
      authRepository: _authRepository,
      profileRepository: _profileRepository,
      quizRepository: _quizRepository,
      diagnosisRepository: _diagnosisRepository,
      interventionRepository: _interventionRepository,
      notificationRepository: _notificationRepository,
      sessionHistoryRepository: _sessionHistoryRepository,
      privacyRepository: _privacyRepository,
    );
  }

  InspectionCubit get _resolvedInspectionCubit =>
      _inspectionCubit ??= InspectionCubit();

  ThemeModeCubit get _resolvedThemeModeCubit =>
      _themeModeCubit ??= ThemeModeCubit()..loadThemeMode();

  ColorPaletteCubit get _resolvedColorPaletteCubit =>
      _colorPaletteCubit ??= ColorPaletteCubit()..loadPalette();

  AppLanguageCubit get _resolvedAppLanguageCubit =>
      _appLanguageCubit ??= AppLanguageCubit()..loadLanguage();

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
    _notificationRepository = NotificationRepository.instance;
    _offlineModeRepository = OfflineModeRepository.instance;
    _sessionHistoryRepository = SessionHistoryRepository.instance;
    _privacyRepository = PrivacyRepository(
      profileRepository: _profileRepository,
      notificationRepository: _notificationRepository,
      sessionHistoryRepository: _sessionHistoryRepository,
    );
    _inspectionCubit = InspectionCubit();
    _authBloc = AuthBloc(authRepository: _authRepository)
      ..add(const AppStarted());

    unawaited(_notificationRepository.bootstrap());

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

    unawaited(
      _offlineModeRepository.flushQueuedSignals(
        submitter: (queuedSignals) {
          return _apiService.submitSignals(
            sessionId: 'session_demo_001',
            signals: queuedSignals,
          );
        },
      ),
    );

    _appRouter = _buildAppRouter();
    _didInitializeDependencies = true;
  }

  @override
  void reassemble() {
    super.reassemble();

    if (!_didInitializeDependencies) {
      return;
    }

    // Hot reload keeps State instances, so refresh GoRouter to pick up route changes.
    _appRouter = _buildAppRouter();
  }

  @override
  void dispose() {
    _inspectionCubit?.close();
    _authBloc.close();
    _themeModeCubit?.close();
    _colorPaletteCubit?.close();
    _appLanguageCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<InspectionCubit>.value(value: _resolvedInspectionCubit),
        BlocProvider<ThemeModeCubit>.value(value: _resolvedThemeModeCubit),
        BlocProvider<ColorPaletteCubit>.value(
          value: _resolvedColorPaletteCubit,
        ),
        BlocProvider<AppLanguageCubit>.value(value: _resolvedAppLanguageCubit),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<ColorPaletteCubit, AppColorPalette>(
            builder: (context, palette) {
              return BlocBuilder<AppLanguageCubit, AppLanguage>(
                builder: (context, language) {
                  return MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'GrowMate',
                    locale: language.locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: AppTheme.lightThemeFor(palette),
                    darkTheme: AppTheme.darkThemeFor(palette),
                    themeMode: themeMode,
                    routerConfig: _appRouter.router,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
