import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _codeC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();

  late String _email;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _email = Get.arguments?['email'] ?? '';
    if (_email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Email Required',
          'Please enter your email to request a reset code first.',
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade800,
        );
        Get.offNamed(AppRoutes.forgotPassword);
      });
    }
  }

  @override
  void dispose() {
    _codeC.dispose();
    _passwordC.dispose();
    _confirmPasswordC.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.isEmpty) {
      Get.snackbar(
        'Email Required',
        'Please start from the forgot password screen.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
      Get.offNamed(AppRoutes.forgotPassword);
      return;
    }

    if (_formKey.currentState!.validate()) {
      Get.find<AuthViewModel>().resetPassword(
        email: _email,
        otpCode: _codeC.text.trim(),
        newPassword: _passwordC.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = Get.find<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
                    onPressed: () => Get.back(),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Set New Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to $_email and choose your new password.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),

                // 6-digit code field
                CustomTextField(
                  label: 'Verification Code',
                  hint: '6-digit code',
                  controller: _codeC,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter the 6-digit code';
                    if (val.trim().length != 6) return 'Code must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New password
                CustomTextField(
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  controller: _passwordC,
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter new password';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordC,
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (val) {
                    if (val != _passwordC.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Obx(() => CustomButton(
                  label: 'Reset Password',
                  isLoading: authVm.isLoading.value,
                  onPressed: _submit,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
