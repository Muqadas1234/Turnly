import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/patient_viewmodel.dart';
import '../../utils/routes.dart';

class HospitalDetailView extends StatefulWidget {
  final int? hospitalId;
  final String? hospitalName;

  const HospitalDetailView({
    super.key,
    this.hospitalId,
    this.hospitalName,
  });

  @override
  State<HospitalDetailView> createState() => _HospitalDetailViewState();
}

class _HospitalDetailViewState extends State<HospitalDetailView> {
  final PatientViewModel _patientVm = Get.find<PatientViewModel>();

  int get _resolvedHospitalId {
    if (widget.hospitalId != null && widget.hospitalId! > 0) {
      return widget.hospitalId!;
    }
    if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      final rawId = args['hospitalId'] ??
          args['hospital_id'] ??
          (args['hospital'] is Map ? (args['hospital'] as Map)['id'] : null);
      return int.tryParse(rawId?.toString() ?? '') ?? 0;
    }
    if (Get.arguments is int) {
      return Get.arguments as int;
    }
    return 0;
  }

  String get _resolvedHospitalName {
    if (widget.hospitalName != null && widget.hospitalName!.isNotEmpty) {
      return widget.hospitalName!;
    }
    if (Get.arguments is Map && Get.arguments['hospitalName'] != null) {
      return Get.arguments['hospitalName'].toString();
    }
    return 'Hospital';
  }

  @override
  void initState() {
    super.initState();
    _patientVm.fetchHospitalDetails(_resolvedHospitalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Hospital details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (_patientVm.isLoadingDetails.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.adminPrimary),
          );
        }
        if (_patientVm.currentHospital.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _patientVm.errorMessage.value.isEmpty
                        ? 'Hospital details are unavailable.'
                        : _patientVm.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _resolvedHospitalId > 0
                        ? () => _patientVm.fetchHospitalDetails(_resolvedHospitalId)
                        : () => Get.back(),
                    child: Text(_resolvedHospitalId > 0 ? 'Try again' : 'Go back'),
                  ),
                ],
              ),
            ),
          );
        }

        final hospital = _patientVm.currentHospital.value ?? {};
        final name = hospital['name'] ?? _resolvedHospitalName;
        final address = hospital['address'] ?? '';
        final city = hospital['city'] ?? '';
        final timings = hospital['opd_timings'] ?? '9:00 AM - 8:00 PM';
        final doctorsCount = _patientVm.doctors.length;

        final words = name.trim().split(RegExp(r'\s+'));
        final initials = words.length >= 2
            ? '${words[0][0]}${words[1][0]}'.toUpperCase()
            : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

        final depts = _patientVm.departments;
        final filteredDoctors = _patientVm.filteredDoctors;
        // Observe selected doctor ID inside the body Obx so list highlight updates immediately
        final selectedDocId = _patientVm.selectedDoctor.value?['id'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hospital Hero Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$address, $city',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.adminApprovedBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user_outlined, size: 12, color: AppColors.adminApprovedText),
                                    SizedBox(width: 4),
                                    Text(
                                      'Approved by Turnly',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.adminApprovedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),

                    // Quick Specs Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickSpec(Icons.access_time, timings, 'OPD timings'),
                        _buildQuickSpec(Icons.people_outline, '$doctorsCount', 'Doctors'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Departments Horizontal Selector
              const Text(
                'Departments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (depts.isEmpty)
                const Text('No departments listed yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: depts.map((d) {
                      final isSelected = _patientVm.selectedDepartmentId.value == d['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            d['name'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.surface : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _patientVm.selectDepartment(d['id']),
                          selectedColor: AppColors.adminPrimary,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.adminPrimary : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              // 3. Doctors in Department List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Doctors in ${_getCurrentDeptName()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: doctorsCount == 0
                        ? null
                        : () => Get.toNamed(
                              AppRoutes.doctorList,
                              arguments: {
                                'hospitalId': _resolvedHospitalId,
                                'hospital': hospital,
                              },
                            ),
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filteredDoctors.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No available doctors in this department.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDoctors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filteredDoctors[index];
                    return _buildDoctorCard(doc, selectedDocId);
                  },
                ),
            ],
          ),
        );
      }),

      // Bottom Sticky Booking Button
      bottomNavigationBar: Obx(() {
        final doc = _patientVm.selectedDoctor.value;
        if (doc == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.booking,
                    arguments: {
                      'doctor': doc,
                      'hospital': _patientVm.currentHospital.value,
                      'hospitalId': _resolvedHospitalId,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Book with ${doc['name'] ?? 'Doctor'}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getCurrentDeptName() {
    final deptId = _patientVm.selectedDepartmentId.value;
    final dept = _patientVm.departments.firstWhereOrNull((d) => d['id'] == deptId);
    return dept != null ? dept['name'] : 'Department';
  }

  Widget _buildQuickSpec(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.adminPrimary),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doc, dynamic selectedDocId) {
    final name = doc['name'] ?? 'Doctor';
    final spec = doc['specialization'] ?? 'Specialist';
    final exp = int.tryParse(doc['experience_years']?.toString() ?? '0') ?? 0;
    
    // Dynamic availability_hours from the database (set by hospital manager)
    final rawHours = doc['availability_hours']?.toString();
    final scheduleDays = doc['schedule_days'];
    final scheduleFrom = doc['schedule_from'];
    final scheduleTo = doc['schedule_to'];

    String hours = 'Mon - Sat · 09:00 - 17:00';
    if (rawHours != null && rawHours.trim().isNotEmpty && rawHours != 'Schedule not set') {
      hours = rawHours;
    } else if (scheduleFrom != null && scheduleTo != null) {
      final daysText = (scheduleDays is List && scheduleDays.isNotEmpty)
          ? (scheduleDays.length >= 6 ? 'Mon - Sat' : scheduleDays.join(', '))
          : 'Mon - Sat';
      hours = '$daysText · $scheduleFrom - $scheduleTo';
    }

    // Dynamic availability status from the database
    final isAvailable = doc['is_available'] != false;
    final isSelected = selectedDocId != null && selectedDocId == doc['id'];

    final docWords = name.trim().split(RegExp(r'\s+'));
    final initials = docWords.length >= 2
        ? '${docWords[0][0]}${docWords[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return InkWell(
      onTap: () => _patientVm.selectDoctor(doc),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.adminPrimary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isAvailable
                  ? AppColors.adminPrimaryLight
                  : AppColors.border,
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAvailable
                      ? AppColors.adminPrimaryDark
                      : AppColors.textSecondary,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exp > 0 ? '$spec · $exp yrs exp' : spec,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  // Dynamic schedule from database (set by hospital manager)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          hours,
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Dynamic availability badge from database is_available field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.adminApprovedBg
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAvailable
                          ? AppColors.adminApprovedText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Book button — tapping directly opens booking screen for this doctor
                InkWell(
                  onTap: isAvailable
                      ? () {
                          _patientVm.selectDoctor(doc);
                          Get.toNamed(
                            AppRoutes.booking,
                            arguments: {
                              'doctor': doc,
                              'hospital': _patientVm.currentHospital.value,
                              'hospitalId': _resolvedHospitalId,
                            },
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.adminPrimary
                          : (isAvailable ? AppColors.adminPrimaryLight : AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAvailable
                            ? AppColors.adminPrimary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isAvailable
                                ? AppColors.adminPrimaryDark
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}