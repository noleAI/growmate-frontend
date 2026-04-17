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
import 'core/services/learning_session_manager.dart';
import 'core/storage/auth_token_storage.dart';
import 'core/widgets/network_status_indicator.dart';
import 'data/repositories/backend_profile_repository.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/repositories/data_consent_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/diagnosis/data/repositories/diagnosis_repository.dart';
import 'features/diagnosis/data/repositories/real_diagnosis_repository.dart';
import 'features/inspection/presentation/cubit/inspection_cubit.dart';
import 'features/intervention/data/repositories/intervention_repository.dart';
import 'features/notification/data/repositories/notification_repository.dart';
import 'features/offline/data/repositories/offline_mode_repository.dart';
import 'features/privacy/data/repositories/privacy_repository.dart';
import 'features/quiz/data/repositories/quiz_repository.dart';
import 'features/quiz/presentation/cubit/study_mode_cubit.dart';
import 'features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import 'features/leaderboard/data/repositories/leaderboard_repository.dart';
import 'features/leaderboard/data/repositories/mock_leaderboard_repository.dart';
import 'features/leaderboard/data/repositories/real_leaderboard_repository.dart';
import 'features/onboarding/data/repositories/mock_onboarding_repository.dart';
import 'features/onboarding/data/repositories/onboarding_repository.dart';
import 'features/onboarding/data/repositories/real_onboarding_repository.dart';
import 'features/progress/data/repositories/formula_repository.dart';
import 'features/progress/data/repositories/mock_formula_repository.dart';
import 'features/progress/data/repositories/real_formula_repository.dart';
import 'features/progress/data/real_progress_repository.dart';
import 'features/quiz/data/repositories/lives_repository.dart';
import 'features/quiz/data/repositories/mock_lives_repository.dart';
import 'features/quiz/data/repositories/real_lives_repository.dart';
import 'features/quiz/data/repositories/quiz_api_repository.dart';
import 'features/session_recovery/data/repositories/session_recovery_repository.dart';
import 'features/session/data/repositories/session_history_repository.dart';
import 'core/network/rest_api_client.dart';

// ===== Agentic Backend Integration =====
import 'core/network/agentic_api_service.dart';
import 'core/network/academic_api_service.dart';
import 'core/network/ws_service.dart';
import 'core/services/real_agentic_api_service.dart';
import 'core/services/real_academic_api_service.dart';
import 'features/agentic_session/data/repositories/agentic_session_repository.dart';
import 'features/agentic_session/presentation/cubit/agentic_session_cubit.dart';
import 'features/agentic_session/presentation/cubit/agentic_session_state.dart';
import 'features/ai_companion/presentation/ai_companion_cubit.dart';
import 'features/ai_companion/presentation/session_companion_bridge.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/data/repositories/mock_chat_repository.dart';
import 'features/chat/data/repositories/real_chat_repository.dart';

import 'features/splash/presentation/pages/splash_page.dart';

// ===== Feature Flags =====
// Compile-time defaults via --dart-define; overridden by .env at runtime.
const String _useMockApiFromDefine = String.fromEnvironment(
  'USE_MOCK_API',
  defaultValue: 'true',
);
const String _useSupabaseRpcDataPlaneFromDefine = String.fromEnvironment(
  'USE_SUPABASE_RPC_DATA_PLANE',
  defaultValue: 'true',
);
const String _useAgenticBackendFromDefine = String.fromEnvironment(
  'USE_AGENTIC_BACKEND',
  defaultValue: 'true',
);
const String _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

/// Resolved in [main] after dotenv.load() — .env takes priority over --dart-define.
late final bool useMockApi;
late final bool useSupabaseRpcDataPlane;
late final bool useAgenticBackend;

