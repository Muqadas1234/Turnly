import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/patient_viewmodel.dart';
import 'token_confirmation_view.dart';

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  final AuthViewModel _authVm = Get.find<AuthViewModel>();
  final PatientViewModel _patientVm = Get.find<PatientViewModel>();

  Map<String, dynamic> _doctor = {};
  Map<String, dynamic> _hospital = {};
  int _hospitalId = 0;

  DateTime _selectedDate = DateTime.now();

  bool _isForMyself = true;
  int? _selectedFamilyMemberId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Safely extract arguments
    final args = (Get.arguments is Map) ? Get.arguments as Map : {};
    if (args['doctor'] is Map) {
      _doctor = Map<String, dynamic>.from(args['doctor'] as Map);
    }
    if (args['hospital'] is Map) {
      _hospital = Map<String, dynamic>.from(args['hospital'] as Map);
    }

    // Resolve hospital ID from arguments, hospital map, or doctor map
    _hospitalId = int.tryParse(args['hospitalId']?.toString() ?? '') ??
        int.tryParse(_hospital['id']?.toString() ?? '') ??
        int.tryParse(_doctor['hospital_id']?.toString() ?? '') ??
        0;

    _selectedDate = DateTime.now();
    _patientVm.fetchFamilyMembers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (!_isForMyself && _selectedFamilyMemberId == null) {
      Get.snackbar(
        'Select family member',
        'Choose a saved family member or add one from the Family Members screen.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            Get.toNamed('/family-members');
          },
          child: const Text('Add member', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final docId = int.tryParse(_doctor['id']?.toString() ?? '') ?? 0;
    final hospId = _hospitalId > 0
        ? _hospitalId
        : (int.tryParse(_doctor['hospital_id']?.toString() ?? '') ?? 0);

    if (docId == 0 || hospId == 0) {
      Get.snackbar(
        'Error',
        'Invalid doctor or hospital selection',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final bookingDate = _selectedDate;

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.bookToken(
        doctorId: docId,
        date: DateFormat('yyyy-MM-dd').format(bookingDate),
        familyMemberId: _isForMyself ? null : _selectedFamilyMemberId,
      );

      if (response['success'] == true) {
        // Refresh active token in PatientViewModel
        await _patientVm.fetchActiveToken();
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        // Navigate to dedicated confirmation screen
        Get.to(() => const TokenConfirmationView());
        return;
      } else {
        if (!mounted) return;
        Get.snackbar(
          'Booking Failed',
          response['message'] ?? 'Unable to book token',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Connection Error',
        'Could not reach server: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Opens date picker dialog allowing selection up to 30 days ahead
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.adminPrimary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _getDateSubtitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = target.difference(today).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => 'In $diff days',
    };
  }

  @override
  Widget build(BuildContext context) {
    final docName = _doctor['name'] ?? 'Doctor';
    final spec = _doctor['specialization'] ?? 'Specialist';
    final hospName = _hospital['name'] ?? 'Hospital';
    final hours = _doctor['availability_hours'] ?? 'OPD Hours';
    final myName = _authVm.currentUser.value?['name'] ?? 'Patient';

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
          'Book Token',
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
            // 1. Doctor Information Card
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
                    radius: 24,
                    backgroundColor: AppColors.adminPrimaryLight,
                    child: Text(
                      docName.isNotEmpty ? docName[0].toUpperCase() : 'D',
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
                          docName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$spec · $hospName',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hours,
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Appointment Date Picker
            const Text(
              'Appointment Date',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.adminPrimary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDateSubtitle(),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Patient Selection (Myself vs Family/Other)
            const Text(
              'Patient',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      'Myself ($myName)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  selected: _isForMyself,
                  selectedColor: AppColors.adminPrimaryLight,
                  onSelected: (_) => setState(() => _isForMyself = true),
                ),
                ChoiceChip(
                  label: const Text('Family / Other'),
                  selected: !_isForMyself,
                  selectedColor: AppColors.adminPrimaryLight,
                  onSelected: (_) => setState(() => _isForMyself = false),
                ),
              ],
            ),
            if (!_isForMyself) ...[
              const SizedBox(height: 14),
              Obx(() {
                if (_patientVm.familyMembers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('No saved family members yet. Add a member before booking for them.'),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed('/family-members'),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedFamilyMemberId,
                  decoration: InputDecoration(
                    labelText: 'Select family member',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _patientVm.familyMembers.map((member) {
                    final id = int.tryParse(member['id']?.toString() ?? '');
                    if (id == null) return null;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('${member['name'] ?? 'Family member'} (${member['relation'] ?? 'Other'})'),
                    );
                  }).whereType<DropdownMenuItem<int>>().toList(),
                  onChanged: (value) => setState(() => _selectedFamilyMemberId = value),
                );
              }),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text(
              'Confirm Booking',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}