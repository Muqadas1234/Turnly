import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'platform_stats_view.dart';
import 'review_registration_view.dart';

class AdminPanelView extends StatelessWidget {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<AdminViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        switch (vm.selectedTab.value) {
          case 0:
            return _buildApprovalsTab(context, vm);
          case 1:
            return const PlatformStatsView();
          case 2:
            return _buildHospitalsTab(context, vm);
          case 3:
            return _buildProfileTab(context);
          default:
            return _buildApprovalsTab(context, vm);
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: vm.selectedTab.value,
        onTap: (index) {
          vm.selectedTab.value = index;
          if (index == 0) vm.fetchHospitals();
          if (index == 1) vm.fetchStats();
          if (index == 2) vm.fetchApprovedHospitals();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0D6E6E),
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital),
            label: 'Hospitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }

  // Tab 0: Approvals screen
  Widget _buildApprovalsTab(BuildContext context, AdminViewModel vm) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => vm.fetchHospitals(),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Admin panel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Review hospital registrations',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter chips row (Pending, Approved, Suspended)
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          title: 'Pending',
                          count: vm.pendingCount.value,
                          filterKey: 'pending',
                          isSelected: vm.selectedFilter.value == 'pending',
                          onTap: () => vm.setFilter('pending'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          title: 'Approved',
                          count: vm.approvedCount.value,
                          filterKey: 'approved',
                          isSelected: vm.selectedFilter.value == 'approved',
                          onTap: () => vm.setFilter('approved'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          title: 'Suspended',
                          count: vm.suspendedCount.value,
                          filterKey: 'suspended',
                          isSelected: vm.selectedFilter.value == 'suspended',
                          onTap: () => vm.setFilter('suspended'),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),

              // Hospital cards list
              Obx(() {
                if (vm.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0D6E6E)),
                    ),
                  );
                }

                if (vm.hospitals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'No ${vm.selectedFilter.value} hospitals found',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.hospitals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final hospital = vm.hospitals[index];
                    return _buildHospitalCard(context, hospital, vm);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Filter chip widget
  Widget _buildFilterChip({
    required String title,
    required int count,
    required String filterKey,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6E6E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6E6E) : AppColors.border,
          ),
        ),
        child: Text(
          '$title · $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // Individual hospital card
  Widget _buildHospitalCard(
      BuildContext context,
      Map<String, dynamic> hospital,
      AdminViewModel vm,
      ) {
    final name = hospital['name'] ?? 'Hospital';
    final city = hospital['city'] ?? '';
    final managerName = hospital['manager_name'] ?? 'Not assigned';
    final status = (hospital['status'] ?? 'pending').toString().toLowerCase();
    final hospitalId = hospital['id'] as int? ?? 0;

    // Generate initials (e.g., 'City General Hospital' -> 'CG')
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return GestureDetector(
      onTap: () {
        Get.to(() => ReviewRegistrationView(hospital: hospital));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar, Name/City, and Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00695C),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // Manager info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Manager: $managerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Submitted time
            Row(
              children: const [
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Recently submitted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons row (Reject / Approve)
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => vm.rejectHospital(hospitalId),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFDE8E8),
                          foregroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => vm.approveHospital(hospitalId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6E6E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '✓  Approve',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (status == 'approved')
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => vm.suspendHospital(hospitalId),
                  icon: const Icon(Icons.block, size: 16, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Suspend hospital',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Status pill widget
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'approved':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF059669);
        label = 'Approved';
        break;
      case 'suspended':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'Suspended';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  // Tab 2: Manage Hospitals tab
  Widget _buildHospitalsTab(BuildContext context, AdminViewModel vm) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Hospitals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final approvedList = vm.approvedHospitals;

                if (approvedList.isEmpty) {
                  return const Center(child: Text('No approved hospitals yet'));
                }

                return ListView.separated(
                  itemCount: approvedList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final h = approvedList[index];
                    return _buildHospitalCard(context, h, vm);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 3: Admin Profile tab
  Widget _buildProfileTab(BuildContext context) {
    final authVm = Get.find<AuthViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF0D6E6E),
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'System Administrator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

              Text(
                authVm.currentUser.value?['email'] ?? 'team.turnly@gmail.com',
                style: const TextStyle(color: AppColors.textSecondary),
              ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => authVm.logout(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

