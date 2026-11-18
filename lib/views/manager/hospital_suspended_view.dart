import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/manager_viewmodel.dart';

// M11: Hospital Suspended Screen
class HospitalSuspendedView extends StatelessWidget {
  const HospitalSuspendedView({super.key});

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

            return Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.suspendedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: AppColors.suspendedText,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.suspendedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Status: Suspended',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.suspendedText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hospital suspended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The Turnly admin team has temporarily suspended $hospitalName. Contact support to resolve this.',
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
                    color: AppColors.suspendedBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.suspendedBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What this means',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.suspendedText,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your hospital is hidden from patients and queues are paused. Existing tokens are kept so patients are not lost.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.suspendedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.snackbar(
                        'Turnly Support',
                        'Contact support at support@turnly.pk',
                        backgroundColor: AppColors.infoBg,
                        colorText: AppColors.infoText,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: authVm.logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log out',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
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
