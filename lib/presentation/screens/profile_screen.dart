import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../core/constants/colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/inspection/presentation/cubit/inspection_cubit.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/nav_tab_routing.dart';
import '../../shared/widgets/top_app_bar.dart';
import '../../shared/widgets/zen_button.dart';
import '../../shared/widgets/zen_card.dart';
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
            backgroundColor: GrowMateColors.background,
            body: ZenPageContainer(
              child: ListView(
                children: [
                  GrowMateTopAppBar(userName: profile?.fullName),
                  const SizedBox(height: 20),
                  Text(
                    'Bạn đang duy trì nhịp học rất tốt',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nghỉ ngơi là một phần của học tập. Mình tinh chỉnh hồ sơ để lộ trình nhẹ nhàng hơn nhé.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: GrowMateColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile == null && state is! ProfileLoading)
                    ZenCard(
                      radius: 24,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: GrowMateColors.textSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Mình chưa tải được hồ sơ lúc này.',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          ZenButton(
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
                          _buildPersonalSection(
                            context: context,
                            profile: profile,
                            isProcessing: isProcessing,
                          ),
                          const SizedBox(height: 12),
                          _buildLearningSection(isProcessing: isProcessing),
                          const SizedBox(height: 12),
                          _buildPrivacySection(
                            context: context,
                            profile: profile,
                            isProcessing: isProcessing,
                          ),
                          const SizedBox(height: 12),
                          _buildSystemSection(
                            context: context,
                            authBloc: authBloc,
                            isProcessing: isProcessing,
                          ),
                          const SizedBox(height: 16),
                          ZenButton(
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

  Widget _buildPersonalSection({
    required BuildContext context,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);

    return ZenCard(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Personal',
            subtitle: 'Thông tin học viên và môn học đang ưu tiên.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GrowMateColors.primaryContainer.withValues(alpha: 0.5),
                ),
                child: profile.avatarUrl?.isNotEmpty == true
                    ? const Icon(
                        Icons.person_rounded,
                        color: GrowMateColors.primary,
                        size: 36,
                      )
                    : const Icon(
                        Icons.add_a_photo_rounded,
                        color: GrowMateColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Avatar placeholder\n(Tính năng upload sẽ mở ở vòng sau)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GrowMateColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullNameController,
            enabled: !isProcessing,
            decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Bạn thêm tên để mình xưng hô dễ hơn nhé.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: profile.email,
            enabled: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _gradeOptions.contains(_gradeLevel)
                ? _gradeLevel
                : null,
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
            decoration: const InputDecoration(labelText: 'Khối lớp'),
          ),
          const SizedBox(height: 12),
          Text(
            'Môn học đang tập trung',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjectOptions
                .map(
                  (subject) => FilterChip(
                    selected: _activeSubjects.contains(subject),
                    label: Text(subject),
                    onSelected: isProcessing
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _activeSubjects.add(subject);
                              } else {
                                _activeSubjects.remove(subject);
                              }
                            });
                          },
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSection({required bool isProcessing}) {
    return ZenCard(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Learning & Agentic',
            subtitle: 'Nhịp học ưa thích và cơ chế hỗ trợ phục hồi nhẹ.',
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: _recoveryModeEnabled,
            onChanged: isProcessing
                ? null
                : (value) {
                    setState(() {
                      _recoveryModeEnabled = value;
                    });
                  },
            title: const Text('Bật Recovery Mode'),
            subtitle: const Text(
              'Khi mệt, hệ thống sẽ ưu tiên can thiệp dịu hơn.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paceOptions.contains(_learningPreferences['pace'])
                ? _learningPreferences['pace'] as String
                : _paceOptions.first,
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
            decoration: const InputDecoration(labelText: 'Nhịp học ưu tiên'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue:
                _hintStyleOptions.contains(_learningPreferences['hint_style'])
                ? _learningPreferences['hint_style'] as String
                : _hintStyleOptions.first,
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
            decoration: const InputDecoration(labelText: 'Kiểu gợi ý'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection({
    required BuildContext context,
    required UserProfile profile,
    required bool isProcessing,
  }) {
    final cubit = context.read<ProfileCubit>();

    return ZenCard(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Privacy & Subscription',
            subtitle: 'Quyền riêng tư và gói học tập theo nhu cầu của bạn.',
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
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
            title: const Text('Cho phép tín hiệu hành vi'),
            subtitle: const Text(
              'Mặc định tắt. Bật khi bạn muốn hệ thống tối ưu theo nhịp gõ và mức tập trung.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
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
            title: const Text('Cho phép analytics tổng quan'),
            subtitle: const Text(
              'Mặc định tắt. Không ảnh hưởng đến bài học cốt lõi.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _subscriptionOptions.contains(_subscriptionTier)
                ? _subscriptionTier
                : 'free',
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
            decoration: const InputDecoration(labelText: 'Gói học tập'),
          ),
          const SizedBox(height: 10),
          Text(
            'Hiện tại: ${_toTierLabel(profile.subscriptionTier)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection({
    required BuildContext context,
    required AuthBloc authBloc,
    required bool isProcessing,
  }) {
    final theme = Theme.of(context);
    final inspectionCubit = _tryGetInspectionCubit(context);

    return ZenCard(
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'System',
            subtitle: 'Thông tin ứng dụng, hỗ trợ và quản lý phiên đăng nhập.',
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.verified_rounded,
            title: 'Phiên bản ứng dụng',
            subtitle: widget.appVersion,
          ),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification',
            subtitle: 'Xem nhắc nhở và cập nhật học tập gần đây.',
            onTap: () {
              context.push(AppRoutes.notifications);
            },
          ),
          _MenuTile(
            icon: Icons.support_agent_rounded,
            title: 'Help & Feedback',
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
          if (inspectionCubit != null)
            StreamBuilder<InspectionState>(
              stream: inspectionCubit.stream,
              initialData: inspectionCubit.state,
              builder: (context, snapshot) {
                final inspectionState = snapshot.data ?? inspectionCubit.state;

                return SwitchListTile.adaptive(
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
                  title: const Text('Chế độ Dev (Auditor)'),
                  subtitle: const Text(
                    'Bật để hiển thị Mini Inspection ở bản release. Trong debug mode, dashboard luôn khả dụng.',
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          const SizedBox(height: 8),
          ZenButton(
            label: isProcessing ? 'Đang xử lý...' : 'Đăng xuất',
            variant: ZenButtonVariant.secondary,
            onPressed: isProcessing
                ? null
                : () {
                    authBloc.add(const LogoutRequested());
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'Mình luôn ở đây để đồng hành cùng nhịp học của bạn.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: GrowMateColors.textSecondary,
            ),
          ),
        ],
      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: GrowMateColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
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
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: GrowMateColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: GrowMateColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
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
            ),
        ],
      ),
    );

    if (onTap == null) {
      return tile;
    }

    return GestureDetector(onTap: onTap, child: tile);
  }
}
