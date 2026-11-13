import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/app_icon.dart';

class ReviewRegistrationView extends StatefulWidget {
  final Map<String, dynamic> hospital;

  const ReviewRegistrationView({super.key, required this.hospital});

  @override
  State<ReviewRegistrationView> createState() => _ReviewRegistrationViewState();
}

class _ReviewRegistrationViewState extends State<ReviewRegistrationView> {
  final TextEditingController _rejectionController = TextEditingController();
  final AdminViewModel _adminVm = Get.find<AdminViewModel>();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    final name = h['name'] ?? 'Hospital';
    final city = h['city'] ?? '';
    final address = h['address'] ?? 'Not specified';
    final phone = h['phone'] ?? 'Not specified';
    final type = h['type'] ?? 'Private hospital';
    final opdTimings = h['opd_timings'] ?? '9:00 AM - 8:00 PM';
    final managerName = h['manager_name'] ?? 'Not assigned';
    final managerEmail = h['manager_email'] ?? '';
    final hospitalId = h['id'] as int? ?? 0;
    final status = (h['status'] ?? 'pending').toString().toLowerCase();

    // Generate initials (e.g., 'City General Hospital' -> 'CG')
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const AppIcon('arrow_left', size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Review registration',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with avatar, name, and pending badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.adminPrimaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.adminPrimaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.adminPendingBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Pending review',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.adminPendingText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hospital specifications table card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Type', type),
                  _buildDivider(),
                  _buildDetailRow('City', city),
                  _buildDivider(),
                  _buildDetailRow('Address', address),
                  _buildDivider(),
                  _buildDetailRow('Phone', phone),
                  _buildDivider(),
                  _buildDetailRow('OPD timings', opdTimings),
                  _buildDivider(),
                  _buildDetailRow(
                    'Manager',
                    managerEmail.isNotEmpty ? '$managerName · $managerEmail' : managerName,
                  ),
                  _buildDivider(),
                  _buildDetailRow('Submitted', 'Recently submitted'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Optional rejection note input field
            if (status == 'pending') ...[
              const Text(
                'Rejection note (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rejectionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a reason if rejecting...',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await _adminVm.approveHospital(hospitalId);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Approve hospital',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () async {
                    await _adminVm.rejectHospital(
                      hospitalId,
                      reason: _rejectionController.text.trim(),
                    );
                    Get.back();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.adminRejectText,
                  ),
                  child: const Text(
                    'Reject registration',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }
}
