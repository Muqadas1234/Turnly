import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../widgets/custom_button.dart';
import 'my_token_view.dart';

class TokenConfirmationView extends StatelessWidget {
  const TokenConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),

                  // 1. Big Green Tick Circle (Built-in Icons.check)
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 42,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Title & Subtitle
                  const Text(
                    'Token booked!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your digital token is confirmed. No need to wait\nat the hospital.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Static Token Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Doctor Details Row
                        Row(
                          children: [
                            // Doctor Initials Avatar
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: AppColors.adminPrimaryLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'AR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.adminPrimaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. Ahmed Raza',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Cardiology · City General Hospital',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Built-in Divider
                        const Divider(color: AppColors.border, thickness: 1),
                        const SizedBox(height: 16),

                        // Token Number & Schedule Details Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Token Number
                            const Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOKEN',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '#12',
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.adminPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: Date, Wait Time, Room
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    text: 'Thu, 12 Nov 2026',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    icon: Icons.access_time_outlined,
                                    text: 'Est. wait ~25 min',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    icon: Icons.location_on_outlined,
                                    text: 'Room 4 · Floor 2',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Notification Reminder Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.adminPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 20,
                          color: AppColors.adminPrimaryDark,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "We'll notify you when only 2 patients are ahead.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.adminPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Track My Token Button
                  CustomButton(
                    label: 'Track my token',
                    height: 48,
                    backgroundColor: AppColors.adminPrimary,
                    textColor: AppColors.surface,
                    onPressed: () {
                      Get.to(() => const MyTokenView());
                    },
                  ),
                  const SizedBox(height: 12),

                  // 6. Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.home);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                      child: const Text(
                        'Back to home',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper row for schedule details with icon
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
