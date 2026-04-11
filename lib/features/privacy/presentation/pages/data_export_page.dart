import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../data/repositories/privacy_repository.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({
    super.key,
    required this.userId,
    required this.email,
    required this.privacyRepository,
  });

  final String userId;
  final String email;
  final PrivacyRepository privacyRepository;

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  late final Future<String> _exportFuture;

  @override
  void initState() {
    super.initState();
    _exportFuture = _buildExportString();
  }

  Future<String> _buildExportString() async {
    final payload = await widget.privacyRepository.buildPersonalDataExport(
      userId: widget.userId,
      email: widget.email,
    );

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: FutureBuilder<String>(
          future: _exportFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final payload = snapshot.data ?? '';

            return ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(AppRoutes.settings);
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.t(
                        vi: 'Xuất dữ liệu cá nhân',
                        en: 'Export personal data',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.t(
                    vi: 'Tập JSON này bao gồm hồ sơ, lịch sử phiên học và notification của bạn.',
                    en: 'This JSON payload includes your profile, session history, and notifications.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (hasError)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.t(
                        vi: 'Chưa xuất được dữ liệu lúc này. Bạn thử lại sau nhé.',
                        en: 'Unable to export data right now. Please try again later.',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: payload));

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                context.t(
                                  vi: 'Đã sao chép dữ liệu JSON.',
                                  en: 'JSON data copied to clipboard.',
                                ),
                              ),
                            ),
                          );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(
                        context.t(vi: 'Sao chép JSON', en: 'Copy JSON'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(
                      payload,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
