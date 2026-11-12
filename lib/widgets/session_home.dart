import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';
import '../utils/routes.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Temporary landing screen so login, signup, and profile can be tested.
class SessionHome extends StatefulWidget {
  const SessionHome({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<SessionHome> createState() => _SessionHomeState();
}

class _SessionHomeState extends State<SessionHome> {
  final _auth = Get.find<AuthViewModel>();

  @override
  void initState() {
    super.initState();
    _auth.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Obx(() {
        final user = _auth.currentUser.value;
        final phone = user?['phone']?.toString();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    user?['name']?.toString() ?? 'Signed in',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_auth.isProfileLoading.value) ...[
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InfoRow(label: 'Email', value: user?['email']?.toString() ?? '—'),
            _InfoRow(label: 'Phone', value: (phone == null || phone.isEmpty) ? '—' : phone),
            _InfoRow(label: 'Role', value: user?['role']?.toString() ?? '—'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.profile),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Edit profile',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Auth is connected. Hospital, queue, and booking screens are still placeholders.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
