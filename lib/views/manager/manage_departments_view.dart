import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/department_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/manager_viewmodel.dart';

// M10: Manage Departments Screen
class ManageDepartmentsView extends StatefulWidget {
  const ManageDepartmentsView({super.key});

  @override
  State<ManageDepartmentsView> createState() => _ManageDepartmentsViewState();
}

class _ManageDepartmentsViewState extends State<ManageDepartmentsView> {
  final _searchC = TextEditingController();
  ManagerViewModel get vm => Get.find<ManagerViewModel>();

  @override
  void initState() {
    super.initState();
    vm.loadDepartments();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Departments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchC,
                onChanged: (val) => vm.departmentSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search departments',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.tealPrimary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Department list
            Expanded(
              child: Obx(() {
                final items = vm.filteredDepartments;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No departments found',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _buildDepartmentCard(items[index], index),
                );
              }),
            ),

            // + Add department button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showAddDepartmentSheet,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add department',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.tealPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        onTap: (index) {
          if (index == 0) Get.offNamed(AppRoutes.managerDashboard);
          if (index == 1) Get.offNamed(AppRoutes.queueControl);
          if (index == 3) Get.offNamed(AppRoutes.profile);
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

  Widget _buildDepartmentCard(DepartmentModel dept, int index) {
    final badgeColors = [
      (const Color(0xFFE6F4F1), const Color(0xFF0F8C7C)),
      (const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
      (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
      (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    ];
    final (bgColor, fgColor) = badgeColors[index % badgeColors.length];
    final doctorLabel = dept.doctorCount == 1 ? '1 doctor' : '${dept.doctorCount} doctors';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.layers_outlined, color: fgColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dept.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$doctorLabel · ${dept.dailyTokenLimit} tokens / day',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: dept.isActive,
            activeColor: Colors.white,
            activeTrackColor: AppColors.tealPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            onChanged: (val) => vm.toggleDepartment(dept, val),
          ),
        ],
      ),
    );
  }

  void _showAddDepartmentSheet() {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    final limitC = TextEditingController(text: '60');
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add department',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Department name',
                  hintText: 'e.g. Dermatology',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Department name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: limitC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily token limit',
                  hintText: '60',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descC,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    vm.addDepartment(
                      name: nameC.text,
                      description: descC.text,
                      dailyTokenLimit: int.tryParse(limitC.text.trim()) ?? 50,
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
                    'Save department',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
