import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/manager_viewmodel.dart';

class ManagerDashboardView extends StatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  State<ManagerDashboardView> createState() => _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends State<ManagerDashboardView> {
  ManagerViewModel get vm => Get.find<ManagerViewModel>();

  @override
  void initState() {
    super.initState();
    vm.loadMyHospital(routeByStatus: false);
    vm.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hospital Manager',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (vm.isLoading.value && vm.currentHospital.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.tealPrimary),
          );
        }

        final hospital = vm.currentHospital.value;
        final status = hospital?.status ?? 'pending';
        final isPending = status == 'pending';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital?.name ?? 'Your Hospital',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospital?.city.isNotEmpty == true
                                ? '${hospital!.city} · ${hospital.opdTimings}'
                                : 'OPD Management',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.suspendedBg : AppColors.tealLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPending ? 'Pending' : 'Approved',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isPending ? AppColors.suspendedText : AppColors.tealPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Today at a glance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.15,
                children: [
                  _metricTile('Tokens today', vm.tokensToday.value.toString(), Icons.confirmation_number_outlined),
                  _metricTile('In queue', vm.inQueueNow.value.toString(), Icons.groups_outlined),
                  _metricTile('Patients served', vm.patientsServed.value.toString(), Icons.check_circle_outline),
                  _metricTile('Avg. consult.', '${vm.avgConsultationMins.value} min', Icons.timer_outlined),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: vm.fetchDashboard,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh stats'),
                ),
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.layers_outlined,
                title: 'Departments',
                subtitle: 'Manage hospital departments & daily token limits',
                onTap: () => Get.toNamed(AppRoutes.manageDepartments),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.assignment_outlined,
                title: 'Queue Control',
                subtitle: 'Call next token & manage live patient queues',
                onTap: () => Get.toNamed(AppRoutes.queueControl),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.medical_services_outlined,
                title: 'Doctors',
                subtitle: 'Add & manage doctors across departments',
                onTap: () => Get.toNamed(AppRoutes.doctorManagement),
              ),
            ],
            ),
          ),
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.tealPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        onTap: (index) {
          if (index == 1) Get.toNamed(AppRoutes.queueControl);
          if (index == 2) Get.toNamed(AppRoutes.doctorManagement);
          if (index == 3) Get.toNamed(AppRoutes.profile);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Doctors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.tealPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.tealPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
