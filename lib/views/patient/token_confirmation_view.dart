import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/patient_viewmodel.dart';

class TokenConfirmationView extends StatefulWidget {
  const TokenConfirmationView({super.key});

  @override
  State<TokenConfirmationView> createState() => _TokenConfirmationViewState();
}

class _TokenConfirmationViewState extends State<TokenConfirmationView> {
  late final PatientViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = Get.find<PatientViewModel>();
    vm.fetchActiveToken();
  }

  String _firstValue(Map<String, dynamic> token, List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final value = token[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Booking confirmed'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Obx(() {
        final token = vm.activeToken.value;
        if (vm.isLoadingTokens.value && token == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (token == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'Your booking request was sent, but the active token details could not be loaded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: vm.fetchActiveToken, child: const Text('Try again')),
                ],
              ),
            ),
          );
        }

        final tokenNumber = _firstValue(token, ['token_number', 'tokenNumber', 'number']);
        final doctor = _firstValue(token, ['doctor_name', 'doctorName'], fallback: 'Assigned doctor');
        final hospital = _firstValue(token, ['hospital_name', 'hospitalName'], fallback: 'Selected hospital');
        final date = _firstValue(token, ['booking_date', 'date', 'appointment_date']);
        final status = _firstValue(token, ['status'], fallback: 'Booked');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your token is booked!',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep this token number and check your queue before leaving.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('TOKEN NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('#$tokenNumber', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.adminPrimary)),
                    const Divider(height: 28),
                    _detailRow('Doctor', doctor),
                    _detailRow('Hospital', hospital),
                    _detailRow('Date', date),
                    _detailRow('Status', status),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.myTokens),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('View my tokens'),
                ),
              ),
              TextButton(
                onPressed: () => Get.offAllNamed(AppRoutes.home),
                child: const Text('Back to home'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 82, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
            Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          ],
        ),
      );
}
