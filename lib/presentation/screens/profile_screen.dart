import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/i18n/app_language_cubit.dart';
import '../../app/i18n/app_strings.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/color_palette_cubit.dart';
import '../../app/theme/theme_mode_cubit.dart';
import '../../core/constants/layout.dart';
import '../../data/models/user_profile.dart';
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
    required this.appVersion,
    this.section = ProfileScreenSection.profile,
  });

  final ProfileRepository profileRepository;
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
    return const Color(0xFF14532D);
  }

  Color _errorSnackBackground(BuildContext context) {
    return const Color(0xFF7F1D1D);
  }

  TextStyle? _snackTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
  }

  String _t(BuildContext context, {required String vi, required String en}) {
    return AppStrings.of(context).pick(vi: vi, en: en);
  }

  String _paletteLabel(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return _t(context, vi: 'Xanh lá - vàng', en: 'Green - Yellow');
      case AppColorPalette.blueWhite:
        return _t(context, vi: 'Xanh dương - trắng', en: 'Blue - White');
      case AppColorPalette.sunsetPeach:
        return _t(context, vi: 'Hoàng hôn đào', en: 'Sunset Peach');
      case AppColorPalette.mintCream:
        return _t(context, vi: 'Bạc hà - kem', en: 'Mint - Cream');
      case AppColorPalette.oceanSlate:
        return _t(context, vi: 'Biển đêm', en: 'Ocean Slate');
    }
  }

  String _paletteDescription(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return _t(
          context,
          vi: 'Gam màu tươi, tạo cảm giác năng lượng và tập trung.',
          en: 'A vibrant palette that feels energetic and focused.',
        );
      case AppColorPalette.blueWhite:
        return _t(
          context,
          vi: 'Gam màu dịu mắt, tối giản và cân bằng.',
          en: 'A calm palette with a clean and balanced look.',
        );
      case AppColorPalette.sunsetPeach:
        return _t(
          context,
          vi: 'Tông cam hồng ấm, tạo cảm giác tích cực và gần gũi.',
          en: 'A warm peach tone that feels positive and inviting.',
        );
      case AppColorPalette.mintCream:
        return _t(
          context,
          vi: 'Sắc bạc hà sáng, nhẹ nhàng và thư giãn khi học lâu.',
          en: 'A light mint palette that stays soft during long study sessions.',
        );
      case AppColorPalette.oceanSlate:
        return _t(
          context,
          vi: 'Xanh biển trầm hiện đại, tập trung và rõ tương phản.',
          en: 'A deep modern ocean tone with strong focus and contrast.',
        );
    }
  }

  String _paletteChangedMessage(BuildContext context, AppColorPalette palette) {
    switch (palette) {
      case AppColorPalette.greenYellow:
        return _t(
          context,
          vi: 'Đã chuyển sang bảng màu xanh lá - vàng.',
          en: 'Switched to the Green - Yellow palette.',
        );
      case AppColorPalette.blueWhite:
        return _t(
          context,
          vi: 'Đã chuyển sang bảng màu xanh dương - trắng.',
          en: 'Switched to the Blue - White palette.',
        );
      case AppColorPalette.sunsetPeach:
        return _t(
          context,
          vi: 'Đã chuyển sang bảng màu hoàng hôn đào.',
          en: 'Switched to the Sunset Peach palette.',
        );
      case AppColorPalette.mintCream:
        return _t(
          context,
          vi: 'Đã chuyển sang bảng màu bạc hà - kem.',
          en: 'Switched to the Mint - Cream palette.',
        );
      case AppColorPalette.oceanSlate:
        return _t(
          context,
          vi: 'Đã chuyển sang bảng màu biển đêm.',
          en: 'Switched to the Ocean Slate palette.',
        );
    }
  }

  String _languageLabel(BuildContext context, AppLanguage language) {
    final strings = AppStrings.of(context);
    switch (language) {
      case AppLanguage.vietnamese:
        return strings.languageVietnamese;
      case AppLanguage.english:
        return strings.languageEnglish;
    }
  }

  String _languageChangedMessage(BuildContext context, AppLanguage language) {
    switch (language) {
      case AppLanguage.vietnamese:
        return 'Đã chuyển sang Tiếng Việt.';
      case AppLanguage.english:
        return 'Switched to English.';
    }
  }

  void _showAvatarComingSoon() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              vi: 'Tính năng avatar sẽ phát triển trong bản ra mắt sau.',
              en: 'Avatar customization will arrive in a future release.',
            ),
            style: _snackTextStyle(context),
          ),
          backgroundColor: _successSnackBackground(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
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
    _subscriptionTier = 'free';
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
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message, style: _snackTextStyle(context)),
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
                  _buildHeader(profile),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  _buildSectionHeader(
                    title: _isSettingsSection
                        ? _t(context, vi: 'Cài đặt', en: 'Settings')
                        : _t(context, vi: 'Hồ sơ', en: 'Profile'),
                    subtitle: _isSettingsSection
                        ? _t(
                            context,
                            vi: 'Quản lý quyền riêng tư, thông báo và cấu hình ứng dụng.',
                            en: 'Manage privacy, notifications, and app preferences.',
                          )
                        : _t(
                            context,
                            vi: 'Thiết lập cá nhân hóa để AI ra quyết định chính xác hơn cho từng phiên học.',
                            en: 'Set personalization so AI can make better decisions for each study session.',
                          ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  if (profile == null && state is! ProfileLoading)
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
                            _t(
                              context,
                              vi: 'Mình chưa tải được hồ sơ lúc này.',
                              en: 'Unable to load your profile right now.',
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: GrowMateLayout.contentGap),
                          _PrimaryGradientButton(
                            label: _t(context, vi: 'Tải lại', en: 'Retry'),
                            onPressed: isProcessing ? null : cubit.loadProfile,
                          ),
                        ],
                      ),
                    )
                  else if (profile != null)
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isSettingsSection) ...[
                            _buildPersonalInfoCard(
                              context: context,
                              profile: profile,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: GrowMateLayout.sectionGapLg),
                            _buildSubjectTagsCard(
                              context: context,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: GrowMateLayout.sectionGapLg),
                            _buildAiRhythmCard(isProcessing: isProcessing),
                            const SizedBox(height: GrowMateLayout.sectionGapLg),
                            _buildStudyPlanCard(
                              context: context,
                              profile: profile,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: GrowMateLayout.sectionGapLg),
                            _PrimaryGradientButton(
                              label: isProcessing
                                  ? _t(
                                      context,
                                      vi: 'Đang lưu...',
                                      en: 'Saving...',
                                    )
                                  : _t(
                                      context,
                                      vi: 'Lưu thay đổi',
                                      en: 'Save changes',
                                    ),
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      _pendingSuccessMessage = _t(
                                        context,
                                        vi: 'Hồ sơ đã được cập nhật nhẹ nhàng rồi nè.',
                                        en: 'Your profile has been updated successfully.',
                                      );
                                      await cubit.updateProfile(
                                        _composeProfile(profile),
                                      );
                                    },
                            ),
                            const SizedBox(height: GrowMateLayout.space12),
                          ] else ...[
                            _buildPrivacyPlanCard(
                              context: context,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: GrowMateLayout.sectionGapLg),
                            _buildSystemCard(
                              context: context,
                              authBloc: authBloc,
                              profile: profile,
                              isProcessing: isProcessing,
                            ),
                            const SizedBox(height: GrowMateLayout.space12),
                          ],
                        ],
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

  Widget _buildHeader(UserProfile? profile) {
    final name = _displayName(profile?.fullName);
    final avatarUrl = profile?.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'B';
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _showAvatarComingSoon,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer.withValues(
                alpha: _isDark(context) ? 0.7 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _AvatarFallback(initial: initial);
                      },
                    )
                  : _AvatarFallback(initial: initial),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _t(context, vi: 'Chào $name', en: 'Hi $name'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _IconCircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            context.push(AppRoutes.notifications);
          },
        ),
      ],
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
            title: _t(context, vi: 'Thông tin cá nhân', en: 'Personal info'),
            subtitle: _t(
              context,
              vi: 'Cập nhật hồ sơ để AI hỗ trợ chính xác hơn.',
              en: 'Update your profile so AI can support you more accurately.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _FieldCaption(_t(context, vi: 'Tên hiển thị', en: 'Display name')),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            controller: _fullNameController,
            enabled: !isProcessing,
            decoration: _softFieldDecoration(
              hint: _t(context, vi: 'Nhập tên của bạn', en: 'Enter your name'),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return _t(
                  context,
                  vi: 'Bạn thêm tên để mình xưng hô dễ hơn nhé.',
                  en: 'Please add your name so the app can address you better.',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _FieldCaption(_t(context, vi: 'Email', en: 'Email')),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            decoration: _softFieldDecoration(),
          ),
          const SizedBox(height: 12),
          _FieldCaption(_t(context, vi: 'Khối lớp', en: 'Grade level')),
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
            title: _t(
              context,
              vi: 'Môn học đang tập trung',
              en: 'Focus subjects',
            ),
            subtitle: _t(
              context,
              vi: 'Chọn các môn bạn muốn AI ưu tiên trong lộ trình.',
              en: 'Choose the subjects you want AI to prioritize.',
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
            title: _t(context, vi: 'Nhịp học AI', en: 'AI Rhythm'),
            subtitle: _t(
              context,
              vi: 'Điều chỉnh nhịp học và phong cách gợi ý của trợ lý AI.',
              en: 'Adjust learning pace and suggestion style of the AI assistant.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: _t(
              context,
              vi: 'Bật chế độ phục hồi',
              en: 'Enable Recovery Mode',
            ),
            subtitle: _t(
              context,
              vi: 'Khi mệt, hệ thống sẽ ưu tiên can thiệp dịu hơn.',
              en: 'When tired, the system will prioritize gentler interventions.',
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
            _t(context, vi: 'Nhịp học ưu tiên', en: 'Preferred pace'),
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
          _FieldCaption(_t(context, vi: 'Kiểu gợi ý', en: 'Hint style')),
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
            title: _t(context, vi: 'Quyền riêng tư', en: 'Privacy'),
            subtitle: _t(
              context,
              vi: 'Quản lý quyền dữ liệu học tập của bạn.',
              en: 'Manage your learning data permissions.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: _t(
              context,
              vi: 'Cho phép tín hiệu hành vi',
              en: 'Allow behavioral signals',
            ),
            subtitle: _t(
              context,
              vi: 'Bật khi bạn muốn hệ thống tối ưu theo nhịp gõ.',
              en: 'Turn on to let the system adapt to your interaction rhythm.',
            ),
            value: _consentBehavioral,
            onChanged: isProcessing
                ? null
                : (value) async {
                    setState(() {
                      _consentBehavioral = value;
                    });
                    _pendingSuccessMessage = value
                        ? _t(
                            context,
                            vi: 'Đã bật thu thập tín hiệu học tập để cá nhân hóa nhịp học.',
                            en: 'Behavioral learning signals are now enabled.',
                          )
                        : _t(
                            context,
                            vi: 'Đã tắt thu thập tín hiệu học tập theo lựa chọn của bạn.',
                            en: 'Behavioral learning signals are now disabled.',
                          );
                    await cubit.toggleConsent(consentBehavioral: value);
                  },
          ),
          const Divider(height: 22, thickness: 0.6, color: Color(0x1A64748B)),
          _ToggleLine(
            title: _t(
              context,
              vi: 'Cho phép analytics tổng quan',
              en: 'Allow aggregate analytics',
            ),
            subtitle: _t(
              context,
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
                        ? _t(
                            context,
                            vi: 'Đã bật analytics tổng quan để cải thiện trải nghiệm.',
                            en: 'Aggregate analytics are now enabled.',
                          )
                        : _t(
                            context,
                            vi: 'Đã tắt analytics tổng quan theo lựa chọn của bạn.',
                            en: 'Aggregate analytics are now disabled.',
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
            title: _t(context, vi: 'Gói học tập', en: 'Study plan'),
            subtitle: _t(
              context,
              vi: 'Quản lý gói dịch vụ phù hợp với nhu cầu học của bạn.',
              en: 'Manage the service plan that fits your study needs.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _FieldCaption(_t(context, vi: 'Lựa chọn gói', en: 'Plan option')),
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
                          : '${_toTierLabel(tier)} (${_t(context, vi: 'Sắp có', en: 'Coming soon')})',
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
                              _t(
                                context,
                                vi: 'Gói ${_toTierLabel(value)} sẽ có trong bản cập nhật sau.',
                                en: '${_toTierLabel(value)} plan will be available in a future update.',
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
                              _t(
                                context,
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

                    _pendingSuccessMessage = _t(
                      context,
                      vi: 'Đã chuyển về gói Free.',
                      en: 'Switched back to Free plan.',
                    );
                    await cubit.changeSubscription('free');
                  },
          ),
          const SizedBox(height: GrowMateLayout.space8),
          Text(
            '${_t(context, vi: 'Hiện tại', en: 'Current')}: ${_toTierLabel(_subscriptionTier)}',
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
    final languageCubit = context.read<AppLanguageCubit>();
    final offlineRepository = OfflineModeRepository.instance;
    const settingContentInset = 46.0;

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: _t(context, vi: 'Hệ thống', en: 'System'),
            subtitle: _t(
              context,
              vi: 'Thông tin ứng dụng, hỗ trợ và phiên đăng nhập.',
              en: 'App information, support, and login session.',
            ),
          ),
          const SizedBox(height: GrowMateLayout.space8),
          _settingsClusterLabel(context, vi: 'Dùng hằng ngày', en: 'Daily use'),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: _t(context, vi: 'Thông báo', en: 'Notifications'),
            subtitle: _t(
              context,
              vi: 'Xem nhắc nhở và cập nhật gần đây.',
              en: 'View recent reminders and updates.',
            ),
            onTap: () {
              context.push(AppRoutes.notifications);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            title: _t(context, vi: 'Lịch thông minh', en: 'Smart Schedule'),
            subtitle: _t(
              context,
              vi: 'Quản lý lịch thi và hạn nộp để AI ưu tiên ôn tập.',
              en: 'Manage exams and deadlines so AI can prioritize your review.',
            ),
            onTap: () {
              context.push(AppRoutes.schedule);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.spa_rounded,
            title: _t(context, vi: 'Nghỉ thở 90 giây', en: 'Mindful Break 90s'),
            subtitle: _t(
              context,
              vi: 'Thả lỏng nhẹ nhịp thở trước khi học tiếp.',
              en: 'Reset your breathing rhythm before continuing.',
            ),
            onTap: () {
              context.push(AppRoutes.mindfulBreak);
            },
          ),
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(
            context,
            vi: 'Cá nhân hóa',
            en: 'Personalization',
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          BlocBuilder<ThemeModeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDarkMode = themeMode == ThemeMode.dark;

              return _ToggleLine(
                icon: Icons.dark_mode_rounded,
                title: _t(context, vi: 'Chế độ tối', en: 'Dark Mode'),
                subtitle: isDarkMode
                    ? _t(
                        context,
                        vi: 'Giao diện tối đang được bật để dịu mắt hơn vào ban đêm.',
                        en: 'Dark interface is on for more comfortable night viewing.',
                      )
                    : _t(
                        context,
                        vi: 'Bật giao diện tối để giảm chói mắt khi học buổi tối.',
                        en: 'Enable dark interface to reduce eye strain at night.',
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
                                    ? _t(
                                        context,
                                        vi: 'Đã bật Chế độ tối.',
                                        en: 'Dark Mode enabled.',
                                      )
                                    : _t(
                                        context,
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
          BlocBuilder<AppLanguageCubit, AppLanguage>(
            builder: (context, language) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingFieldHeader(
                      icon: Icons.language_rounded,
                      title: _t(context, vi: 'Ngôn ngữ', en: 'Language'),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: Text(
                        _t(
                          context,
                          vi: 'Chuyển nhanh giữa Tiếng Việt và English.',
                          en: 'Switch quickly between Vietnamese and English.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: DropdownButtonFormField<AppLanguage>(
                        initialValue: language,
                        decoration: _softFieldDecoration(),
                        style: _dropdownValueStyle(context),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        items: AppLanguage.values
                            .map(
                              (option) => DropdownMenuItem<AppLanguage>(
                                value: option,
                                child: _dropdownOptionText(
                                  context,
                                  _languageLabel(context, option),
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

                                await languageCubit.setLanguage(value);

                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _languageChangedMessage(context, value),
                                        style: _snackTextStyle(context),
                                      ),
                                      backgroundColor: _successSnackBackground(
                                        context,
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
                      title: _t(
                        context,
                        vi: 'Bảng màu giao diện',
                        en: 'Color palette',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: settingContentInset),
                      child: Text(
                        _t(
                          context,
                          vi: 'Mặc định là xanh lá - vàng. Bạn có thể đổi nhanh theo sở thích.',
                          en: 'Default is Green - Yellow. You can quickly switch it anytime.',
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

                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _paletteChangedMessage(context, value),
                                        style: _snackTextStyle(context),
                                      ),
                                      backgroundColor: _successSnackBackground(
                                        context,
                                      ),
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
          _settingsClusterLabel(
            context,
            vi: 'Hệ thống & hỗ trợ',
            en: 'System & support',
          ),
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
                  ? _t(
                      context,
                      vi: 'Đang lưu tín hiệu cục bộ. Hàng đợi: ${offlineState.queuedSignals}.',
                      en: 'Saving signals locally. Queue: ${offlineState.queuedSignals}.',
                    )
                  : offlineState.queuedSignals > 0
                  ? _t(
                      context,
                      vi: 'Sẵn sàng đồng bộ ${offlineState.queuedSignals} tín hiệu khi mạng ổn định.',
                      en: 'Ready to sync ${offlineState.queuedSignals} signals when network is stable.',
                    )
                  : _t(
                      context,
                      vi: 'Tự động queue tín hiệu khi mất mạng.',
                      en: 'Automatically queue signals while offline.',
                    );

              return _ToggleLine(
                icon: Icons.cloud_off_rounded,
                title: _t(
                  context,
                  vi: 'Chế độ ngoại tuyến',
                  en: 'Offline Mode',
                ),
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
                                    ? _t(
                                        context,
                                        vi: 'Đã bật Chế độ ngoại tuyến. Tín hiệu sẽ được lưu cục bộ.',
                                        en: 'Offline Mode enabled. Signals will be queued locally.',
                                      )
                                    : _t(
                                        context,
                                        vi: 'Đã tắt Chế độ ngoại tuyến. Ứng dụng sẽ đồng bộ lại khi có thể.',
                                        en: 'Offline Mode disabled. The app will sync when possible.',
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
            title: _t(
              context,
              vi: 'Hỗ trợ & phản hồi',
              en: 'Support & feedback',
            ),
            subtitle: _t(
              context,
              vi: 'Gửi góp ý để GrowMate hỗ trợ bạn tốt hơn.',
              en: 'Share feedback to help GrowMate support you better.',
            ),
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      _t(
                        context,
                        vi: 'Cảm ơn bạn. Kênh góp ý sẽ mở trong bản kế tiếp.',
                        en: 'Thank you. Feedback channel will be available in the next release.',
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
            title: _t(context, vi: 'Phiên bản ứng dụng', en: 'App version'),
            subtitle: widget.appVersion,
          ),
          const SizedBox(height: GrowMateLayout.space24),
          _settingsClusterLabel(
            context,
            vi: 'Dữ liệu & pháp lý',
            en: 'Data & legal',
          ),
          _MenuTile(
            icon: Icons.download_rounded,
            title: _t(
              context,
              vi: 'Tải dữ liệu cá nhân',
              en: 'Export personal data',
            ),
            subtitle: _t(
              context,
              vi: 'Xuất JSON hồ sơ, timeline phiên và notification.',
              en: 'Export profile JSON, session timeline, and notifications.',
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
            title: _t(
              context,
              vi: 'Điều khoản sử dụng',
              en: 'Terms of service',
            ),
            subtitle: _t(
              context,
              vi: 'Xem quy định sử dụng dịch vụ GrowMate.',
              en: 'View GrowMate service terms.',
            ),
            onTap: () {
              context.push(AppRoutes.termsOfService);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            title: _t(
              context,
              vi: 'Chính sách quyền riêng tư',
              en: 'Privacy policy',
            ),
            subtitle: _t(
              context,
              vi: 'Tìm hiểu cách GrowMate xử lý dữ liệu của bạn.',
              en: 'Learn how GrowMate handles your data.',
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
                  title: _t(
                    context,
                    vi: 'Chế độ Dev (Auditor)',
                    en: 'Dev Mode (Auditor)',
                  ),
                  subtitle: _t(
                    context,
                    vi: 'Bật để hiện nút AI Insight ở góc phải trên Trang chủ.',
                    en: 'Enable to show the AI Insight button on the Today top-right corner.',
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
                                      ? _t(
                                          context,
                                          vi: 'Đã bật Chế độ Dev. Vào Trang chủ và nhấn nút AI Insight ở góc phải trên.',
                                          en: 'Dev Mode enabled. Open Today and tap the AI Insight button at the top-right.',
                                        )
                                      : _t(
                                          context,
                                          vi: 'Đã tắt Chế độ Dev. Nút AI Insight sẽ được ẩn.',
                                          en: 'Dev Mode disabled. The AI Insight button is now hidden.',
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
                ? _t(context, vi: 'Đang xử lý...', en: 'Processing...')
                : _t(context, vi: 'Xóa tài khoản', en: 'Delete account'),
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
                ? _t(context, vi: 'Đang xử lý...', en: 'Processing...')
                : _t(context, vi: 'Đăng xuất', en: 'Log out'),
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
          title: Text(_t(context, vi: 'Xóa tài khoản', en: 'Delete account')),
          content: Text(
            _t(
              context,
              vi: 'Bạn có chắc muốn xóa toàn bộ dữ liệu cá nhân trên thiết bị và hồ sơ học tập hiện tại không?',
              en: 'Are you sure you want to delete all personal data on this device and your current learning profile?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(_t(context, vi: 'Hủy', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(_t(context, vi: 'Xóa ngay', en: 'Delete now')),
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
              _t(
                context,
                vi: 'Đã xóa dữ liệu tài khoản. Bạn có thể đăng ký lại bất cứ lúc nào.',
                en: 'Account data deleted. You can sign up again anytime.',
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
              _t(
                context,
                vi: 'Mình chưa xóa được tài khoản lúc này, bạn thử lại giúp mình nhé.',
                en: 'Unable to delete the account right now. Please try again.',
              ),
              style: _snackTextStyle(context),
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
        _t(context, vi: vi, en: en),
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

  static String _displayName(String? fullName) {
    final value = fullName?.trim();
    if (value == null || value.isEmpty) {
      return 'Huy';
    }
    final parts = value.split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Huy' : parts.last;
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
        return _t(context, vi: 'Toán', en: 'Mathematics');
      case 'Vật lý':
        return _t(context, vi: 'Vật lý', en: 'Physics');
      case 'Hóa học':
        return _t(context, vi: 'Hóa học', en: 'Chemistry');
      case 'Sinh học':
        return _t(context, vi: 'Sinh học', en: 'Biology');
      case 'Ngữ văn':
        return _t(context, vi: 'Ngữ văn', en: 'Literature');
      case 'Tiếng Anh':
        return _t(context, vi: 'Tiếng Anh', en: 'English');
      default:
        return subject;
    }
  }

  String _gradeLabel(BuildContext context, String grade) {
    switch (grade) {
      case 'Lớp 10':
        return _t(context, vi: 'Lớp 10', en: 'Grade 10');
      case 'Lớp 11':
        return _t(context, vi: 'Lớp 11', en: 'Grade 11');
      case 'Lớp 12':
        return _t(context, vi: 'Lớp 12', en: 'Grade 12');
      case 'Đại học năm 1':
        return _t(context, vi: 'Đại học năm 1', en: 'University year 1');
      default:
        return grade;
    }
  }

  String _toPaceLabel(BuildContext context, String pace) {
    switch (pace) {
      case 'focused':
        return _t(context, vi: 'Tập trung', en: 'Focused');
      case 'balanced':
        return _t(context, vi: 'Cân bằng', en: 'Balanced');
      default:
        return _t(context, vi: 'Nhẹ nhàng', en: 'Gentle');
    }
  }

  String _toHintStyleLabel(BuildContext context, String hintStyle) {
    switch (hintStyle) {
      case 'concept_first':
        return _t(context, vi: 'Ưu tiên khái niệm', en: 'Concept first');
      case 'minimal':
        return _t(context, vi: 'Gợi ý tối giản', en: 'Minimal hints');
      default:
        return _t(context, vi: 'Từng bước', en: 'Step by step');
    }
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

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: colors.onSurface, size: 21),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
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
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final colors = Theme.of(context).colorScheme;

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
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
