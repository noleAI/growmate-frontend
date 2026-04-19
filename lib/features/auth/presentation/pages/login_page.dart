import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/i18n/build_context_i18n.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/layout.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
import '../../../../shared/widgets/zen_screen_header.dart';
import '../../../../shared/widgets/zen_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  bool _validateForm() {
    _clearErrors();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;

    if (email.isEmpty) {
      setState(() {
        _emailError = context.t(
          vi: 'Vui lòng nhập email',
          en: 'Please enter your email',
        );
      });
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = context.t(
          vi: 'Email không hợp lệ',
          en: 'Invalid email address',
        );
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = context.t(
          vi: 'Vui lòng nhập mật khẩu',
          en: 'Please enter your password',
        );
      });
      hasError = true;
    }

    return !hasError;
  }

  void _submit() {
    if (!_validateForm()) return;

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSoftMessage(
              context,
              _localizedAuthMessage(context, state.message),
            );
          }

          if (state is AuthAuthenticated) {
            _showSoftMessage(
              context,
              context.t(
                vi: 'Chào mừng bạn quay lại, ${state.session.displayName} ✨',
                en: 'Welcome back, ${state.session.displayName} ✨',
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final theme = Theme.of(context);

          return ZenPageContainer(
            child: ListView(
              children: [
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ZenScreenHeader(
                  eyebrow: context.t(
                    vi: 'Đăng nhập an toàn',
                    en: 'Secure sign-in',
                  ),
                  title: context.t(
                    vi: 'Chào mừng bạn quay lại',
                    en: 'Welcome back',
                  ),
                  subtitle: context.t(
                    vi: 'Đăng nhập để đồng bộ tiến trình, tiếp tục phiên học và nhận gợi ý AI đúng nhịp.',
                    en: 'Sign in to sync your progress, resume sessions, and get AI guidance tuned to your pace.',
                  ),
                  icon: Icons.lock_person_rounded,
                  chips: [
                    ZenHeaderChipData(
                      label: context.t(
                        vi: 'Đồng bộ tiến trình',
                        en: 'Progress sync',
                      ),
                      icon: Icons.cloud_done_rounded,
                    ),
                    ZenHeaderChipData(
                      label: context.t(
                        vi: 'Tiếp tục phiên học',
                        en: 'Resume learning',
                      ),
                      icon: Icons.play_circle_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ZenCard(
                  radius: GrowMateLayout.cardRadius,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  showShadow: true,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        hintText: context.t(vi: 'Email', en: 'Email'),
                        enabled: !isLoading,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: context.t(vi: 'Mật khẩu', en: 'Password'),
                        enabled: !isLoading,
                        error: _passwordError,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          child: Text(
                            context.t(
                              vi: 'Quên mật khẩu?',
                              en: 'Forgot password?',
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      ZenButton(
                        label: isLoading
                            ? context.t(
                                vi: 'Đang đăng nhập...',
                                en: 'Signing in...',
                              )
                            : context.t(vi: 'Đăng nhập', en: 'Log in'),
                        onPressed: isLoading ? null : _submit,
                        trailing: isLoading
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
                const SizedBox(height: 14),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        context.t(
                          vi: 'Chưa có tài khoản?',
                          en: 'Do not have an account?',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: isLoading
                            ? null
                            : () => context.pushReplacement(AppRoutes.register),
                        child: Text(
                          context.t(vi: 'Đăng ký', en: 'Sign up'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSoftMessage(BuildContext context, String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _localizedAuthMessage(BuildContext context, String message) {
    if (!context.isEnglish) {
      return message;
    }

    final trimmed = message.trim();
    switch (trimmed) {
      case 'Đang khởi tạo phiên làm việc...':
        return 'Initializing your session...';
      case 'Mình đang đăng nhập nhẹ nhàng...':
        return 'Signing you in...';
      case 'Đang tạo tài khoản cho bạn...':
        return 'Creating your account...';
      case 'Mình đang lưu lại phiên học của bạn...':
        return 'Saving your learning session...';
      case 'Hmm, email này chưa đúng lắm, bạn thử lại nhé 🌿':
        return 'This email looks invalid. Please try again 🌿';
      case 'Mật khẩu cần ít nhất 6 ký tự để an toàn hơn nhé 🌱':
        return 'Password must have at least 6 characters for better security 🌱';
      case 'Bạn cần xác nhận email trước khi đăng nhập nhé ✨':
        return 'Please verify your email before signing in ✨';
      case 'Kết nối hơi chậm một chút, mình thử lại ngay nhé 🌿':
        return 'The connection is a bit slow. Please try again 🌿';
      case 'Bạn thêm tên để mình xưng hô dễ hơn nha 🌿':
        return 'Please add your name so we can address you properly 🌿';
      case 'Hai mật khẩu chưa trùng nhau, mình nhập lại một chút nhé ✨':
        return 'Password confirmation does not match. Please check again ✨';
      case 'Tài khoản đã được tạo. Bạn kiểm tra email để xác nhận rồi đăng nhập nhé ✨':
        return 'Your account was created. Please verify your email, then sign in ✨';
      case 'Mình chưa tạo được tài khoản lúc này, thử lại giúp mình nhé 🌱':
        return 'Unable to create your account right now. Please try again 🌱';
      case 'Kết nối hơi chậm, mình thử lại một chút nhé 🌿':
        return 'The connection is a bit slow. Please try again 🌿';
      case 'Mình chưa đăng xuất được, bạn thử lại giúp mình nhé 🌿':
        return 'Unable to sign out right now. Please try again 🌿';
      default:
        if (_containsVietnameseChars(trimmed)) {
          return 'Something went wrong. Please try again.';
        }
        return trimmed;
    }
  }

  bool _containsVietnameseChars(String value) {
    return RegExp(
      r'[ĂÂĐÊÔƠƯăâđêôơưÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]',
    ).hasMatch(value);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    String? error,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onToggleVisibility,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZenTextField(
          controller: controller,
          hintText: hintText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onSubmitted: onSubmitted,
          suffixIcon: onToggleVisibility != null
              ? IconButton(
                  onPressed: enabled ? onToggleVisibility : null,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
