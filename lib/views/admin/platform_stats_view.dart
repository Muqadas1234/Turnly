import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/app_icon.dart';

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
        color: AppColors.adminPrimary,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.adminPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2x2 Real Live Database Metrics Grid
              Obx(() {
                final stats = vm.platformStats;
                final totalHospitals = stats['totalHospitals'] ?? vm.approvedCount.value;
                final activeQueues = stats['activeQueues'] ?? 0;
                final tokensToday = stats['tokensToday'] ?? 0;
                final totalPatients = stats['totalPatients'] ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            iconName: 'hospital',
                            iconColor: AppColors.adminPrimary,
                            iconBg: AppColors.adminPrimaryLight,
                            value: '$totalHospitals',
                            label: 'Total hospitals',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMetricCard(
                            iconName: 'activity',
                            iconColor: AppColors.adminBlue,
                            iconBg: AppColors.adminBlueBg,
                            value: '$activeQueues',
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
                            iconName: 'ticket',
                            iconColor: AppColors.adminPendingText,
                            iconBg: AppColors.adminPendingBg,
                            value: '$tokensToday',
                            label: 'Tokens today',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMetricCard(
                            iconName: 'users',
                            iconColor: AppColors.adminPurple,
                            iconBg: AppColors.adminPurpleBg,
                            value: totalPatients >= 1000
                                ? '${(totalPatients / 1000).toStringAsFixed(1)}k'
                                : '$totalPatients',
                            label: 'Patients',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Section: Tokens issued per hospital
              Builder(
                builder: (context) {
                  final rawList = vm.platformStats['tokensPerHospital'];
                  final tokensList = (rawList is List) ? rawList : [];

                  final colors = [
                    AppColors.adminPrimary,
                    AppColors.adminBlue,
                    AppColors.adminPurple,
                    AppColors.adminOrange,
                    AppColors.accent,
                  ];

                  final maxTokens = tokensList.fold<int>(
                    1,
                    (max, item) {
                      final count = int.tryParse(item['token_count']?.toString() ?? '0') ?? 0;
                      return count > max ? count : max;
                    },
                  );

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
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
                        if (tokensList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No token data available yet',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ...tokensList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value as Map;
                            final hospitalName = (item['name'] ?? 'Hospital').toString();
                            final count = int.tryParse(item['token_count']?.toString() ?? '0') ?? 0;
                            final color = colors[idx % colors.length];

                            return Padding(
                              padding: EdgeInsets.only(bottom: idx == tokensList.length - 1 ? 0 : 12),
                              child: _buildHospitalProgressBar(hospitalName, count, maxTokens, color),
                            );
                          }),
                      ],
                    ),
                  );
                },
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
                      foregroundColor: AppColors.adminPrimary,
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
                      color: AppColors.card,
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.adminBlueBg,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.adminBlue,
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
                                color: AppColors.adminApprovedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: AppColors.adminApprovedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _confirmSuspend(context, vm, hospitalId, name),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.adminSuspendedBg,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon('ban', size: 14, color: AppColors.adminSuspendedText),
                            SizedBox(width: 4),
                            Text(
                              'Suspend',
                              style: TextStyle(fontSize: 12, color: AppColors.adminSuspendedText),
                            ),
                          ],
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Suspend', style: TextStyle(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  // Metric card widget
  Widget _buildMetricCard({
    required String iconName,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(iconName, color: iconColor, size: 20),
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
              backgroundColor: AppColors.divider,
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
