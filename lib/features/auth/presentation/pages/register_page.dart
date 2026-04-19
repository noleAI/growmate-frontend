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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  bool _validateForm() {
    _clearErrors();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    if (name.isEmpty) {
      setState(() {
        _nameError = context.t(
          vi: 'Vui lòng nhập tên của bạn',
          en: 'Please enter your name',
        );
      });
      hasError = true;
    }

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
    } else if (password.length < 6) {
      setState(() {
        _passwordError = context.t(
          vi: 'Mật khẩu phải có ít nhất 6 ký tự',
          en: 'Password must have at least 6 characters',
        );
      });
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _confirmPasswordError = context.t(
          vi: 'Vui lòng xác nhận mật khẩu',
          en: 'Please confirm your password',
        );
      });
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = context.t(
          vi: 'Mật khẩu xác nhận không khớp',
          en: 'Password confirmation does not match',
        );
      });
      hasError = true;
    }

    return !hasError;
  }

  void _submit() {
    if (!_validateForm()) return;

    context.read<AuthBloc>().add(
      RegisterRequested(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
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
                vi: 'Tài khoản đã sẵn sàng, cùng bắt đầu nhé ${state.session.displayName} 🌱',
                en: 'Your account is ready. Let\'s get started, ${state.session.displayName} 🌱',
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
                    vi: 'Khởi tạo hành trình',
                    en: 'Start your journey',
                  ),
                  title: context.t(
                    vi: 'Tạo tài khoản mới',
                    en: 'Create a new account',
                  ),
                  subtitle: context.t(
                    vi: 'Thiết lập tài khoản để GrowMate cá nhân hóa nhịp học, mục tiêu và lộ trình ôn tập cho bạn.',
                    en: 'Set up your account so GrowMate can personalize your pace, goals, and study roadmap.',
                  ),
                  icon: Icons.person_add_alt_1_rounded,
                  chips: [
                    ZenHeaderChipData(
                      label: context.t(
                        vi: 'AI cá nhân hóa',
                        en: 'AI personalization',
                      ),
                      icon: Icons.auto_awesome_rounded,
                    ),
                    ZenHeaderChipData(
                      label: context.t(
                        vi: 'Lộ trình theo mục tiêu',
                        en: 'Goal-based roadmap',
                      ),
                      icon: Icons.flag_rounded,
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
                        controller: _nameController,
                        hintText: context.t(vi: 'Tên của bạn', en: 'Your name'),
                        enabled: !isLoading,
                        error: _nameError,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        hintText: context.t(vi: 'Email', en: 'Email'),
                        enabled: !isLoading,
                        error: _emailError,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        controller: _passwordController,
                        hintText: context.t(vi: 'Mật khẩu', en: 'Password'),
                        enabled: !isLoading,
                        error: _passwordError,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: context.t(
                          vi: 'Xác nhận mật khẩu',
                          en: 'Confirm password',
                        ),
                        enabled: !isLoading,
                        error: _confirmPasswordError,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      ZenButton(
                        label: isLoading
                            ? context.t(
                                vi: 'Đang tạo tài khoản...',
                                en: 'Creating account...',
                              )
                            : context.t(
                                vi: 'Tạo tài khoản',
                                en: 'Create account',
                              ),
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
                          vi: 'Đã có tài khoản?',
                          en: 'Already have an account?',
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
                            : () => context.pushReplacement(AppRoutes.login),
                        child: Text(
                          context.t(vi: 'Đăng nhập', en: 'Log in'),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? error,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZenTextField(
          controller: controller,
          hintText: hintText,
          enabled: enabled,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          suffixIcon: IconButton(
            onPressed: enabled ? onToggleVisibility : null,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
