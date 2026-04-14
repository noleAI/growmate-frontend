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
import 'data/repositories/profile_repository.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/repositories/data_consent_repository.dart';
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

// ===== Agentic Backend Integration =====
import 'core/network/agentic_api_service.dart';
import 'core/network/ws_service.dart';
import 'core/services/real_agentic_api_service.dart';
import 'features/agentic_session/data/repositories/agentic_session_repository.dart';
import 'features/agentic_session/presentation/cubit/agentic_session_cubit.dart';
import 'features/agentic_session/presentation/cubit/agentic_session_state.dart';

// ===== Feature Flags =====
// Chuyển useMockApi = false khi backend REST API sẵn sàng
const bool useMockApi = true;
const bool useSupabaseRpcDataPlane = true;

/// Bật để sử dụng agentic backend (FastAPI multi-agent).
/// Khi true, AgenticSessionCubit sẽ được cung cấp qua BlocProvider.
const bool useAgenticBackend = false;
const String _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKeyFromDefine = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Không tìm thấy .env, sẽ fallback qua --dart-define nếu có.');
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

  // ===== Agentic Backend =====
  AgenticApiService? _agenticApiService;
  AgenticWsService? _agenticWsService;
  AgenticSessionRepository? _agenticSessionRepository;
  AgenticSessionCubit? _agenticSessionCubit;
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
        // Supabase tự handle token refresh, nhưng nếu dùng custom backend:
        // Lưu tokens mới vào secure storage
        debugPrint('🔄 Tokens refreshed');
      },
    );
  }

  /// Khởi tạo repositories với session ID động
  Future<void> _initializeRepositories() async {
    // Lấy hoặc tạo learning session
    _activeSessionId = await _sessionManager.getActiveSessionId();

    _quizRepository = QuizRepository(
      apiService: _apiService,
      sessionId: _activeSessionId!,
    );

    _diagnosisRepository = DiagnosisRepository(
      apiService: _apiService,
      sessionId: _activeSessionId!,
    );

    _interventionRepository = InterventionRepository(
      apiService: _apiService,
      sessionId: _activeSessionId!,
    );

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

    _sessionManager = SessionManager.instance;
    _apiService = _buildApiService();
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
          debugPrint('🔄 Agentic tokens refreshed');
        },
      );
      _agenticSessionRepository = AgenticSessionRepository(
        apiService: _agenticApiService!,
        wsService: _agenticWsService!,
      );
      _agenticSessionCubit = AgenticSessionCubit(
        repository: _agenticSessionRepository!,
      );
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
    _agenticSessionRepository?.dispose();
    _agenticWsService?.dispose();
    _inspectionCubit?.close();
    _authBloc.close();
    _themeModeCubit?.close();
    _colorPaletteCubit?.close();
    _appLanguageCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chờ initialization hoàn tất
    if (!_didInitializeDependencies) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<InspectionCubit>.value(value: _resolvedInspectionCubit),
        BlocProvider<ThemeModeCubit>.value(value: _resolvedThemeModeCubit),
        BlocProvider<ColorPaletteCubit>.value(
          value: _resolvedColorPaletteCubit,
        ),
        BlocProvider<AppLanguageCubit>.value(value: _resolvedAppLanguageCubit),
        if (_agenticSessionCubit != null)
          BlocProvider<AgenticSessionCubit>.value(value: _agenticSessionCubit!),
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
                      return Stack(
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
                    },
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
