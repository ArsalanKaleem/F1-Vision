import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// E-mail + Google sign-in. Successful auth flips `authStateChanges`, which
/// triggers the router redirect back into the app — no manual navigation.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
  }

  Future<void> _google() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Enter your e-mail above first, then tap again.')));
      return;
    }
    final error = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);
    messenger.showSnackBar(SnackBar(
        content: Text(error ?? 'Password-reset e-mail sent to $email.')));
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(authControllerProvider);
    final busy = submit.isLoading;
    final error = submit.hasError ? '${submit.error}' : null;

    return AuthScaffold(
      title: 'Welcome back',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              AuthErrorBanner(message: error),
              const SizedBox(height: 16),
            ],
            AuthTextField(
              controller: _email,
              label: 'E-mail',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid e-mail address'
                  : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'Password',
              hint: '••••••••',
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy ? null : _forgotPassword,
                child: Text('Forgot password?',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(height: 8),
            AuthPrimaryButton(label: 'Sign in', busy: busy, onPressed: _submit),
            const SizedBox(height: 18),
            const OrDivider(),
            const SizedBox(height: 18),
            GoogleButton(busy: busy, onPressed: _google),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('New here?', style: AppTextStyles.body),
                TextButton(
                  onPressed: busy ? null : () => context.go('/register'),
                  child: Text('Create an account',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.accentSoft)),
                ),
              ],
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => ref.read(guestModeProvider.notifier).state = true,
              child: Text('Continue as guest',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }
}
