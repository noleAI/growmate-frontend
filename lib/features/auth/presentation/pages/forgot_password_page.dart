import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_text_field.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    setState(() => _emailError = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email');
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Email không hợp lệ');
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (_isSending || !_validateEmail()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.authRepository.sendPasswordResetLink(
        email: _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                vi: 'Mình đã gửi link khôi phục rồi, bạn kiểm tra email nhé ✨',
                en: 'Reset link sent. Please check your email ✨',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.go(AppRoutes.login);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                vi: 'Kết nối hơi chậm, mình thử lại một chút nhé 🌿',
                en: 'Connection looks slow. Please try again in a moment 🌿',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ZenPageContainer(
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.t(vi: 'Quên mật khẩu?', en: 'Forgot password?'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.t(
                vi: 'Nhập email để nhận link khôi phục',
                en: 'Enter your email to receive a reset link',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ZenCard(
              radius: GrowMateLayout.cardRadius,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZenTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        hintText: context.t(vi: 'Email', en: 'Email'),
                        enabled: !_isSending,
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_emailError != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _emailError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  ZenButton(
                    label: _isSending
                        ? context.t(vi: 'Đang gửi...', en: 'Sending...')
                        : context.t(
                            vi: 'Gửi link khôi phục',
                            en: 'Send reset link',
                          ),
                    onPressed: _isSending ? null : _submit,
                    trailing: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
