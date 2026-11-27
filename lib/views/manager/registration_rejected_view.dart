import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/manager_viewmodel.dart';

// M9: Registration Rejected Screen
class RegistrationRejectedView extends StatelessWidget {
  const RegistrationRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<ManagerViewModel>();
    final authVm = Get.find<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Obx(() {
            final hospital = vm.currentHospital.value;
            final hospitalName = (hospital != null && hospital.name.isNotEmpty)
                ? hospital.name
                : 'City General Hospital';
            final reason = (hospital != null && hospital.rejectionReason.isNotEmpty)
                ? hospital.rejectionReason
                : 'The hospital license document is unclear. Please upload a clear, full-page copy of your license and resubmit.';

            return Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.rejectedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.rejectedText,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.rejectedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Status: Rejected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rejectedText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Registration not approved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "We couldn't approve $hospitalName yet. Fix the issue below and resubmit — it only takes a minute.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MESSAGE FROM ADMIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (hospital != null) {
                        vm.prefillFromHospital(hospital);
                      }
                      vm.isResubmitting.value = true;
                      vm.goToStep(1);
                      Get.toNamed(AppRoutes.registrationForm, arguments: {'step': 1});
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 22),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Edit application',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Turnly Support',
                        'Contact support at support@turnly.pk',
                        backgroundColor: AppColors.infoBg,
                        colorText: AppColors.infoText,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Contact support',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: authVm.logout,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
