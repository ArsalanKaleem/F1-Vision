import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_providers.dart';
import 'widgets/auth_widgets.dart';

/// E-mail registration (name, e-mail, password + confirmation) plus Google
/// sign-up. On success the router redirect takes the user straight in.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final submit = ref.watch(authControllerProvider);
    final busy = submit.isLoading;
    final error = submit.hasError ? '${submit.error}' : null;

    return AuthScaffold(
      title: 'Create your account',
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
              controller: _name,
              label: 'Name',
              hint: 'Lewis Hamilton',
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
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
              hint: 'At least 6 characters',
              obscure: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm password',
              hint: 'Repeat your password',
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  v != _password.text ? 'Passwords don’t match' : null,
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
                label: 'Create account', busy: busy, onPressed: _submit),
            const SizedBox(height: 18),
            const OrDivider(),
            const SizedBox(height: 18),
            GoogleButton(
              busy: busy,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signInWithGoogle(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?', style: AppTextStyles.body),
                TextButton(
                  onPressed: busy ? null : () => context.go('/login'),
                  child: Text('Sign in',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.accentSoft)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
