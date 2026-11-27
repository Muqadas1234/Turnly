import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/patient_viewmodel.dart';

/// Doctor directory for a selected hospital. Expects {hospitalId, hospital}.
class DoctorListView extends StatefulWidget {
  const DoctorListView({super.key});

  @override
  State<DoctorListView> createState() => _DoctorListViewState();
}

class _DoctorListViewState extends State<DoctorListView> {
  late final PatientViewModel vm;
  late final int hospitalId;
  late final Map<String, dynamic> hospital;

  @override
  void initState() {
    super.initState();
    vm = Get.isRegistered<PatientViewModel>()
        ? Get.find<PatientViewModel>()
        : Get.put(PatientViewModel());

    final args = Get.arguments;
    final data = args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{};
    hospital = data['hospital'] is Map
        ? Map<String, dynamic>.from(data['hospital'] as Map)
        : <String, dynamic>{};
    hospitalId = int.tryParse(
          (data['hospitalId'] ?? data['hospital_id'] ?? hospital['id'] ?? '').toString(),
        ) ??
        0;

    if (hospitalId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.fetchHospitalDetails(hospitalId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
              vm.currentHospital.value?['name']?.toString() ??
                  hospital['name']?.toString() ??
                  'Doctors',
            )),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: hospitalId <= 0
          ? const Center(child: Text('Hospital information is missing. Go back and select a hospital.'))
          : Obx(() {
              if (vm.isLoadingDetails.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.errorMessage.value.isNotEmpty && vm.doctors.isEmpty) {
                return _MessageState(
                  message: vm.errorMessage.value,
                  onRetry: () => vm.fetchHospitalDetails(hospitalId),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.departments.isNotEmpty)
                    SizedBox(
                      height: 62,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: vm.selectedDepartmentId.value == null,
                            onSelected: (_) => vm.selectDepartment(null),
                          ),
                          const SizedBox(width: 8),
                          ...vm.departments.map((department) {
                            final id = int.tryParse(
                              (department['id'] ?? department['department_id'] ?? '').toString(),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(department['name']?.toString() ?? 'Department'),
                                selected: vm.selectedDepartmentId.value == id,
                                onSelected: (_) => vm.selectDepartment(id),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text(
                      '${vm.filteredDoctors.length} doctors available',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: vm.filteredDoctors.isEmpty
                        ? const Center(child: Text('No doctors found for this department.'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: vm.filteredDoctors.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final doctor = vm.filteredDoctors[index];
                              final available = doctor['is_available'] != false;
                              final selected = vm.selectedDoctor.value?['id'] == doctor['id'];
                              return Card(
                                elevation: 0,
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: selected ? AppColors.adminPrimary : AppColors.border,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: available ? () => vm.selectDoctor(doctor) : null,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.adminPrimaryLight,
                                    child: const Icon(Icons.medical_services_outlined, color: AppColors.adminPrimary),
                                  ),
                                  title: Text(
                                    doctor['name']?.toString() ?? 'Doctor',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text([
                                    doctor['specialization']?.toString() ?? 'General physician',
                                    if (doctor['experience_years'] != null)
                                      '${doctor['experience_years']} years experience',
                                    if (doctor['availability_hours'] != null)
                                      doctor['availability_hours'].toString(),
                                  ].join(' · ')),
                                  trailing: Icon(
                                    selected ? Icons.check_circle : Icons.chevron_right,
                                    color: selected ? AppColors.adminPrimary : AppColors.textHint,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
      bottomNavigationBar: Obx(() {
        final doctor = vm.selectedDoctor.value;
        return SafeArea(
          minimum: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: doctor == null
                ? null
                : () => Get.toNamed(
                      AppRoutes.booking,
                      arguments: {
                        'doctor': doctor,
                        'hospital': vm.currentHospital.value ?? hospital,
                        'hospitalId': hospitalId,
                      },
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text('Continue to booking'),
          ),
        );
      }),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
