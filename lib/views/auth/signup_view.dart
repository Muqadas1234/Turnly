import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Get.find<AuthViewModel>().signup(
        name: _nameC.text.trim(),
        email: _emailC.text.trim(),
        password: _passwordC.text,
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
                IconButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.roleSelection),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                  'Sign up as ${authVm.selectedRole.value == 'manager' ? 'Hospital Manager' : 'Patient'}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                )),
                const SizedBox(height: 32),

                // reusable custom text fields
                CustomTextField(
                  controller: _nameC,
                  label: 'Full name',
                  hint: 'Ali Raza',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _emailC,
                  label: 'Email',
                  hint: 'ali.raza@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: _passwordC,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_agreedToTerms) _submit();
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'At least 6 characters',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 18),

                // privacy terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I have read the privacy note: we store only my name, age and tokens.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // reusable custom button
                Obx(() => CustomButton(
                  label: 'Create account',
                  isLoading: authVm.isLoading.value,
                  onPressed: _agreedToTerms ? _submit : null,
                )),
                const SizedBox(height: 24),

                // reusable custom text link button
                CustomTextButton(
                  leadText: 'Already have an account? ',
                  actionText: 'Log in',
                  onTap: () => Get.offNamed(AppRoutes.login),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
