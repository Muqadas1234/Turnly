import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Get.find<AuthViewModel>().login(
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
                const SizedBox(height: 32),
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back! Log in to see your tokens.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // reusable custom text fields
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
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _passwordC,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // reusable custom button
                Obx(() => CustomButton(
                  label: 'Log in',
                  isLoading: authVm.isLoading.value,
                  onPressed: _submit,
                )),
                const SizedBox(height: 24),

                // reusable custom text link button
                CustomTextButton(
                  leadText: 'New here? ',
                  actionText: 'Create account',
                  onTap: () => Get.offNamed(AppRoutes.signup),
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
