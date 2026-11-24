import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../utils/app_assets.dart';
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
                // Top Bar with circular back button and title
                Row(
                  children: [
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
                        onPressed: () => Get.offAllNamed(AppRoutes.roleSelection),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Role Pill Badge
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreenWhistish,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        authVm.selectedRole.value == 'manager'
                            ? AppAssets.hospitalManagerIcon
                            : AppAssets.userIcon,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        authVm.selectedRole.value == 'manager' ? 'Hospital Manager' : 'Patient',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),

                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log in to book tokens and track your queue position live.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // reusable custom text fields
                CustomTextField(
                  controller: _emailC,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
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
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
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
                    onTap: () {
                      Get.toNamed(AppRoutes.forgotPassword);
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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
