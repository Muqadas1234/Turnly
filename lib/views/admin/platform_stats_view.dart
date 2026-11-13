import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';

class PlatformStatsView extends StatelessWidget {
  const PlatformStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<AdminViewModel>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await vm.fetchStats();
          await vm.fetchApprovedHospitals();
        },
        color: const Color(0xFF0D6E6E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Platform stats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6E6E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2x2 Metrics Cards Grid
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.local_hospital_outlined,
                          iconColor: const Color(0xFF0D6E6E),
                          iconBg: const Color(0xFFE0F2F1),
                          badgeText: '+3',
                          badgeColor: const Color(0xFFD1FAE5),
                          badgeTextColor: const Color(0xFF059669),
                          value: '24',
                          label: 'Total hospitals',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.show_chart,
                          iconColor: const Color(0xFF2563EB),
                          iconBg: const Color(0xFFDBEAFE),
                          value: '17',
                          label: 'Active queues',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.confirmation_number_outlined,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF3C7),
                          badgeText: '+12%',
                          badgeColor: const Color(0xFFD1FAE5),
                          badgeTextColor: const Color(0xFF059669),
                          value: '1,248',
                          label: 'Tokens today',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: const Color(0xFFEDE9FE),
                          value: '9.4k',
                          label: 'Patients',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Tokens issued per hospital (Visual Mockup Chart)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tokens issued per hospital',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHospitalProgressBar('City General', 420, 500, const Color(0xFF0D6E6E)),
                    const SizedBox(height: 12),
                    _buildHospitalProgressBar('Aga Khan', 360, 500, const Color(0xFF2563EB)),
                    const SizedBox(height: 12),
                    _buildHospitalProgressBar('Liaquat Nat.', 250, 500, const Color(0xFF7C3AED)),
                    const SizedBox(height: 12),
                    _buildHospitalProgressBar('Shifa Care', 140, 500, const Color(0xFFEA580C)),
                    const SizedBox(height: 12),
                    _buildHospitalProgressBar('Noor Medical', 78, 500, const Color(0xFF60A5FA)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Manage hospitals Header with "See all"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage hospitals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Switch to the 'Hospitals' tab (index 2)
                      vm.selectedTab.value = 2;
                      vm.fetchApprovedHospitals();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D6E6E),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Manage hospital tiles from live database (vm.approvedHospitals)
              Obx(() {
                final approvedList = vm.approvedHospitals;

                if (approvedList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No active approved hospitals found',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  );
                }

                // Show the approved hospitals from live database
                final hospital = approvedList.first;
                final hospitalId = hospital['id'] as int? ?? 0;
                final name = hospital['name'] ?? 'Hospital';

                final words = name.trim().split(RegExp(r'\s+'));
                final initials = words.length >= 2
                    ? '${words[0][0]}${words[1][0]}'.toUpperCase()
                    : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _confirmSuspend(context, vm, hospitalId, name),
                        icon: const Icon(Icons.block, size: 14, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Suspend',
                          style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Confirmation dialog before suspending a hospital
  void _confirmSuspend(BuildContext context, AdminViewModel vm, int hospitalId, String hospitalName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Suspend Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to suspend $hospitalName? Patients will no longer be able to book tokens.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await vm.suspendHospital(hospitalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Metric card widget
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Progress bar for tokens issued per hospital
  Widget _buildHospitalProgressBar(String name, int tokens, int maxTokens, Color barColor) {
    final ratio = (tokens / (maxTokens == 0 ? 1 : maxTokens)).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$tokens',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
