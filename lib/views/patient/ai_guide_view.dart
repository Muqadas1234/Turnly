import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';

/// Static in-app help. This is not an AI chat because no AI endpoint is
/// configured in the supplied API client.
class AiGuideView extends StatelessWidget {
  const AiGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient guide'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Text(
              'This guide explains the current Turnly patient flow. AI chat is not enabled in this build.',
              style: TextStyle(color: AppColors.infoText, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          _step(1, 'Choose a hospital', 'Browse approved hospitals on the Home tab and open a hospital to view its departments.'),
          _step(2, 'Select a doctor', 'Choose a department, review available doctors and continue to booking.'),
          _step(3, 'Book a token', 'Choose an appointment date. For a family member, first save them under Family Members.'),
          _step(4, 'Track your turn', 'Open My Tokens to view active tokens and token history.'),
          const SizedBox(height: 18),
          _action('Browse hospitals', Icons.local_hospital_outlined, () => Get.offAllNamed(AppRoutes.home)),
          const SizedBox(height: 10),
          _action('My tokens', Icons.confirmation_number_outlined, () => Get.toNamed(AppRoutes.myTokens)),
          const SizedBox(height: 10),
          _action('Family members', Icons.people_outline, () => Get.toNamed(AppRoutes.familyMembers)),
        ],
      ),
    );
  }

  Widget _step(int number, String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.adminPrimaryLight,
              child: Text('$number', style: const TextStyle(color: AppColors.adminPrimary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(height: 1.4, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _action(String label, IconData icon, VoidCallback onTap) => Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.adminPrimary),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
