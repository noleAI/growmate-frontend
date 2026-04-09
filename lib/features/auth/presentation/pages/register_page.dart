import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/zen_button.dart';
import '../../../../shared/widgets/zen_card.dart';
import '../../../../shared/widgets/zen_page_container.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
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
      backgroundColor: GrowMateColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showSoftMessage(context, state.message);
          }

          if (state is AuthAuthenticated) {
            _showSoftMessage(
              context,
              'Tài khoản đã sẵn sàng, cùng bắt đầu nhé ${state.session.displayName} 🌱',
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: GrowMateColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo tài khoản mới',
                  style: theme.textTheme.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bắt đầu hành trình học tập nhẹ nhàng',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: GrowMateColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ZenCard(
                  radius: 30,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ZenTextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        hintText: 'Tên của bạn',
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12),
                      ZenTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        hintText: 'Email',
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 12),
                      ZenTextField(
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        hintText: 'Mật khẩu',
                        obscureText: _obscurePassword,
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: GrowMateColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ZenTextField(
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        hintText: 'Xác nhận mật khẩu',
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading,
                        onSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: GrowMateColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ZenButton(
                        label: isLoading
                            ? 'Đang tạo tài khoản...'
                            : 'Tạo tài khoản',
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
                        'Đã có tài khoản?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: GrowMateColors.textSecondary,
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
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: GrowMateColors.primary,
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
          backgroundColor: GrowMateColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
