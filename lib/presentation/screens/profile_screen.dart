import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/layout.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/inspection/presentation/cubit/inspection_cubit.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/nav_tab_routing.dart';
import '../../shared/widgets/zen_page_container.dart';
import '../cubit/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profileRepository,
    required this.appVersion,
  });

  final ProfileRepository profileRepository;
  final String appVersion;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _screenBackground = Color(0xFFF5F7FB);
  static const Color _softInputBackground = Color(0xFFF0F4FA);
  static const Color _tagSelected = Color(0xFFEAF2FF);
  static const Color _tagUnselected = Color(0xFFEFF3F8);

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
  String? _pendingSuccessMessage;

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
                    content: Text(_pendingSuccessMessage!),
                    backgroundColor: const Color(0xFFDDF3E5),
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
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFFDE8D7),
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
            backgroundColor: _screenBackground,
            body: ZenPageContainer(
              child: ListView(
                children: [
                  _buildHeader(profile),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  Text('Hồ sơ', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: GrowMateLayout.space8),
                  Text(
                    'Thiết lập cá nhân hóa để AI ra quyết định chính xác hơn cho từng phiên học.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: GrowMateColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.sectionGap),
                  if (profile == null && state is! ProfileLoading)
                    _CalmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: GrowMateColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mình chưa tải được hồ sơ lúc này.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: GrowMateLayout.contentGap),
                          _PrimaryGradientButton(
                            label: 'Tải lại',
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
                          _buildPrivacyPlanCard(
                            context: context,
                            profile: profile,
                            isProcessing: isProcessing,
                          ),
                          const SizedBox(height: GrowMateLayout.sectionGapLg),
                          _buildSystemCard(
                            context: context,
                            authBloc: authBloc,
                            isProcessing: isProcessing,
                          ),
                          const SizedBox(height: GrowMateLayout.sectionGapLg),
                          _PrimaryGradientButton(
                            label: isProcessing
                                ? 'Đang lưu...'
                                : 'Lưu thay đổi',
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    _pendingSuccessMessage =
                                        'Hồ sơ đã được cập nhật nhẹ nhàng rồi nè.';
                                    await cubit.updateProfile(
                                      _composeProfile(profile),
                                    );
                                  },
                          ),
                          const SizedBox(height: GrowMateLayout.space12),
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
              currentTab: GrowMateTab.profile,
              onTabSelected: (tab) => handleTabNavigation(context, tab),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserProfile? profile) {
    final name = _displayName(profile?.fullName);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEAF2FF),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: GrowMateColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Chào $name',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: GrowMateColors.textPrimary,
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

  Widget _buildPersonalInfoCard({
    required BuildContext context,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            title: 'Thông tin cá nhân',
            subtitle: 'Cập nhật hồ sơ để AI hỗ trợ chính xác hơn.',
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          const _FieldCaption('Tên hiển thị'),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            controller: _fullNameController,
            enabled: !isProcessing,
            decoration: _softFieldDecoration(hint: 'Nhập tên của bạn'),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bạn thêm tên để mình xưng hô dễ hơn nhé.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          const _FieldCaption('Email'),
          const SizedBox(height: GrowMateLayout.space8),
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            decoration: _softFieldDecoration(),
          ),
          const SizedBox(height: 12),
          const _FieldCaption('Khối lớp'),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue: _gradeOptions.contains(_gradeLevel)
                ? _gradeLevel
                : null,
            decoration: _softFieldDecoration(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: GrowMateColors.textSecondary,
            ),
            items: _gradeOptions
                .map(
                  (grade) => DropdownMenuItem<String>(
                    value: grade,
                    child: Text(grade),
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
          const _CardHeading(
            title: 'Môn học đang tập trung',
            subtitle: 'Chọn các môn bạn muốn AI ưu tiên trong lộ trình.',
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
                    backgroundColor: _tagUnselected,
                    selectedColor: _tagSelected,
                    label: Text(
                      subject,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? GrowMateColors.primaryDark
                            : GrowMateColors.textSecondary,
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
    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'AI Rhythm',
            subtitle: 'Điều chỉnh nhịp học và phong cách gợi ý của trợ lý AI.',
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: 'Bật Recovery Mode',
            subtitle: 'Khi mệt, hệ thống sẽ ưu tiên can thiệp dịu hơn.',
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
          const _FieldCaption('Nhịp học ưu tiên'),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue: _paceOptions.contains(_learningPreferences['pace'])
                ? _learningPreferences['pace'] as String
                : _paceOptions.first,
            decoration: _softFieldDecoration(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: GrowMateColors.textSecondary,
            ),
            items: _paceOptions
                .map(
                  (pace) => DropdownMenuItem<String>(
                    value: pace,
                    child: Text(_toPaceLabel(pace)),
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
          const _FieldCaption('Kiểu gợi ý'),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue:
                _hintStyleOptions.contains(_learningPreferences['hint_style'])
                ? _learningPreferences['hint_style'] as String
                : _hintStyleOptions.first,
            decoration: _softFieldDecoration(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: GrowMateColors.textSecondary,
            ),
            items: _hintStyleOptions
                .map(
                  (hintStyle) => DropdownMenuItem<String>(
                    value: hintStyle,
                    child: Text(_toHintStyleLabel(hintStyle)),
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
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final cubit = context.read<ProfileCubit>();

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Quyền riêng tư & gói học',
            subtitle: 'Quản lý dữ liệu học tập và gói dịch vụ của bạn.',
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          _ToggleLine(
            title: 'Cho phép tín hiệu hành vi',
            subtitle: 'Bật khi bạn muốn hệ thống tối ưu theo nhịp gõ.',
            value: _consentBehavioral,
            onChanged: isProcessing
                ? null
                : (value) async {
                    setState(() {
                      _consentBehavioral = value;
                    });
                    _pendingSuccessMessage = value
                        ? 'Đã bật thu thập tín hiệu học tập để cá nhân hóa nhịp học.'
                        : 'Đã tắt thu thập tín hiệu học tập theo lựa chọn của bạn.';
                    await cubit.toggleConsent(consentBehavioral: value);
                  },
          ),
          const Divider(height: 22, thickness: 0.6, color: Color(0x1A64748B)),
          _ToggleLine(
            title: 'Cho phép analytics tổng quan',
            subtitle: 'Không ảnh hưởng đến bài học cốt lõi.',
            value: _consentAnalytics,
            onChanged: isProcessing
                ? null
                : (value) async {
                    setState(() {
                      _consentAnalytics = value;
                    });
                    _pendingSuccessMessage = value
                        ? 'Đã bật analytics tổng quan để cải thiện trải nghiệm.'
                        : 'Đã tắt analytics tổng quan theo lựa chọn của bạn.';
                    await cubit.toggleConsent(consentAnalytics: value);
                  },
          ),
          const SizedBox(height: GrowMateLayout.contentGap),
          const _FieldCaption('Gói học tập'),
          const SizedBox(height: GrowMateLayout.space8),
          DropdownButtonFormField<String>(
            initialValue: _subscriptionOptions.contains(_subscriptionTier)
                ? _subscriptionTier
                : 'free',
            decoration: _softFieldDecoration(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: GrowMateColors.textSecondary,
            ),
            items: _subscriptionOptions
                .map(
                  (tier) => DropdownMenuItem<String>(
                    value: tier,
                    child: Text(_toTierLabel(tier)),
                  ),
                )
                .toList(growable: false),
            onChanged: isProcessing
                ? null
                : (value) async {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _subscriptionTier = value;
                    });
                    _pendingSuccessMessage = 'Đã chuyển gói học thành công.';
                    await cubit.changeSubscription(value);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện tại: ${_toTierLabel(profile.subscriptionTier)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard({
    required BuildContext context,
    required AuthBloc authBloc,
    required bool isProcessing,
  }) {
    final inspectionCubit = _tryGetInspectionCubit(context);

    return _CalmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            title: 'Hệ thống',
            subtitle: 'Thông tin ứng dụng, hỗ trợ và phiên đăng nhập.',
          ),
          const SizedBox(height: GrowMateLayout.space8),
          _MenuTile(
            icon: Icons.verified_rounded,
            title: 'Phiên bản ứng dụng',
            subtitle: widget.appVersion,
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            subtitle: 'Xem nhắc nhở và cập nhật gần đây.',
            onTap: () {
              context.push(AppRoutes.notifications);
            },
          ),
          const Divider(height: 1, color: Color(0x1464748B)),
          _MenuTile(
            icon: Icons.support_agent_rounded,
            title: 'Hỗ trợ & phản hồi',
            subtitle: 'Gửi góp ý để GrowMate hỗ trợ bạn tốt hơn.',
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cảm ơn bạn. Kênh góp ý sẽ mở trong bản kế tiếp.',
                    ),
                    backgroundColor: Color(0xFFDDF3E5),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            },
          ),
          if (inspectionCubit != null) ...[
            const Divider(height: 1, color: Color(0x1464748B)),
            StreamBuilder<InspectionState>(
              stream: inspectionCubit.stream,
              initialData: inspectionCubit.state,
              builder: (context, snapshot) {
                final inspectionState = snapshot.data ?? inspectionCubit.state;

                return _ToggleLine(
                  title: 'Chế độ Dev (Auditor)',
                  subtitle: 'Hiển thị Mini Inspection ở bản release.',
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
                                      ? 'Đã bật Chế độ Dev cho Mini Inspection Dashboard.'
                                      : 'Đã tắt Chế độ Dev. Dashboard chỉ hiện khi debug.',
                                ),
                                backgroundColor: const Color(0xFFDDF3E5),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                );
              },
            ),
          ],
          const SizedBox(height: GrowMateLayout.contentGap),
          _GhostButton(
            label: isProcessing ? 'Đang xử lý...' : 'Đăng xuất',
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

  InputDecoration _softFieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: _softInputBackground,
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
        borderSide: const BorderSide(color: Color(0x554F8CFF), width: 1),
      ),
      hintStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: GrowMateColors.textSecondary),
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

  static String _toPaceLabel(String pace) {
    switch (pace) {
      case 'focused':
        return 'Tập trung';
      case 'balanced':
        return 'Cân bằng';
      default:
        return 'Nhẹ nhàng';
    }
  }

  static String _toHintStyleLabel(String hintStyle) {
    switch (hintStyle) {
      case 'concept_first':
        return 'Ưu tiên khái niệm';
      case 'minimal':
        return 'Gợi ý tối giản';
      default:
        return 'Từng bước';
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
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: GrowMateColors.primary, size: 18),
            ),
            const SizedBox(width: GrowMateLayout.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GrowMateColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: GrowMateColors.textSecondary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GrowMateLayout.contentGap),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
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
            color: GrowMateColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: GrowMateLayout.space8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: GrowMateColors.textSecondary,
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
        color: GrowMateColors.textSecondary,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _ToggleLine extends StatelessWidget {
  const _ToggleLine({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: GrowMateLayout.space8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GrowMateColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF7FAAFF),
          inactiveTrackColor: const Color(0xFFDCE4F1),
          thumbColor: Colors.white,
        ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x090F172A),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: GrowMateColors.textPrimary, size: 21),
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
              color: const Color(0xFFF1F5FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: GrowMateColors.textPrimary,
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
