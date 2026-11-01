import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/app_logo.dart';
import '../widgets/labeled_text_field.dart';

/// Frame 6: Sign up.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUpPressed() async {
    final vm = context.read<AuthViewModel>();
    if (vm.isLoading) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await vm.signUp(
      name: _nameController.text,
      surname: _surnameController.text,
      studentNumber: _studentNumberController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || result == null) return; // null = error shown on screen

    if (result == SignUpResult.loggedIn) {
      // Clear Login and Sign up from history, so Back can't return here
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (route) => false);
    } else {
      await _showCheckEmailDialog();
      if (mounted) Navigator.pop(context); // back to Login
    }
  }

  Future<void> _showCheckEmailDialog() {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check your email'),
        content: Text(
          'We sent a confirmation link to ${_emailController.text.trim()}. '
          'Open it, then come back and log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(height: 110),
                    const SizedBox(height: 32),

                    LabeledTextField(
                      label: 'Name',
                      controller: _nameController,
                      validator: (v) => Validators.required(v, 'Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      onChanged: (_) => vm.clearError(),
                    ),
                    const SizedBox(height: 16),

                    LabeledTextField(
                      label: 'Surname',
                      controller: _surnameController,
                      validator: (v) => Validators.required(v, 'Surname'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                      onChanged: (_) => vm.clearError(),
                    ),
                    const SizedBox(height: 16),

                                      LabeledTextField(
                      label: 'Student number',
                      controller: _studentNumberController,
                      validator: Validators.studentNumber,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => vm.clearError(),
                    ),
                    const SizedBox(height: 16),

                    LabeledTextField(
                      label: 'Email',
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onChanged: (_) => vm.clearError(),
                    ),
                    const SizedBox(height: 16),

                    LabeledTextField(
                      label: 'Password',
                      controller: _passwordController,
                      validator: Validators.password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => vm.clearError(),
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),

                    Center(
                      child: SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          onPressed: _onSignUpPressed,
                          child: vm.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Sign up'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
