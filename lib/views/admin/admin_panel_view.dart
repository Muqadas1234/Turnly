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
      backgroundColor: AppColors.background,
      body: Obx(() {
        switch (vm.selectedTab.value) {
          case 0:
            return _buildApprovalsTab(context, vm);
          case 1:
            return const PlatformStatsView();
          case 2:
            return _buildUsersTab(context, vm);
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
          if (index == 2) vm.fetchUsers();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.adminPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        backgroundColor: AppColors.surface,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined, size: 22),
            activeIcon: Icon(Icons.verified_user, size: 22),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined, size: 22),
            activeIcon: Icon(Icons.bar_chart, size: 22),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, size: 22),
            activeIcon: Icon(Icons.people, size: 22),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 22),
            activeIcon: Icon(Icons.person, size: 22),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin panel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter chips row (Pending, Approved, Rejected, Suspended)
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
                      title: 'Rejected',
                      count: vm.rejectedCount.value,
                      filterKey: 'rejected',
                      isSelected: vm.selectedFilter.value == 'rejected',
                      onTap: () => vm.setFilter('rejected'),
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
                      child: CircularProgressIndicator(color: AppColors.adminPrimary),
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
          color: isSelected ? AppColors.adminPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.adminPrimary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "2 hours ago" style label for the Submitted line
  String _timeAgo(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString());
    if (d == null) return 'recently';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }

  // Asks the admin for an optional reason, then rejects the registration
  Future<void> _showRejectDialog(AdminViewModel vm, int id, String name) async {
    final controller = TextEditingController();
    final reason = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject $name?',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason shown to the manager (optional)',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true,
            fillColor: AppColors.background,
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
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.adminRejectText),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return; // admin cancelled
    await vm.rejectHospital(id, reason: reason);
  }

  // Delete hospital confirmation dialog
  Future<void> _showDeleteDialog(AdminViewModel vm, int id, String name) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$name"? This will remove all associated departments, doctors, and queues from the database. This action cannot be undone.',
          style: const TextStyle(height: 1.4, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vm.deleteHospital(id);
    }
  }

  // Hospital card for Approvals tab
  Widget _buildHospitalCard(
      BuildContext context,
      Map<String, dynamic> hospital,
      AdminViewModel vm,
      ) {
    final status = (hospital['status'] ?? 'pending').toString().toLowerCase();
    final hospitalId = hospital['id'] as int? ?? 0;
    final name = (hospital['name'] ?? 'Unnamed Hospital').toString();
    final city = (hospital['city'] ?? '').toString();
    final managerName = (hospital['manager_name'] ?? '').toString();

    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.adminPrimaryLight,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminPrimaryDark,
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
                    if (city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (managerName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Manager: $managerName',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Submitted ${_timeAgo(hospital['created_at'])}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.to(() => ReviewRegistrationView(hospital: hospital));
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Review details & documents'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adminPrimary,
                side: const BorderSide(color: AppColors.adminPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Action buttons based on status
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(vm, hospitalId, name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminRejectBg,
                      foregroundColor: AppColors.adminRejectText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => vm.approveHospital(hospitalId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'rejected') ...[
            const SizedBox(height: 10),
            if ((hospital['rejection_note'] ?? '').toString().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Reason: ${hospital['rejection_note']}',
                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade900),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => vm.approveHospital(hospitalId),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Approve hospital',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else if (status == 'suspended') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => vm.approveHospital(hospitalId),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'Reactivate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(vm, hospitalId, name),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => vm.suspendHospital(hospitalId),
                icon: Icon(Icons.block, size: 18, color: Colors.red.shade700),
                label: Text(
                  'Suspend hospital',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'suspended':
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.capitalizeFirst ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Tab 2: Registered Platform Users screen
  Widget _buildUsersTab(BuildContext context, AdminViewModel vm) {
    final searchController = TextEditingController(text: vm.userSearchText.value);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => vm.fetchUsers(),
        color: AppColors.adminPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage registered managers and patients',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            vm.searchUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                onSubmitted: (val) => vm.searchUsers(val),
                onChanged: (val) {
                  if (val.isEmpty) vm.searchUsers('');
                },
              ),
              const SizedBox(height: 12),

              // Role Filter Chips (All, Managers, Patients)
              Obx(() => Row(
                children: [
                  _buildUserRoleChip(vm, 'all', 'All Users'),
                  const SizedBox(width: 8),
                  _buildUserRoleChip(vm, 'manager', 'Managers'),
                  const SizedBox(width: 8),
                  _buildUserRoleChip(vm, 'patient', 'Patients'),
                ],
              )),
              const SizedBox(height: 16),

              // Users List
              Obx(() {
                if (vm.isUsersLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.adminPrimary),
                    ),
                  );
                }

                if (vm.users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = vm.users[index];
                    final name = (user['name'] ?? 'User').toString();
                    final email = (user['email'] ?? '').toString();
                    final phone = (user['phone'] ?? '').toString();
                    final role = (user['role'] ?? 'patient').toString().toLowerCase();
                    final hospitalName = (user['hospital_name'] ?? '').toString();
                    final hospitalStatus = (user['hospital_status'] ?? '').toString().toLowerCase();

                    final isManager = role == 'manager';
                    final roleColor = isManager ? AppColors.tealPrimary : Colors.blue.shade700;
                    final roleBg = isManager ? AppColors.tealLight : Colors.blue.shade50;

                    final words = name.trim().split(RegExp(r'\s+'));
                    final initials = words.length >= 2
                        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
                        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: roleBg,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: roleBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role.capitalizeFirst ?? role,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: roleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 5),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                                if (isManager && hospitalName.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.tealPrimary),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          hospitalName,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hospitalStatus.isNotEmpty)
                                        _buildStatusBadge(hospitalStatus),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserRoleChip(AdminViewModel vm, String roleKey, String label) {
    return Obx(() {
      final isSelected = vm.userRoleFilter.value == roleKey;
      return GestureDetector(
        onTap: () => vm.setUserRoleFilter(roleKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.adminPrimary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.adminPrimary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    });
  }

  // Tab 3: Admin Profile screen
  Widget _buildProfileTab(BuildContext context) {
    final authVm = Get.find<AuthViewModel>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.adminPrimary.withOpacity(0.1),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 28,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Administrator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Platform Management',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => authVm.logout(),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}