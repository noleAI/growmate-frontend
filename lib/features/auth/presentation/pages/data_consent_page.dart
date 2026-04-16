import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../core/services/behavioral_signal_collector.dart';
import '../../../../core/services/behavioral_signal_service.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/repositories/data_consent_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class DataConsentPage extends StatefulWidget {
  const DataConsentPage({super.key, required this.dataConsentRepository});

  final DataConsentRepository dataConsentRepository;

  @override
  State<DataConsentPage> createState() => _DataConsentPageState();
}

class _DataConsentPageState extends State<DataConsentPage> {
  bool _accepted = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final authState = context.read<AuthBloc>().state;
    final userKey = authState is AuthAuthenticated
        ? authState.session.email
        : null;
    final accepted = await widget.dataConsentRepository.isAccepted(
      userKey: userKey,
    );
    if (!mounted) {
      return;
    }

    if (accepted) {
      context.go(AppRoutes.home);
      return;
    }

    setState(() {
      _accepted = accepted;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_saving || !_accepted) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final authState = context.read<AuthBloc>().state;
    final userKey = authState is AuthAuthenticated
        ? authState.session.email
        : null;
    await widget.dataConsentRepository.saveConsent(
      accepted: true,
      userKey: userKey,
    );
    BehavioralSignalService.instance.setCollectionEnabled(true);
    BehavioralSignalCollector.instance.setCollectionEnabled(true);

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const SizedBox(height: GrowMateLayout.space12),
                  Text(
                    context.t(
                      vi: 'GrowMate thu thập gì?',
                      en: 'What does GrowMate collect?',
                    ),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: GrowMateLayout.space12),
                  Text(
                    context.t(
                      vi: 'Để cá nhân hóa phiên học, GrowMate cần bạn đồng ý trước khi thu thập tín hiệu hành vi.',
                      en: 'To personalize your sessions, GrowMate needs your consent before collecting behavioral signals.',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space16),
                  ZenCard(
                    radius: GrowMateLayout.cardRadius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ConsentBullet(
                          text: context.t(
                            vi: 'Tốc độ gõ trong lúc làm bài',
                            en: 'Typing speed while answering',
                          ),
                        ),
                        const SizedBox(height: GrowMateLayout.space8),
                        _ConsentBullet(
                          text: context.t(
                            vi: 'Thời gian idle khi tạm ngừng tương tác',
                            en: 'Idle time when interaction pauses',
                          ),
                        ),
                        const SizedBox(height: GrowMateLayout.space8),
                        _ConsentBullet(
                          text: context.t(
                            vi: 'Tỷ lệ sửa đáp án trước khi gửi',
                            en: 'Correction rate before submission',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space12),
                  ZenCard(
                    radius: GrowMateLayout.cardRadius,
                    child: Text(
                      context.t(
                        vi: 'Mục đích sử dụng: ước lượng trạng thái tinh thần và cá nhân hóa lộ trình học cho bạn.',
                        en: 'Usage purpose: estimate mental state and personalize your learning path.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        context.t(
                          vi: 'Xem Chính sách bảo mật',
                          en: 'View Privacy Policy',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: GrowMateLayout.space8),
                  SwitchListTile(
                    value: _accepted,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.t(
                        vi: 'Tôi đồng ý cho GrowMate thu thập tín hiệu hành vi',
                        en: 'I agree to let GrowMate collect behavioral signals',
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged: _saving
                        ? null
                        : (value) {
                            setState(() {
                              _accepted = value;
                            });
                            BehavioralSignalService.instance
                                .setCollectionEnabled(value);
                            BehavioralSignalCollector.instance
                                .setCollectionEnabled(value);
                          },
                  ),
                  const SizedBox(height: GrowMateLayout.space12),
                  ZenButton(
                    label: _saving
                        ? context.t(vi: 'Đang lưu...', en: 'Saving...')
                        : context.t(vi: 'Tiếp tục', en: 'Continue'),
                    onPressed: (!_accepted || _saving) ? null : _submit,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ConsentBullet extends StatelessWidget {
  const _ConsentBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, size: 18, color: colors.primary),
        const SizedBox(width: GrowMateLayout.space8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
