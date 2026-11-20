import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/patient_viewmodel.dart';
import '../../widgets/app_icon.dart';
import 'hospital_detail_view.dart';
import 'my_token_view.dart';

class PatientHomeTab extends StatefulWidget {
  const PatientHomeTab({super.key});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab> {
  final PatientViewModel _patientVm = Get.put(PatientViewModel());
  final AuthViewModel _authVm = Get.find<AuthViewModel>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current user's display name from auth state
    final userName = _authVm.currentUser.value?['name'] ?? 'Patient';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _patientVm.refreshCatalog();
          },
          color: AppColors.adminPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Greeting and Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, $userName',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Find your hospital',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: AppIcon('bell', size: 20, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Search Bar and Filters
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            _patientVm.search(value);
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Search hospitals or city',
                            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: AppIcon('search', size: 18, color: AppColors.textHint),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const AppIcon('x', size: 16, color: AppColors.textHint),
                                    onPressed: () {
                                      _searchController.clear();
                                      _patientVm.search('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.adminPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: AppIcon('sliders-horizontal', color: AppColors.surface, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Active Token Banner (shown when active token exists)
                Obx(() {
                  final token = _patientVm.activeToken.value;
                  if (token == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildActiveTokenCard(token),
                  );
                }),

                // Dynamic City Filter Chips
                Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _patientVm.availableCities.map((city) {
                      final isSelected = _patientVm.selectedCity.value == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            city,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.surface : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _searchController.clear();
                              _patientVm.setCityFilter(city);
                              setState(() {});
                            }
                          },
                          selectedColor: AppColors.adminPrimary,
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.adminPrimary : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      );
                    }).toList(),
                  ),
                )),
                const SizedBox(height: 22),

                // Approved Hospitals Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Approved hospitals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.adminPrimary,
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Approved Hospitals List
                Obx(() {
                  if (_patientVm.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.adminPrimary),
                      ),
                    );
                  }

                  if (_patientVm.hospitals.isEmpty) {
                    final query = _patientVm.currentSearchQuery.value.trim();
                    final emptyMsg = query.isNotEmpty
                        ? 'No approved hospitals found matching "$query"'
                        : 'No approved hospitals found in ${_patientVm.selectedCity.value}';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const AppIcon('hospital', size: 36, color: AppColors.textHint),
                          const SizedBox(height: 10),
                          Text(
                            emptyMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _patientVm.hospitals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hospital = _patientVm.hospitals[index];
                      return _buildHospitalCard(hospital);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Active Token Banner Card
  Widget _buildActiveTokenCard(Map<String, dynamic> token) {
    final tokenNumber = int.tryParse(token['token_number']?.toString() ?? '0') ?? 0;
    final doctorName = token['doctor_name']?.toString() ?? 'Doctor';
    final aheadCount = int.tryParse(token['ahead_count']?.toString() ?? '0') ?? 0;
    final waitMin = int.tryParse(token['estimated_wait_minutes']?.toString() ?? '20') ?? 20;

    return InkWell(
      onTap: () => Get.to(() => const MyTokenView()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adminPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR ACTIVE TOKEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Token #$tokenNumber · Dr. $doctorName',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$aheadCount patients ahead · ~$waitMin min wait',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const AppIcon('arrow-right', color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // Approved Hospital Card Widget
  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    final name = hospital['name'] ?? 'Hospital';
    final city = hospital['city'] ?? '';
    final address = hospital['address'] ?? city;
    final timings = hospital['opd_timings'] ?? 'OPD 9AM-8PM';
    final facilityType = hospital['type']?.toString() ?? 'Hospital';
    final doctorsCount = int.tryParse(hospital['doctors_count']?.toString() ?? '0') ?? 0;
    final hospitalId = int.tryParse(hospital['id']?.toString() ?? '0') ?? 0;

    // Generate initials for avatar
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return InkWell(
      onTap: () {
        Get.to(() => HospitalDetailView(
          hospitalId: hospitalId,
          hospitalName: name,
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Initials Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.adminPrimaryLight,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimaryDark,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Hospital Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const AppIcon('map-pin', size: 14, color: AppColors.textSecondary),
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

                  // Status Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.adminApprovedBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          facilityType,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.adminApprovedText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.adminBlueBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timings,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.adminBlue,
                          ),
                        ),
                      ),
                      if (doctorsCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$doctorsCount doctors',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon('chevron-right', color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
