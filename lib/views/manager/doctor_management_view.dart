import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';

class DoctorManagementView extends StatefulWidget {
  const DoctorManagementView({super.key});

  @override
  State<DoctorManagementView> createState() => _AddDoctorViewState();
}

class _AddDoctorViewState extends State<DoctorManagementView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController(text: 'Dr. Ahmed Raza');
  final TextEditingController _specializationController =
  TextEditingController(text: 'Consultant Cardiologist');
  final TextEditingController _tokenLimitController =
  TextEditingController(text: '40 tokens');

  final List<String> _departments = [
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'General Medicine',
  ];
  String _selectedDepartment = 'Cardiology';

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> _selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};

  TimeOfDay _fromTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 14, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _tokenLimitController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final initial = isFrom ? _fromTime : _toTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tealPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  void _handleSaveDoctor() {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing Field',
        'Please enter the doctor\'s full name',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      Get.snackbar(
        'Missing Working Days',
        'Please select at least one working day',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

// TODO: Connect to your DoctorViewModel / ManagerViewModel API call
    Get.back();
    Get.snackbar(
      'Doctor Added',
      '${_nameController.text.trim()} has been added to $_selectedDepartment',
      backgroundColor: AppColors.tealLight,
      colorText: AppColors.tealPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
// Top App Bar Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Add doctor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

// Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
// 1. Doctor Photo Upload Row
                      GestureDetector(
                        onTap: () {
// TODO: Hook up image_picker here
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.tealLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.tealPrimary,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: AppColors.tealPrimary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Doctor photo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Optional · JPG or PNG',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

// 2. Full Name Field
                      _buildFieldLabel('Full name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter doctor name',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),

// 3. Department Dropdown
                      _buildFieldLabel('Department'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Select department',
                          prefixIcon: Icons.layers_outlined,
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDepartment = val);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

// 4. Specialization Field
                      _buildFieldLabel('Specialization'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _specializationController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Consultant Cardiologist',
                          prefixIcon: Icons.medical_services_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),
// 5. Working Days Multi-Select Pills
                      _buildFieldLabel('Working days'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekDays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedDays.remove(day);
                                    } else {
                                      _selectedDays.add(day);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.tealPrimary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.tealPrimary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
// 6. From & To Time Pickers
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('From'),
                                const SizedBox(height: 8),
                                _buildTimePickerBox(
                                  timeText: _formatTime(_fromTime),
                                  onTap: () => _pickTime(isFrom: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('To'),
                                const SizedBox(height: 8),
                                _buildTimePickerBox(
                                  timeText: _formatTime(_toTime),
                                  onTap: () => _pickTime(isFrom: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
// 7. Daily Token Limit Field
                      _buildFieldLabel('Daily token limit'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tokenLimitController,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. 40 tokens',
                          prefixIcon: Icons.confirmation_number_outlined,
                        ),
                      ),
                      const SizedBox(height: 28),
// 8. Save Doctor Primary Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSaveDoctor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Save doctor'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: AppColors.textSecondary,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.tealPrimary,
          width: 1.5,
        ),
      ),
    );
  }
  Widget _buildTimePickerBox({
    required String timeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              timeText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}