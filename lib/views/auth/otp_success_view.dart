import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/routes.dart';
import '../../widgets/custom_button.dart';

class OtpSuccessView extends StatefulWidget {
  const OtpSuccessView({super.key});

  @override
  State<OtpSuccessView> createState() => _OtpSuccessViewState();
}

class _OtpSuccessViewState extends State<OtpSuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  String _userName = '';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final data = await ApiService.getUserData();
    if (data != null && mounted) {
      setState(() => _userName = data['name'] ?? '');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account verified!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _userName.isNotEmpty
                    ? 'Great, $_userName! Your account is verified.\nPlease log in to access your dashboard.'
                    : 'Your account is verified!\nPlease log in to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),

              // reusable custom button
              CustomButton(
                label: 'Go to Log in',
                onPressed: () => Get.offAllNamed(AppRoutes.login),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
