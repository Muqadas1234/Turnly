import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/patient_viewmodel.dart';
import '../../widgets/app_icon.dart';
import '../../utils/routes.dart';

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  final AuthViewModel _authVm = Get.find<AuthViewModel>();
  final PatientViewModel _patientVm = Get.find<PatientViewModel>();
  final TextEditingController _patientNameController = TextEditingController();

  Map<String, dynamic> _doctor = {};
  Map<String, dynamic> _hospital = {};
  int _hospitalId = 0;

  DateTime _selectedDate = DateTime.now();

  bool _isForMyself = true;
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
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    final patientName = _isForMyself
        ? (_authVm.currentUser.value?['name'] ?? 'Patient')
        : _patientNameController.text.trim();

    if (!_isForMyself && patientName.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter patient name',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final docId = int.tryParse(_doctor['id']?.toString() ?? '') ?? 0;
    final hospId = _hospitalId > 0
        ? _hospitalId
        : (int.tryParse(_doctor['hospital_id']?.toString() ?? '') ?? 0);
    final deptId = int.tryParse(_doctor['department_id']?.toString() ?? '');

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
    final formattedDate = DateFormat('yyyy-MM-dd').format(bookingDate);

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.bookToken(
        doctorId: docId,
        hospitalId: hospId,
        departmentId: deptId,
        patientName: patientName,
        bookingDate: formattedDate,
      );

      if (response['success'] == true) {
        // Refresh active token in PatientViewModel
        await _patientVm.fetchActiveToken();
        if (!mounted) return;
        final tokenData = response['data'] as Map? ?? {};
        final tokenNum = tokenData['token_number'] ?? 1;
        _showSuccess(tokenNum, patientName, bookingDate);
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

  void _showSuccess(dynamic tokenNum, String patientName, DateTime confirmedDate) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.adminApprovedBg,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppIcon('check', size: 30, color: AppColors.adminApprovedText),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Token Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Token #$tokenNum booked for $patientName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('EEE, d MMM yyyy').format(confirmedDate),
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    // Cleanly close dialog and return to previous screen without race conditions
                    Get.until((route) => route.settings.name == AppRoutes.hospitalDetail || route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
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
          icon: const AppIcon('arrow_left', size: 20, color: AppColors.textPrimary),
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
                    const AppIcon('calendar', size: 20, color: AppColors.adminPrimary),
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
                    const AppIcon('chevron-down', size: 16, color: AppColors.textSecondary),
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
              TextField(
                controller: _patientNameController,
                decoration: InputDecoration(
                  labelText: 'Patient Full Name',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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