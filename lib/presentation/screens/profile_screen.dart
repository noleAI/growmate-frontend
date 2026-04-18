import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/i18n/build_context_i18n.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/color_palette_cubit.dart';
import '../../app/theme/theme_mode_cubit.dart';
import '../../core/constants/layout.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/backend_profile_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/inspection/presentation/cubit/inspection_cubit.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import '../../features/offline/data/models/offline_state.dart';
import '../../features/offline/data/repositories/offline_mode_repository.dart';
import '../../features/privacy/data/repositories/privacy_repository.dart';
import '../../features/session/data/repositories/session_history_repository.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/nav_tab_routing.dart';
import '../../shared/widgets/zen_page_container.dart';
import '../cubit/profile_cubit.dart';

enum ProfileScreenSection { profile, settings }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileRepository,
    this.backendProfileRepository,
    required this.appVersion,
    this.section = ProfileScreenSection.profile,
  });

  final ProfileRepository profileRepository;
  final BackendProfileRepository? backendProfileRepository;
  final String appVersion;
  final ProfileScreenSection section;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();

  static const _subjectOptions = <String>[
    'Toán',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Ngữ văn',
    'Tiếng Anh',
  ];

  static const _gradeOptions = <String>[
    'Lớp 10',
    'Lớp 11',
    'Lớp 12',
    'Đại học năm 1',
  ];

  static const _subscriptionOptions = <String>['free', 'plus', 'pro'];
  static const _studyGoalOptions = <String>['exam_prep', 'explore'];
  static const _paceOptions = <String>['gentle', 'balanced', 'focused'];
  static const _hintStyleOptions = <String>[
    'step_by_step',
    'concept_first',
    'minimal',
  ];

  bool _hydrated = false;
  String? _gradeLevel;
  Set<String> _activeSubjects = <String>{};
  Map<String, dynamic> _learningPreferences = const <String, dynamic>{};
  bool _recoveryModeEnabled = false;
  bool _consentBehavioral = false;
  bool _consentAnalytics = false;
  String _subscriptionTier = 'free';
  int _subscriptionPickerVersion = 0;
  String? _pendingSuccessMessage;
  String _studyGoal = 'exam_prep';
  int _dailyMinutes = 20;
  String _userLevel = 'beginner';
  DateTime? _onboardedAt;
  bool _backendProfileLoading = false;
  String? _backendProfileError;
  bool _backendProfileHydrated = false;

  bool get _isSettingsSection =>
      widget.section == ProfileScreenSection.settings;

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _softInputBackground(BuildContext context) {
    return _isDark(context) ? const Color(0xFF1E2940) : const Color(0xFFF0F4FA);
  }

  Color _tagSelected(BuildContext context) {
    return _isDark(context) ? const Color(0xFF2A3F66) : const Color(0xFFEAF2FF);
  }

  Color _tagUnselected(BuildContext context) {
    return _isDark(context) ? const Color(0xFF1D273C) : const Color(0xFFEFF3F8);
  }

  Color _successSnackBackground(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _errorSnackBackground(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  TextStyle? _snackTextStyle(
    BuildContext context, {
    bool isError = false,
    Color? colorOverride,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colorOverride ?? (isError ? colors.onError : colors.onPrimary),
      fontWeight: FontWeight.w600,
    );
  }

  String _paletteLabel(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return context.t(vi: 'Xanh lá - vàng', en: 'Green - Yellow');
      case AppColorPalette.blueWhite:
        return context.t(vi: 'Xanh dương - trắng', en: 'Blue - White');
      case AppColorPalette.sunsetPeach:
        return context.t(vi: 'Hoàng hôn đào', en: 'Sunset Peach');
      case AppColorPalette.mintCream:
        return context.t(vi: 'Bạc hà - kem', en: 'Mint - Cream');
      case AppColorPalette.oceanSlate:
        return context.t(vi: 'Biển đêm', en: 'Ocean Slate');
    }
  }

  String _paletteDescription(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return context.t(
          vi: 'Gam màu tươi, tạo cảm giác năng lượng và tập trung.',
          en: 'A vibrant palette that feels energetic and focused.',
        );
      case AppColorPalette.blueWhite:
        return context.t(
          vi: 'Gam màu dịu mắt, tối giản và cân bằng.',
          en: 'A calm palette with a clean and balanced look.',
        );
      case AppColorPalette.sunsetPeach:
        return context.t(
          vi: 'Tông cam hồng ấm, tạo cảm giác tích cực và gần gũi.',
          en: 'A warm peach tone that feels positive and inviting.',
        );
      case AppColorPalette.mintCream:
        return context.t(
          vi: 'Sắc bạc hà sáng, nhẹ nhàng và thư giãn khi học lâu.',
          en: 'A light mint palette that stays soft during long study sessions.',
        );
      case AppColorPalette.oceanSlate:
        return context.t(
          vi: 'Xanh biển trầm hiện đại, tập trung và rõ tương phản.',
          en: 'A deep modern ocean tone with strong focus and contrast.',
        );
    }
  }

  String _paletteChangedMessage(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return context.t(
          vi: 'Đã chuyển sang bảng màu xanh lá - vàng.',
          en: 'Switched to the Green - Yellow palette.',
        );
      case AppColorPalette.blueWhite:
        return context.t(
          vi: 'Đã chuyển sang bảng màu xanh dương - trắng.',
          en: 'Switched to the Blue - White palette.',
        );
      case AppColorPalette.sunsetPeach:
        return context.t(
          vi: 'Đã chuyển sang bảng màu hoàng hôn đào.',
          en: 'Switched to the Sunset Peach palette.',
        );
      case AppColorPalette.mintCream:
        return context.t(
          vi: 'Đã chuyển sang bảng màu bạc hà - kem.',
          en: 'Switched to the Mint - Cream palette.',
        );
      case AppColorPalette.oceanSlate:
        return context.t(
          vi: 'Đã chuyển sang bảng màu biển đêm.',
          en: 'Switched to the Ocean Slate palette.',
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBackendProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendProfile() async {
    final repository = widget.backendProfileRepository;
    if (repository == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _backendProfileLoading = true;
        _backendProfileError = null;
      });
    }

    try {
      final backendProfile = await repository.fetchProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _studyGoal = _sanitizeStudyGoal(backendProfile.studyGoal);
        _dailyMinutes = backendProfile.dailyMinutes.clamp(5, 180);
        _userLevel = backendProfile.userLevel;
        _onboardedAt = backendProfile.onboardedAt;
        _backendProfileHydrated = true;
        _backendProfileLoading = false;
        _backendProfileError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _backendProfileLoading = false;
        _backendProfileError = context.t(
          vi: 'Chưa tải được hồ sơ học tập từ backend.',
          en: 'Failed to load backend learning profile.',
        );
      });
    }
  }

  Future<void> _saveBackendProfile() async {
    final repository = widget.backendProfileRepository;
    if (repository == null) {
      return;
    }

    final updated = await repository.updateProfile(
      studyGoal: _sanitizeStudyGoal(_studyGoal),
      dailyMinutes: _dailyMinutes.clamp(5, 180),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_goal', _sanitizeStudyGoal(updated.studyGoal));
    await prefs.setInt('daily_minutes', updated.dailyMinutes.clamp(5, 180));

    if (!mounted) {
      return;
    }

    setState(() {
      _studyGoal = _sanitizeStudyGoal(updated.studyGoal);
      _dailyMinutes = updated.dailyMinutes.clamp(5, 180);
      _userLevel = updated.userLevel;
      _onboardedAt = updated.onboardedAt;
      _backendProfileHydrated = true;
      _backendProfileError = null;
    });
  }

  String _sanitizeStudyGoal(String? goal) {
    final normalized = (goal ?? '').trim().toLowerCase();
    if (_studyGoalOptions.contains(normalized)) {
      return normalized;
    }
    return 'exam_prep';
  }

  void _hydrateFromProfile(UserProfile profile) {
    if (_hydrated &&
        _fullNameController.text.trim() == profile.fullName.trim()) {
      return;
    }

    _fullNameController.text = profile.fullName;
    _gradeLevel = profile.gradeLevel;
    _activeSubjects = profile.activeSubjects.toSet();
    _learningPreferences = Map<String, dynamic>.from(
      profile.learningPreferences,
    );
    _recoveryModeEnabled = profile.recoveryModeEnabled;
    _consentBehavioral = profile.consentBehavioral;
    _consentAnalytics = profile.consentAnalytics;
    _subscriptionTier = profile.subscriptionTier;
    _hydrated = true;

    if (mounted) {
      setState(() {});
    }
  }

  UserProfile _composeProfile(UserProfile source) {
    return source.copyWith(
      fullName: _fullNameController.text.trim(),
      gradeLevel: _gradeLevel,
      activeSubjects: _activeSubjects.toList(growable: false),
      // Agentic feature: used by policy selection and adaptive intervention planner.
      learningPreferences: Map<String, dynamic>.from(_learningPreferences),
      recoveryModeEnabled: _recoveryModeEnabled,
      consentBehavioral: _consentBehavioral,
      consentAnalytics: _consentAnalytics,
      subscriptionTier: _subscriptionTier,
      updatedAt: DateTime.now().toUtc(),
      lastActive: DateTime.now().toUtc(),
    );
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      _learningPreferences = Map<String, dynamic>.from(_learningPreferences)
        ..[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return BlocProvider<ProfileCubit>(
      create: (_) =>
          ProfileCubit(repository: widget.profileRepository)..loadProfile(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            current is ProfileLoaded || current is ProfileError,
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _hydrateFromProfile(state.profile);
            if (_pendingSuccessMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      _pendingSuccessMessage!,
                      style: _snackTextStyle(context),
                    ),
                    backgroundColor: _successSnackBackground(context),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              _pendingSuccessMessage = null;
            }
          }

          if (state is ProfileError) {
            if (_isSettingsSection && state.previous != null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: _snackTextStyle(context, isError: true),
                  ),
                  backgroundColor: _errorSnackBackground(context),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            _pendingSuccessMessage = null;
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final cubit = context.read<ProfileCubit>();

          final profile = switch (state) {
            ProfileLoaded(:final profile) => profile,
            ProfileLoading(:final previous) => previous,
            ProfileError(:final previous) => previous,
            _ => null,
          };

          final isProcessing = state is ProfileLoading;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: ZenPageContainer(
              includeBottomSafeArea: false,
              child: ListView(
                children: [
                  _buildSectionHeader(
                    title: _isSettingsSection
                        ? context.t(vi: 'Cài đặt', en: 'Settings')
                        : context.t(vi: 'Hồ sơ', en: 'Profile'),
                    subtitle: _isSettingsSection
                        ? context.t(
                            vi: 'Quyền riêng tư, thông báo và cấu hình.',
                            en: 'Privacy, notifications, and preferences.',
                          )
                        : context.t(
                            vi: 'Cá nhân hóa để AI hỗ trợ tốt hơn.',
                            en: 'Personalize for better AI support.',
                          ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  if (profile == null && state is ProfileLoading)
                    _CalmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.t(
                              vi: 'Đang tải hồ sơ của bạn...',
                              en: 'Loading your profile...',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (profile == null && state is! ProfileLoading)
                    _CalmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.t(
                              vi: 'Mình chưa tải được hồ sơ lúc này.',
                              en: 'Unable to load your profile right now.',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: GrowMateLayout.contentGap),
                          _PrimaryGradientButton(
                            label: context.t(vi: 'Tải lại', en: 'Retry'),
                            onPressed: isProcessing ? null : cubit.loadProfile,
                          ),
                        ],
                      ),
                    )
                  else if (profile != null)
                    Form(
                      key: _formKey,
                      child: Column(
                        children: _isSettingsSection
                            ? _buildSettingsSectionContent(
                                context: context,
                                authBloc: authBloc,
                                profile: profile,
                                isProcessing: isProcessing,
                              )
                            : _buildProfileSectionContent(
                                context: context,
                                cubit: cubit,
                                profile: profile,
                                isProcessing: isProcessing,
                              ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            bottomNavigationBar: GrowMateBottomNavBar(
              currentTab: _isSettingsSection
                  ? GrowMateTab.settings
                  : GrowMateTab.profile,
              onTabSelected: (tab) => handleTabNavigation(context, tab),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineLarge),
        const SizedBox(height: GrowMateLayout.space8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildProfileSectionContent({
    required BuildContext context,
    required ProfileCubit cubit,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    return <Widget>[
      _buildPersonalInfoCard(
        context: context,
        profile: profile,
        isProcessing: isProcessing,
      ),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _buildSubjectTagsCard(context: context, isProcessing: isProcessing),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _buildAiRhythmCard(isProcessing: isProcessing),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _buildLearningProfileCard(context: context, isProcessing: isProcessing),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _buildStudyPlanCard(
        context: context,
        profile: profile,
        isProcessing: isProcessing,
      ),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _PrimaryGradientButton(
        label: isProcessing
            ? context.t(vi: 'Đang lưu...', en: 'Saving...')
            : context.t(vi: 'Lưu thay đổi', en: 'Save changes'),
        onPressed: isProcessing
            ? null
            : () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                final successMessage = context.t(
                  vi: 'Hồ sơ đã được cập nhật nhẹ nhàng rồi nè.',
                  en: 'Your profile has been updated successfully.',
                );
                final partialMessage = context.t(
                  vi: 'Đã lưu hồ sơ cục bộ, nhưng chưa đồng bộ mục tiêu học lên server.',
                  en: 'Local profile saved, but learning goal was not synced to server.',
                );
                var backendSynced = true;
                if (widget.backendProfileRepository != null) {
                  try {
                    await _saveBackendProfile();
                  } catch (_) {
                    backendSynced = false;
                  }
                }

                _pendingSuccessMessage = backendSynced
                    ? successMessage
                    : partialMessage;
                await cubit.updateProfile(_composeProfile(profile));
              },
      ),
      const SizedBox(height: GrowMateLayout.space12),
    ];
  }

  List<Widget> _buildSettingsSectionContent({
    required BuildContext context,
    required AuthBloc authBloc,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    return <Widget>[
      _buildPrivacyPlanCard(context: context, isProcessing: isProcessing),
      const SizedBox(height: GrowMateLayout.sectionGap),
      _buildSystemCard(
        context: context,
        authBloc: authBloc,
        profile: profile,
        isProcessing: isProcessing,
      ),
      const SizedBox(height: GrowMateLayout.space12),
    ];
  }

  Widget _buildPersonalInfoCard({
    required BuildContext context,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Thông tin cá nhân', en: 'Personal info'),
            subtitle: context.t(
              vi: 'Cập nhật hồ sơ cho AI chính xác hơn.',
              en: 'Update profile for better AI support.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _FieldCaption(context.t(vi: 'Tên hiển thị', en: 'Display name')),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            controller: _fullNameController,
            enabled: !isProcessing,
            decoration: _softFieldDecoration(
              hint: context.t(vi: 'Nhập tên của bạn', en: 'Enter your name'),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return context.t(
                  vi: 'Bạn thêm tên để mình xưng hô dễ hơn nhé.',
                  en: 'Please add your name so the app can address you better.',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _FieldCaption(context.t(vi: 'Email', en: 'Email')),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            decoration: _softFieldDecoration(),
          ),
          const SizedBox(height: 12),
          _FieldCaption(context.t(vi: 'Khối lớp', en: 'Grade level')),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue: _gradeOptions.contains(_gradeLevel)
                ? _gradeLevel
                : null,
            decoration: _softFieldDecoration(),
            style: _dropdownValueStyle(context),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _gradeOptions
                .map(
                  (grade) => DropdownMenuItem<String>(
                    value: grade,
                    child: _dropdownOptionText(
                      context,
                      _gradeLabel(context, grade),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isProcessing
                ? null
                : (value) {
                    setState(() {
                      _gradeLevel = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTagsCard({
    required BuildContext context,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(
              vi: 'Môn học đang tập trung',
              en: 'Focus subjects',
            ),
            subtitle: context.t(
              vi: 'Chọn môn AI ưu tiên.',
              en: 'Choose AI priority subjects.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjectOptions
                .map((subject) {
                  final selected = _activeSubjects.contains(subject);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    side: BorderSide.none,
                    backgroundColor: _tagUnselected(context),
                    selectedColor: _tagSelected(context),
                    label: Text(
                      _subjectLabel(context, subject),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    onSelected: isProcessing
                        ? null
                        : (value) {
                            setState(() {
                              if (value) {
                                _activeSubjects.add(subject);
                              } else {
                                _activeSubjects.remove(subject);
                              }
                            });
                          },
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRhythmCard({required bool isProcessing}) {
    final theme = Theme.of(context);

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Nhịp học AI', en: 'AI Rhythm'),
            subtitle: context.t(
              vi: 'Điều chỉnh nhịp và kiểu gợi ý AI.',
              en: 'Adjust pace and AI hint style.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: context.t(
              vi: 'Bật chế độ phục hồi',
              en: 'Enable Recovery Mode',
            ),
            subtitle: context.t(
              vi: 'Khi mệt, AI sẽ can thiệp dịu hơn.',
              en: 'When tired, AI uses gentler interventions.',
            ),
            value: _recoveryModeEnabled,
            onChanged: isProcessing
                ? null
                : (value) {
                    setState(() {
                      _recoveryModeEnabled = value;
                    });
                  },
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _FieldCaption(
            context.t(vi: 'Nhịp học ưu tiên', en: 'Preferred pace'),
          ),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue: _paceOptions.contains(_learningPreferences['pace'])
                ? _learningPreferences['pace'] as String
                : _paceOptions.first,
            decoration: _softFieldDecoration(),
            style: _dropdownValueStyle(context),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _paceOptions
                .map(
                  (pace) => DropdownMenuItem<String>(
                    value: pace,
                    child: _dropdownOptionText(
                      context,
                      _toPaceLabel(context, pace),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isProcessing
                ? null
                : (value) {
                    if (value != null) {
                      _updatePreference('pace', value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          _FieldCaption(context.t(vi: 'Kiểu gợi ý', en: 'Hint style')),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue:
                _hintStyleOptions.contains(_learningPreferences['hint_style'])
                ? _learningPreferences['hint_style'] as String
                : _hintStyleOptions.first,
            decoration: _softFieldDecoration(),
            style: _dropdownValueStyle(context),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _hintStyleOptions
                .map(
                  (hintStyle) => DropdownMenuItem<String>(
                    value: hintStyle,
                    child: _dropdownOptionText(
                      context,
                      _toHintStyleLabel(context, hintStyle),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isProcessing
                ? null
                : (value) {
                    if (value != null) {
                      _updatePreference('hint_style', value);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProfileCard({
    required BuildContext context,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasBackendRepo = widget.backendProfileRepository != null;
    final canEdit = hasBackendRepo && !isProcessing && !_backendProfileLoading;

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Hồ sơ học tập', en: 'Learning profile'),
            subtitle: context.t(
              vi: 'Đồng bộ với backend để gợi ý lộ trình chính xác trên mọi thiết bị.',
              en: 'Synced with backend to keep recommendations consistent across devices.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          if (!hasBackendRepo)
            Text(
              context.t(
                vi: 'Backend profile chưa khả dụng ở môi trường này. Dữ liệu local vẫn hoạt động bình thường.',
                en: 'Backend profile is not available in this environment. Local data still works.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else ...[
            if (_backendProfileLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_backendProfileError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _backendProfileError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _backendProfileLoading
                          ? null
                          : _loadBackendProfile,
                      child: Text(context.t(vi: 'Thử lại', en: 'Retry')),
                    ),
                  ],
                ),
              ),
            _FieldCaption(context.t(vi: 'Mục tiêu học tập', en: 'Study goal')),
            const SizedBox(height: GrowMateLayout.space8),
            DropdownButtonFormField<String>(
              initialValue: _studyGoalOptions.contains(_studyGoal)
                  ? _studyGoal
                  : _studyGoalOptions.first,
              decoration: _softFieldDecoration(),
              style: _dropdownValueStyle(context),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              items: _studyGoalOptions
                  .map(
                    (goal) => DropdownMenuItem<String>(
                      value: goal,
                      child: _dropdownOptionText(
                        context,
                        _studyGoalLabel(context, goal),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: canEdit
                  ? (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _studyGoal = value;
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            _FieldCaption(
              context.t(vi: 'Thời lượng học mỗi ngày', en: 'Daily minutes'),
            ),
            const SizedBox(height: GrowMateLayout.space8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              decoration: BoxDecoration(
                color: _softInputBackground(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_dailyMinutes.toInt()} ${context.t(vi: 'phút/ngày', en: 'min/day')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: _dailyMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$_dailyMinutes',
                    onChanged: canEdit
                        ? (value) {
                            final stepped = ((value / 5).round() * 5)
                                .clamp(5, 180)
                                .toInt();
                            setState(() {
                              _dailyMinutes = stepped;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FieldCaption(context.t(vi: 'Trình độ hiện tại', en: 'User level')),
            const SizedBox(height: GrowMateLayout.space8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: GrowMateLayout.contentGap,
                vertical: GrowMateLayout.space12,
              ),
              decoration: BoxDecoration(
                color: _softInputBackground(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _userLevelLabel(context, _userLevel),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),
            _FieldCaption(context.t(vi: 'Onboarded at', en: 'Onboarded at')),
            const SizedBox(height: GrowMateLayout.space8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: GrowMateLayout.contentGap,
                vertical: GrowMateLayout.space12,
              ),
              decoration: BoxDecoration(
                color: _softInputBackground(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _formatOnboardedAt(context, _onboardedAt),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (_backendProfileHydrated)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  context.t(
                    vi: 'Giá trị đang hiển thị là dữ liệu mới nhất từ backend.',
                    en: 'Values shown above are synced from backend.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyPlanCard({
    required BuildContext context,
    required bool isProcessing,
  }) {
    final cubit = context.read<ProfileCubit>();

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Quyền riêng tư', en: 'Privacy'),
            subtitle: context.t(
              vi: 'Quản lý quyền dữ liệu học tập.',
              en: 'Manage learning data permissions.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: context.t(
              vi: 'Cho phép tín hiệu hành vi',
              en: 'Allow behavioral signals',
            ),
            subtitle: context.t(
              vi: 'Tối ưu theo nhịp tương tác.',
              en: 'Optimize by interaction rhythm.',
            ),
            value: _consentBehavioral,
            onChanged: isProcessing
                ? null
                : (value) async {
                    setState(() {
                      _consentBehavioral = value;
                    });
                    _pendingSuccessMessage = value
                        ? context.t(
                            vi: 'Đã bật tín hiệu hành vi.',
                            en: 'Behavioral signals enabled.',
                          )
                        : context.t(
                            vi: 'Đã tắt tín hiệu hành vi.',
                            en: 'Behavioral signals disabled.',
                          );
                    await cubit.toggleConsent(consentBehavioral: value);
                  },
          ),
          const Divider(height: 22, thickness: 0.6, color: Color(0x1A64748B)),
          _ToggleLine(
            title: context.t(
              vi: 'Cho phép analytics tổng quan',
              en: 'Allow aggregate analytics',
            ),
            subtitle: context.t(
              vi: 'Không ảnh hưởng đến bài học cốt lõi.',
              en: 'This does not affect your core learning flow.',
            ),
            value: _consentAnalytics,
            onChanged: isProcessing
                ? null
                : (value) async {
                    setState(() {
                      _consentAnalytics = value;
                    });
                    _pendingSuccessMessage = value
                        ? context.t(
                            vi: 'Đã bật analytics.',
                            en: 'Analytics enabled.',
                          )
                        : context.t(
                            vi: 'Đã tắt analytics.',
                            en: 'Analytics disabled.',
                          );
                    await cubit.toggleConsent(consentAnalytics: value);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPlanCard({
    required BuildContext context,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);
    final cubit = context.read<ProfileCubit>();

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Gói học tập', en: 'Study plan'),
            subtitle: context.t(
              vi: 'Quản lý gói dịch vụ.',
              en: 'Manage your service plan.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _FieldCaption(context.t(vi: 'Lựa chọn gói', en: 'Plan option')),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            key: ValueKey('subscription_picker_$_subscriptionPickerVersion'),
            initialValue: 'free',
            decoration: _softFieldDecoration(),
            style: _dropdownValueStyle(context),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            items: _subscriptionOptions
                .map(
                  (tier) => DropdownMenuItem<String>(
                    value: tier,
                    child: _dropdownOptionText(
                      context,
                      tier == 'free'
                          ? _toTierLabel(tier)
                          : '${_toTierLabel(tier)} (${context.t(vi: 'Chưa khả dụng', en: 'Unavailable')})',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: isProcessing
                ? null
                : (value) async {
                    if (value == null) {
                      return;
                    }

                    if (value != 'free') {
                      setState(() {
                        _subscriptionTier = 'free';
                        _subscriptionPickerVersion += 1;
                      });

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              context.t(
                                vi: 'Gói ${_toTierLabel(value)} chưa khả dụng trong phiên bản hiện tại.',
                                en: '${_toTierLabel(value)} plan is not available in the current version.',
                              ),
                              style: _snackTextStyle(context),
                            ),
                            backgroundColor: _successSnackBackground(context),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      return;
                    }

                    setState(() {
                      _subscriptionTier = 'free';
                      _subscriptionPickerVersion += 1;
                    });

                    if (profile.subscriptionTier == 'free') {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              context.t(
                                vi: 'Bạn đang ở gói Free.',
                                en: 'You are currently on the Free plan.',
                              ),
                              style: _snackTextStyle(context),
                            ),
                            backgroundColor: _successSnackBackground(context),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      return;
                    }

                    _pendingSuccessMessage = context.t(
                      vi: 'Đã chuyển về gói Free.',
                      en: 'Switched back to Free plan.',
                    );
                    await cubit.changeSubscription('free');
                  },
          ),
          const SizedBox(height: GrowMateLayout.space8),
          Text(
            '${context.t(vi: 'Hiện tại', en: 'Current')}: ${_toTierLabel(_subscriptionTier)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard({
    required BuildContext context,
    required AuthBloc authBloc,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);
    final inspectionCubit = _tryGetInspectionCubit(context);
    final themeModeCubit = context.read<ThemeModeCubit>();
    final colorPaletteCubit = context.read<ColorPaletteCubit>();
    final offlineRepository = OfflineModeRepository.instance;
    const settingContentInset = 46.0;

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: context.t(vi: 'Hệ thống', en: 'System'),
            subtitle: context.t(
              vi: 'Ứng dụng, hỗ trợ và đăng nhập.',
              en: 'App info, support, and session.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.space8),
          _settingsClusterLabel(
            context,
            vi: 'Trải nghiệm hằng ngày',
            en: 'Daily experience',
          ),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: context.t(vi: 'Thông báo', en: 'Notifications'),
            subtitle: context.t(
              vi: 'Nhắc nhở và cập nhật.',
              en: 'Reminders and updates.',
            ),
            onTap: () {
              context.push(AppRoutes.notifications);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            title: context.t(vi: 'Lịch thông minh', en: 'Smart Schedule'),
            subtitle: context.t(
              vi: 'Lịch thi và hạn nộp để AI ưu tiên.',
              en: 'Exams and deadlines for AI priority.',
            ),
            onTap: () {
              context.push(AppRoutes.schedule);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.spa_rounded,
            title: context.t(vi: 'Nghỉ thở 90 giây', en: 'Mindful Break 90s'),
            subtitle: context.t(
              vi: 'Thư giãn trước khi học tiếp.',
              en: 'Relax before continuing.',
            ),
            onTap: () {
              context.push(AppRoutes.mindfulBreak);
            },
          ),
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(context, vi: 'Giao diện', en: 'Appearance'),
          const Divider(height: 1, color: Color(0x1464748B)),
          BlocBuilder<ThemeModeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDarkMode = themeMode == ThemeMode.dark;

              return _ToggleLine(
                icon: Icons.dark_mode_rounded,
                title: context.t(vi: 'Chế độ tối', en: 'Dark Mode'),
                subtitle: isDarkMode
                    ? context.t(
                        vi: 'Giao diện tối đang bật.',
                        en: 'Dark interface is on.',
                      )
                    : context.t(
                        vi: 'Bật để giảm chói khi học tối.',
                        en: 'Enable to reduce eye strain at night.',
                      ),
                value: isDarkMode,
                onChanged: isProcessing
                    ? null
                    : (value) async {
                        await themeModeCubit.setDarkMode(value);

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? context.t(
                                        vi: 'Đã bật Chế độ tối.',
                                        en: 'Dark Mode enabled.',
                                      )
                                    : context.t(
                                        vi: 'Đã chuyển về Chế độ sáng.',
                                        en: 'Switched to Light Mode.',
                                      ),
                                style: _snackTextStyle(context),
                              ),
                              backgroundColor: _successSnackBackground(context),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      },
              );
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          const Divider(height: 1, color: Color(0x1464748B)),
          BlocBuilder<ColorPaletteCubit, AppColorPalette>(
            builder: (context, palette) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingFieldHeader(
                      icon: Icons.palette_outlined,
                      title: context.t(
                        vi: 'Bảng màu giao diện',
                        en: 'Color palette',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: Text(
                        context.t(
                          vi: 'Đổi nhanh theo sở thích.',
                          en: 'Switch to your preference.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: DropdownButtonFormField<AppColorPalette>(
                        initialValue: palette,
                        decoration: _softFieldDecoration(),
                        style: _dropdownValueStyle(context),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        items: AppColorPalette.values
                            .map(
                              (option) => DropdownMenuItem<AppColorPalette>(
                                value: option,
                                child: _dropdownOptionText(
                                  context,
                                  _paletteLabel(context, option),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: isProcessing
                            ? null
                            : (value) async {
                                if (value == null) {
                                  return;
                                }

                                await colorPaletteCubit.setPalette(value);

                                // Wait one frame so ThemeData reflects the newly selected palette.
                                await WidgetsBinding.instance.endOfFrame;

                                if (!context.mounted) {
                                  return;
                                }

                                final isDarkMode =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                final nextTheme = isDarkMode
                                    ? AppTheme.darkThemeFor(value)
                                    : AppTheme.lightThemeFor(value);
                                final nextColorScheme = nextTheme.colorScheme;

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _paletteChangedMessage(context, value),
                                        style: _snackTextStyle(
                                          context,
                                          colorOverride:
                                              nextColorScheme.onPrimary,
                                        ),
                                      ),
                                      backgroundColor: nextColorScheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: Text(
                        _paletteDescription(context, palette),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(context, vi: 'Hỗ trợ', en: 'Support'),
          StreamBuilder<OfflineState>(
            stream: offlineRepository.watchState(),
            builder: (context, snapshot) {
              final offlineState =
                  snapshot.data ??
                  const OfflineState(
                    enabled: false,
                    queuedSignals: 0,
                    lastSyncedAt: null,
                  );

              final subtitle = offlineState.enabled
                  ? context.t(
                      vi: 'Lưu cục bộ. Hàng đợi: ${offlineState.queuedSignals}.',
                      en: 'Saving locally. Queue: ${offlineState.queuedSignals}.',
                    )
                  : offlineState.queuedSignals > 0
                  ? context.t(
                      vi: 'Sẵn sàng đồng bộ ${offlineState.queuedSignals} tín hiệu.',
                      en: 'Ready to sync ${offlineState.queuedSignals} signals.',
                    )
                  : context.t(
                      vi: 'Tự động lưu khi mất mạng.',
                      en: 'Auto-queue when offline.',
                    );

              return _ToggleLine(
                icon: Icons.cloud_off_rounded,
                title: context.t(vi: 'Chế độ ngoại tuyến', en: 'Offline Mode'),
                subtitle: subtitle,
                value: offlineState.enabled,
                onChanged: isProcessing
                    ? null
                    : (value) async {
                        await offlineRepository.setOfflineModeEnabled(value);

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? context.t(
                                        vi: 'Đã bật ngoại tuyến.',
                                        en: 'Offline Mode on.',
                                      )
                                    : context.t(
                                        vi: 'Đã tắt ngoại tuyến.',
                                        en: 'Offline Mode off.',
                                      ),
                                style: _snackTextStyle(context),
                              ),
                              backgroundColor: _successSnackBackground(context),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      },
              );
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.support_agent_rounded,
            title: context.t(vi: 'Hỗ trợ & phản hồi', en: 'Support & feedback'),
            subtitle: context.t(
              vi: 'Gửi góp ý cho GrowMate.',
              en: 'Share feedback for GrowMate.',
            ),
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      context.t(
                        vi: 'Kênh góp ý sẽ mở sớm.',
                        en: 'Feedback channel coming soon.',
                      ),
                      style: _snackTextStyle(context),
                    ),
                    backgroundColor: _successSnackBackground(context),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.verified_rounded,
            title: context.t(vi: 'Phiên bản ứng dụng', en: 'App version'),
            subtitle: widget.appVersion,
          ),
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(
            context,
            vi: 'Quyền riêng tư & dữ liệu',
            en: 'Privacy & data',
          ),
          _MenuTile(
            icon: Icons.download_rounded,
            title: context.t(
              vi: 'Tải dữ liệu cá nhân',
              en: 'Export personal data',
            ),
            subtitle: context.t(
              vi: 'Xuất JSON hồ sơ và timeline.',
              en: 'Export profile JSON and timeline.',
            ),
            onTap: () {
              final location = Uri(
                path: AppRoutes.dataExport,
                queryParameters: <String, String>{
                  'uid': profile.id,
                  'email': profile.email,
                },
              ).toString();
              context.push(location);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.policy_outlined,
            title: context.t(vi: 'Điều khoản sử dụng', en: 'Terms of service'),
            subtitle: context.t(
              vi: 'Quy định dịch vụ GrowMate.',
              en: 'GrowMate service terms.',
            ),
            onTap: () {
              context.push(AppRoutes.termsOfService);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            title: context.t(
              vi: 'Chính sách quyền riêng tư',
              en: 'Privacy policy',
            ),
            subtitle: context.t(
              vi: 'Cách GrowMate xử lý dữ liệu.',
              en: 'How GrowMate handles your data.',
            ),
            onTap: () {
              context.push(AppRoutes.privacyPolicy);
            },
          ),
          if (inspectionCubit != null) ...[
            const SizedBox(height: GrowMateLayout.space24),
            _settingsClusterLabel(
              context,
              vi: 'Công cụ phát triển',
              en: 'Developer tools',
            ),
            StreamBuilder<InspectionState>(
              stream: inspectionCubit.stream,
              initialData: inspectionCubit.state,
              builder: (context, snapshot) {
                final inspectionState = snapshot.data ?? inspectionCubit.state;

                return _ToggleLine(
                  icon: Icons.developer_mode_rounded,
                  title: context.t(
                    vi: 'Chế độ Dev (Auditor)',
                    en: 'Dev Mode (Auditor)',
                  ),
                  subtitle: context.t(
                    vi: 'Hiện nút AI Insight trên Trang chủ.',
                    en: 'Show AI Insight button on Today page.',
                  ),
                  value: inspectionState.devModeEnabled,
                  onChanged: isProcessing
                      ? null
                      : (value) async {
                          await inspectionCubit.setDevMode(value);

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? context.t(
                                          vi: 'Đã bật Dev Mode.',
                                          en: 'Dev Mode enabled.',
                                        )
                                      : context.t(
                                          vi: 'Đã tắt Dev Mode.',
                                          en: 'Dev Mode disabled.',
                                        ),
                                  style: _snackTextStyle(context),
                                ),
                                backgroundColor: _successSnackBackground(
                                  context,
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                );
              },
            ),
          ],
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(context, vi: 'Tài khoản', en: 'Account'),
          const SizedBox(height: GrowMateLayout.space8),
          _GhostButton(
            label: isProcessing
                ? context.t(vi: 'Đang xử lý...', en: 'Processing...')
                : context.t(vi: 'Xóa tài khoản', en: 'Delete account'),
            isDanger: true,
            onPressed: isProcessing
                ? null
                : () {
                    _showDeleteAccountDialog(
                      profile: profile,
                      authBloc: authBloc,
                    );
                  },
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _GhostButton(
            label: isProcessing
                ? context.t(vi: 'Đang xử lý...', en: 'Processing...')
                : context.t(vi: 'Đăng xuất', en: 'Log out'),
            isDanger: true,
            onPressed: isProcessing
                ? null
                : () {
                    authBloc.add(const LogoutRequested());
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog({
    required UserProfile profile,
    required AuthBloc authBloc,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.t(vi: 'Xóa tài khoản', en: 'Delete account')),
          content: Text(
            context.t(
              vi: 'Xóa dữ liệu và hồ sơ học tập?',
              en: 'Delete all data and learning profile?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(context.t(vi: 'Hủy', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(context.t(vi: 'Xóa ngay', en: 'Delete now')),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteAccountData(profile: profile, authBloc: authBloc);
  }

  Future<void> _deleteAccountData({
    required UserProfile profile,
    required AuthBloc authBloc,
  }) async {
    final privacyRepository = PrivacyRepository(
      profileRepository: widget.profileRepository,
      notificationRepository: NotificationRepository.instance,
      sessionHistoryRepository: SessionHistoryRepository.instance,
    );

    try {
      await privacyRepository.deleteAccountData(userId: profile.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Đã xóa dữ liệu. Bạn có thể đăng ký lại.',
                en: 'Data deleted. You can sign up again.',
              ),
              style: _snackTextStyle(context),
            ),
            backgroundColor: _successSnackBackground(context),
            behavior: SnackBarBehavior.floating,
          ),
        );

      authBloc.add(const LogoutRequested());
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Không xóa được. Thử lại nhé.',
                en: 'Unable to delete. Try again.',
              ),
              style: _snackTextStyle(context, isError: true),
            ),
            backgroundColor: _errorSnackBackground(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  InputDecoration _softFieldDecoration({String? hint}) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: _softInputBackground(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GrowMateLayout.contentGap,
        vertical: GrowMateLayout.space12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colors.primary.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      hintStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
    );
  }

  TextStyle? _dropdownValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  Widget _dropdownOptionText(BuildContext context, String text) {
    return Text(text, style: _dropdownValueStyle(context));
  }

  Widget _settingsClusterLabel(
    BuildContext context, {
    required String vi,
    required String en,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
      child: Text(
        context.t(vi: vi, en: en),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _settingFieldHeader({required IconData icon, required String title}) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 18),
        ),
        const SizedBox(width: GrowMateLayout.space12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  static String _toTierLabel(String tier) {
    switch (tier) {
      case 'plus':
        return 'Plus';
      case 'pro':
        return 'Pro';
      default:
        return 'Free';
    }
  }

  String _subjectLabel(BuildContext context, String subject) {
    switch (subject) {
      case 'Toán':
        return context.t(vi: 'Toán', en: 'Mathematics');
      case 'Vật lý':
        return context.t(vi: 'Vật lý', en: 'Physics');
      case 'Hóa học':
        return context.t(vi: 'Hóa học', en: 'Chemistry');
      case 'Sinh học':
        return context.t(vi: 'Sinh học', en: 'Biology');
      case 'Ngữ văn':
        return context.t(vi: 'Ngữ văn', en: 'Literature');
      case 'Tiếng Anh':
        return context.t(vi: 'Tiếng Anh', en: 'English');
      default:
        return subject;
    }
  }

  String _gradeLabel(BuildContext context, String grade) {
    switch (grade) {
      case 'Lớp 10':
        return context.t(vi: 'Lớp 10', en: 'Grade 10');
      case 'Lớp 11':
        return context.t(vi: 'Lớp 11', en: 'Grade 11');
      case 'Lớp 12':
        return context.t(vi: 'Lớp 12', en: 'Grade 12');
      case 'Đại học năm 1':
        return context.t(vi: 'Đại học năm 1', en: 'University year 1');
      default:
        return grade;
    }
  }

  String _toPaceLabel(BuildContext context, String pace) {
    switch (pace) {
      case 'focused':
        return context.t(vi: 'Tập trung', en: 'Focused');
      case 'balanced':
        return context.t(vi: 'Cân bằng', en: 'Balanced');
      default:
        return context.t(vi: 'Nhẹ nhàng', en: 'Gentle');
    }
  }

  String _toHintStyleLabel(BuildContext context, String hintStyle) {
    switch (hintStyle) {
      case 'concept_first':
        return context.t(vi: 'Ưu tiên khái niệm', en: 'Concept first');
      case 'minimal':
        return context.t(vi: 'Gợi ý tối giản', en: 'Minimal hints');
      default:
        return context.t(vi: 'Từng bước', en: 'Step by step');
    }
  }

  String _studyGoalLabel(BuildContext context, String goal) {
    switch (goal) {
      case 'exam_prep':
        return context.t(vi: 'Ôn thi THPT', en: 'Exam prep');
      case 'explore':
        return context.t(vi: 'Khám phá kiến thức', en: 'Explore learning');
      default:
        return goal;
    }
  }

  String _userLevelLabel(BuildContext context, String level) {
    switch (level.trim().toLowerCase()) {
      case 'advanced':
        return context.t(vi: 'Nâng cao', en: 'Advanced');
      case 'intermediate':
        return context.t(vi: 'Trung cấp', en: 'Intermediate');
      default:
        return context.t(vi: 'Cơ bản', en: 'Beginner');
    }
  }

  String _formatOnboardedAt(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.t(vi: 'Chưa có dữ liệu', en: 'Not available yet');
    }

    final local = value.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  InspectionCubit? _tryGetInspectionCubit(BuildContext context) {
    try {
      return BlocProvider.of<InspectionCubit>(context);
    } catch (_) {
      return null;
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.primary, size: 18),
            ),
            const SizedBox(width: GrowMateLayout.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _CalmCard extends StatelessWidget {
  const _CalmCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: GrowMateLayout.space8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _FieldCaption extends StatelessWidget {
  const _FieldCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ToggleLine extends StatelessWidget {
  const _ToggleLine({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData? icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GrowMateLayout.space8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
    final switchControl = CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: const Color(0xFF7FAAFF),
      inactiveTrackColor: isDark
          ? const Color(0xFF3A4661)
          : const Color(0xFFDCE4F1),
      thumbColor: Colors.white,
    );

    if (icon == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: textColumn),
          const SizedBox(width: 8),
          switchControl,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.primary, size: 18),
          ),
          const SizedBox(width: GrowMateLayout.space12),
          Expanded(child: textColumn),
          const SizedBox(width: 8),
          switchControl,
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7DA9FF), Color(0xFF5A94FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4F8CFF),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = isDanger
        ? colors.errorContainer.withValues(alpha: 0.75)
        : colors.surfaceContainerHigh;
    final textColor = isDanger ? colors.error : colors.onSurface;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: GrowMateLayout.space12,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: isDanger
                  ? Border.all(color: colors.error.withValues(alpha: 0.25))
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
