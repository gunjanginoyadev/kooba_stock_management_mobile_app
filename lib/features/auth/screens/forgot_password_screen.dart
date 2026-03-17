import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_auth_shell.dart';
import '../../../core/widgets/app_logo_header.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/toast_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ResetPasswordEvent(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AppAuthState>(
      listener: (context, state) {
        if (state is PasswordResetSent) {
          ToastHelper.success(context, 'Password reset email sent.');
          context.go(AppConstants.loginRoute);
        } else if (state is AuthError) {
          ToastHelper.error(context, state.message);
        }
      },
      child: AppAuthShell(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogoHeader(
                title: 'Reset Password',
                subtitle:
                    'Enter the email associated with your account to reset your password.',
              ),
              const SizedBox(height: 32),

              AppTextField(
                controller: _emailController,
                label: 'Work Email',
                hintText: 'work-email@company.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppTheme.textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              BlocBuilder<AuthBloc, AppAuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return AppPrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: isLoading,
                    onPressed: _handleReset,
                  );
                },
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton.icon(
                  onPressed: () => context.go(AppConstants.loginRoute),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  label: const Text(
                    'Back to Log In',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