bool _boolFromEnvFlag(String rawValue) {
  return rawValue.toLowerCase() == 'true';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Không tìm thấy .env, sẽ fallback qua --dart-define nếu có.');
  }

  // Resolve feature flags: .env overrides --dart-define.
  useMockApi = _boolFromEnvFlag(
    dotenv.env['USE_MOCK_API'] ?? _useMockApiFromDefine,
  );
  useSupabaseRpcDataPlane = _boolFromEnvFlag(
    dotenv.env['USE_SUPABASE_RPC_DATA_PLANE'] ??
        _useSupabaseRpcDataPlaneFromDefine,
  );
  useAgenticBackend = _boolFromEnvFlag(
    dotenv.env['USE_AGENTIC_BACKEND'] ?? _useAgenticBackendFromDefine,
  );

  debugPrint(
    '🏳️ Feature flags: useMockApi=$useMockApi, '
    'useSupabaseRpcDataPlane=$useSupabaseRpcDataPlane, '
    'useAgenticBackend=$useAgenticBackend',
  );

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
  late final DataConsentRepository _dataConsentRepository;
  late final ProfileRepository _profileRepository;
  late final NotificationRepository _notificationRepository;
  late final OfflineModeRepository _offlineModeRepository;
  late final SessionHistoryRepository _sessionHistoryRepository;
  late final PrivacyRepository _privacyRepository;
  late final LearningSessionManager _sessionManager;
  InspectionCubit? _inspectionCubit;
  late final AuthBloc _authBloc;
  ThemeModeCubit? _themeModeCubit;
  ColorPaletteCubit? _colorPaletteCubit;
  AppLanguageCubit? _appLanguageCubit;
  StudyModeCubit? _studyModeCubit;
  LeaderboardCubit? _leaderboardCubit;

  // ===== Backend REST API Client & Repositories =====
  RestApiClient? _restApiClient;
  late final LeaderboardRepository _leaderboardRepository;
  late final LivesRepository _livesRepository;
  late final FormulaRepository _formulaRepository;
  late final OnboardingRepository _onboardingRepository;
  QuizApiRepository? _quizApiRepository;
  SessionRecoveryRepository? _sessionRecoveryRepository;
  BackendProfileRepository? _backendProfileRepository;
  ConfigRepository? _configRepository;
  RealProgressRepository? _realProgressRepository;
  late ChatRepository _chatRepository;

  // ===== Agentic Backend =====
  AgenticApiService? _agenticApiService;
  AcademicApiService? _academicApiService;
  AgenticWsService? _agenticWsService;
  AgenticSessionRepository? _agenticSessionRepository;
  AgenticSessionCubit? _agenticSessionCubit;
  AiCompanionCubit? _aiCompanionCubit;
  StreamSubscription<AgenticSessionState>? _agenticPaletteSub;
  AppColorPalette? _preRecoveryPalette;

  // Session ID sẽ được lấy động từ SessionManager
  String? _activeSessionId;

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
      dataConsentRepository: _dataConsentRepository,
      onboardingRepository: _onboardingRepository,
      quizApiRepository: _quizApiRepository,
      backendProfileRepository: _backendProfileRepository,
      realProgressRepository: _realProgressRepository,
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

  StudyModeCubit get _resolvedStudyModeCubit =>
      _studyModeCubit ??= StudyModeCubit()..load();

  LeaderboardCubit get _resolvedLeaderboardCubit =>
      _leaderboardCubit ??= LeaderboardCubit(repository: _leaderboardRepository)
        ..loadLeaderboard();

  /// Khởi tạo API service với token injection (cho production REST API)
  ApiService _buildApiService() {
    final mockApiService = MockApiService(
      scenario: MockDiagnosisScenario.autoCycle,
    );

    if (useMockApi) {
      return useSupabaseRpcDataPlane
          ? SupabaseHybridApiService(fallbackApiService: mockApiService)
          : mockApiService;
    }

    // Production REST API với token injection
    return RealApiService(
      getAccessToken: GlobalTokenStorage.instance.getAccessToken,
      getRefreshToken: GlobalTokenStorage.instance.getRefreshToken,
      onTokenRefresh: (newAccess, newRefresh) async {
        await GlobalTokenStorage.instance.saveRawTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        debugPrint('🔄 Tokens refreshed');
      },
    );
  }

  /// Khởi tạo REST client dùng chung cho tất cả real repositories.
  RestApiClient _buildRestApiClient() {
    return RestApiClient(
      getAccessToken: GlobalTokenStorage.instance.getAccessToken,
      getRefreshToken: GlobalTokenStorage.instance.getRefreshToken,
      onTokenRefresh: (newAccess, newRefresh) async {
        await GlobalTokenStorage.instance.saveRawTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        debugPrint('🔄 REST tokens refreshed');
      },
    );
  }

  /// Khởi tạo feature repositories dựa trên feature flag useMockApi.
  void _initializeFeatureRepositories() {
    if (useMockApi) {
      _leaderboardRepository = MockLeaderboardRepository();
      _livesRepository = MockLivesRepository();
      _formulaRepository = MockFormulaRepository();
      _onboardingRepository = MockOnboardingRepository();
      _chatRepository = MockChatRepository();
    } else {
      _restApiClient = _buildRestApiClient();
      _leaderboardRepository = RealLeaderboardRepository(
        client: _restApiClient!,
      );
      _livesRepository = RealLivesRepository(client: _restApiClient!);
      _formulaRepository = RealFormulaRepository(client: _restApiClient!);
      _onboardingRepository = RealOnboardingRepository(client: _restApiClient!);
      _quizApiRepository = QuizApiRepository(client: _restApiClient!);
      _sessionRecoveryRepository = SessionRecoveryRepository(
        client: _restApiClient!,
      );
      _backendProfileRepository = BackendProfileRepository(
        client: _restApiClient!,
      );
      _configRepository = ConfigRepository(client: _restApiClient!);
      // Chat defaults to mock; overridden after agentic init if available.
      _chatRepository = MockChatRepository();
    }
  }

  /// Khởi tạo repositories với session ID động
  Future<void> _initializeRepositories() async {
    // Lấy hoặc tạo learning session
    _activeSessionId = await _sessionManager.getActiveSessionId();

    _quizRepository = QuizRepository(
      apiService: _apiService,
      sessionId: _activeSessionId!,
    );

    _diagnosisRepository = useAgenticBackend && _agenticApiService != null
        ? RealDiagnosisRepository(
            apiService: _agenticApiService!,
            sessionId: _activeSessionId!,
          )
        : MockDiagnosisRepository(
            apiService: _apiService,
            sessionId: _activeSessionId!,
          );

    _interventionRepository = InterventionRepository(
      apiService: _apiService,
      sessionId: _activeSessionId!,
    );

    // Upgrade chat to real chatbot endpoint when agentic API is available.
    if (useAgenticBackend && _agenticApiService != null) {
      _chatRepository = RealChatRepository(
        getAccessToken: GlobalTokenStorage.instance.getAccessToken,
      );
    }

    // Flush queued signals từ offline mode
    unawaited(
      _offlineModeRepository.flushQueuedSignals(
        submitter: (queuedSignals) {
          return _apiService.submitSignals(
            sessionId: _activeSessionId!,
            signals: queuedSignals,
          );
        },
      ),
    );
  }

  Future<void> _bootstrapDependencies() async {
    try {
      await _initializeRepositories();
    } catch (error) {
      debugPrint('❌ Lỗi khởi tạo repositories: $error');
    }

    // Pre-fetch remote feature flags / configs at app init.
    if (_configRepository != null) {
      try {
        await _configRepository!.getConfig('feature_flags');
      } catch (e) {
        debugPrint('⚠️ Không tải được remote config: $e');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _appRouter = _buildAppRouter();
      _didInitializeDependencies = true;
    });
  }

  @override
  void initState() {
    super.initState();

    _apiService = _buildApiService();
    _initializeFeatureRepositories();
    _authRepository = AuthRepository();
    _dataConsentRepository = DataConsentRepository.instance;
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

    // ===== Agentic Backend Initialization =====
    if (useAgenticBackend) {
      _agenticWsService = AgenticWsService();
      _agenticApiService = RealAgenticApiService(
        getAccessToken: GlobalTokenStorage.instance.getAccessToken,
        getRefreshToken: GlobalTokenStorage.instance.getRefreshToken,
        onTokenRefresh: (newAccess, newRefresh) async {
          await GlobalTokenStorage.instance.saveRawTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          debugPrint('🔄 Agentic tokens refreshed');
        },
      );
      _academicApiService = RealAcademicApiService(
        getAccessToken: GlobalTokenStorage.instance.getAccessToken,
        getRefreshToken: GlobalTokenStorage.instance.getRefreshToken,
        onTokenRefresh: (newAccess, newRefresh) async {
          await GlobalTokenStorage.instance.saveRawTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          debugPrint('🔄 Academic tokens refreshed');
        },
      );
      _realProgressRepository = RealProgressRepository(
        apiService: _agenticApiService!,
      );
      _agenticSessionRepository = AgenticSessionRepository(
        apiService: _agenticApiService!,
        wsService: _agenticWsService!,
      );
      _agenticSessionCubit = AgenticSessionCubit(
        repository: _agenticSessionRepository!,
      );
      _aiCompanionCubit = AiCompanionCubit();
      // Auto-switch to mintCream (De-Stress palette) when recovery is triggered
      _agenticPaletteSub = _agenticSessionCubit!.stream.listen((state) {
        final paletteCubit = _colorPaletteCubit;
        if (paletteCubit == null) return;
        if (state.isRecovery && _preRecoveryPalette == null) {
          _preRecoveryPalette = paletteCubit.state;
          unawaited(paletteCubit.setPalette(AppColorPalette.mintCream));
        } else if (!state.isRecovery && _preRecoveryPalette != null) {
          unawaited(paletteCubit.setPalette(_preRecoveryPalette!));
          _preRecoveryPalette = null;
        }
      });
    }

    // SessionManager must be created AFTER _agenticApiService so the
    // REST session creator callback can reference the real API client.
    _sessionManager = useAgenticBackend && _agenticApiService != null
        ? LearningSessionManager(
            restSessionCreator:
                ({
                  required String subject,
                  required String topic,
                  String? mode,
                  String? classificationLevel,
                  Map<String, dynamic>? onboardingResults,
                }) async {
                  final response = await _agenticApiService!.createSession(
                    subject: subject,
                    topic: topic,
                    mode: mode,
                    classificationLevel: classificationLevel,
                    onboardingResults: onboardingResults,
                  );
                  return response.sessionId;
                },
            restSessionCompleter: (sessionId, status) async {
              await _agenticApiService!.updateSession(
                sessionId: sessionId,
                status: status,
              );
            },
          )
        : SessionManager.instance;

    // Khởi tạo repositories với session ID động
    unawaited(_bootstrapDependencies());
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
    _agenticPaletteSub?.cancel();
    _agenticSessionCubit?.close();
    _aiCompanionCubit?.close();
    _agenticSessionRepository?.dispose();
    _agenticWsService?.dispose();
    _inspectionCubit?.close();
    _authBloc.close();
    _themeModeCubit?.close();
    _colorPaletteCubit?.close();
    _appLanguageCubit?.close();
    _studyModeCubit?.close();
    _leaderboardCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chờ initialization hoàn tất
    if (!_didInitializeDependencies) {
      return MaterialApp(
        home: SplashPage(
          onComplete: () {
            // Splash finishes before deps — no-op; the setState in
            // _bootstrapDependencies will rebuild with the real app.
          },
        ),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LeaderboardRepository>.value(
          value: _leaderboardRepository,
        ),
        RepositoryProvider<LivesRepository>.value(value: _livesRepository),
        RepositoryProvider<FormulaRepository>.value(value: _formulaRepository),
        RepositoryProvider<OnboardingRepository>.value(
          value: _onboardingRepository,
        ),
        if (_quizApiRepository != null)
          RepositoryProvider<QuizApiRepository>.value(
            value: _quizApiRepository!,
          ),
        if (_sessionRecoveryRepository != null)
          RepositoryProvider<SessionRecoveryRepository>.value(
            value: _sessionRecoveryRepository!,
          ),
        if (_backendProfileRepository != null)
          RepositoryProvider<BackendProfileRepository>.value(
            value: _backendProfileRepository!,
          ),
        RepositoryProvider<ChatRepository>.value(value: _chatRepository),
        if (_configRepository != null)
          RepositoryProvider<ConfigRepository>.value(value: _configRepository!),
        if (_agenticApiService != null)
          RepositoryProvider<AgenticApiService>.value(
            value: _agenticApiService!,
          ),
        if (_academicApiService != null)
          RepositoryProvider<AcademicApiService>.value(
            value: _academicApiService!,
          ),
        if (_realProgressRepository != null)
          RepositoryProvider<RealProgressRepository>.value(
            value: _realProgressRepository!,
          ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<InspectionCubit>.value(value: _resolvedInspectionCubit),
          BlocProvider<ThemeModeCubit>.value(value: _resolvedThemeModeCubit),
          BlocProvider<ColorPaletteCubit>.value(
            value: _resolvedColorPaletteCubit,
          ),
          BlocProvider<AppLanguageCubit>.value(
            value: _resolvedAppLanguageCubit,
          ),
          BlocProvider<StudyModeCubit>.value(value: _resolvedStudyModeCubit),
          BlocProvider<LeaderboardCubit>.value(
            value: _resolvedLeaderboardCubit,
          ),
          if (_agenticSessionCubit != null)
            BlocProvider<AgenticSessionCubit>.value(
              value: _agenticSessionCubit!,
            ),
          if (_aiCompanionCubit != null)
            BlocProvider<AiCompanionCubit>.value(value: _aiCompanionCubit!),
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
                      builder: (context, child) {
                        // Bridge: forward AgenticSession events to AiCompanionCubit
                        // when agentic backend is active.
                        Widget content = Stack(
                          children: [
                            child ?? const SizedBox.shrink(),
                            const Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: NetworkStatusIndicator(),
                            ),
                          ],
                        );
                        if (_agenticSessionCubit != null &&
                            _aiCompanionCubit != null) {
                          content = SessionToCompanionBridge(child: content);
                        }
                        return content;
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
