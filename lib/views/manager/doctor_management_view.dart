import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/department_model.dart';
import '../../services/api_service.dart';
import '../../services/manager_api.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';

class DoctorManagementView extends StatefulWidget {
  const DoctorManagementView({super.key});

  @override
  State<DoctorManagementView> createState() => _AddDoctorViewState();
}

class _AddDoctorViewState extends State<DoctorManagementView> {
final _formKey = GlobalKey<FormState>();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _specializationController = TextEditingController();
final TextEditingController _tokenLimitController = TextEditingController(text: '40');

List<DepartmentModel> _departments = [];
String? _selectedDepartmentId;
bool _loadingDepartments = true;
bool _saving = false;

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
void initState() {
super.initState();
_loadDepartments();
}

/// Safely returns to the previous screen if one exists on the stack,
/// or routes back to the Manager Dashboard if opened via Get.offNamed.
void _handleBack() {
if (Get.key.currentState?.canPop() ?? false) {
Get.back(closeOverlays: true);
} else {
Get.offNamed(AppRoutes.managerDashboard);
}
}

/// Loads this manager's real departments from the backend.
Future<void> _loadDepartments() async {
try {
final res = await ApiService.getDepartments();
final raw = res['departments'];
if (res['success'] == true && raw is List) {
final list = raw
.whereType<Map>()
.map((e) => DepartmentModel.fromMap(Map<String, dynamic>.from(e)))
.where((d) => d.isActive)
.toList();
if (!mounted) return;
setState(() {
_departments = list;
_selectedDepartmentId = list.isEmpty ? null : list.first.departmentId;
});
}
} catch (_) {
// leave list empty; the form explains it
} finally {
if (mounted) setState(() => _loadingDepartments = false);
}
}

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

/// Validates the form, then sends the new doctor to the backend (POST /api/doctors).
Future<void> _handleSaveDoctor() async {
if (_saving) return;

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

final tokenLimit = int.tryParse(_tokenLimitController.text.trim());
if (tokenLimit == null || tokenLimit <= 0 || tokenLimit > 500) {
Get.snackbar(
'Invalid token limit',
'Enter a whole number between 1 and 500.',
backgroundColor: Colors.red.shade50,
colorText: Colors.red.shade800,
);
return;
}

final fromMinutes = _fromTime.hour * 60 + _fromTime.minute;
final toMinutes = _toTime.hour * 60 + _toTime.minute;
if (toMinutes <= fromMinutes) {
Get.snackbar(
'Invalid timing',
'The end time must be after the start time.',
backgroundColor: Colors.red.shade50,
colorText: Colors.red.shade800,
);
return;
}

final departmentId = int.tryParse(_selectedDepartmentId ?? '');
if (departmentId == null) {
Get.snackbar(
'No department',
'Create a department first (Profile > Manage departments), then add the doctor.',
backgroundColor: Colors.red.shade50,
colorText: Colors.red.shade800,
);
return;
}

String hm(TimeOfDay t) =>
'${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

setState(() => _saving = true);
final res = await ManagerApi.createDoctor({
'name': _nameController.text.trim(),
'department_id': departmentId,
if (_specializationController.text.trim().isNotEmpty)
'specialization': _specializationController.text.trim(),
'schedule_days': order.where(_selectedDays.contains).toList(),
'schedule_from': hm(_fromTime),
'schedule_to': hm(_toTime),
'daily_token_limit': tokenLimit,
});

if (mounted) setState(() => _saving = false);

if (res['success'] == true) {
_handleBack();
Get.snackbar(
'Doctor added',
res['message']?.toString() ?? 'Doctor added successfully',
backgroundColor: Colors.green.shade50,
colorText: Colors.green.shade900,
);
} else {
Get.snackbar(
'Doctor not saved',
res['message']?.toString() ?? 'Please try again.',
backgroundColor: Colors.red.shade50,
colorText: Colors.red.shade800,
duration: const Duration(seconds: 5),
);
}
}

@override
Widget build(BuildContext context) {
return PopScope(
canPop: false,
onPopInvokedWithResult: (didPop, _) {
if (!didPop) {
_handleBack();
}
},
child: Scaffold(
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
behavior: HitTestBehavior.opaque,
onTap: _handleBack,
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
onTap: () => Get.snackbar(
'Photo upload unavailable',
'Image upload is not connected in the supplied app services.',
),
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
  DropdownButtonFormField(
    initialValue: _selectedDepartmentId,
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
        value: dept.departmentId,
        child: Text(dept.name),
      );
    }).toList(),
    hint: Text(_loadingDepartments
        ? 'Loading departments...'
        : 'No departments yet'),
    onChanged: (val) {
      if (val != null) {
        setState(() => _selectedDepartmentId = val);
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
// 6. From & To Time Pickers Row
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
    keyboardType: TextInputType.number,
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
      onPressed: _saving ? null : _handleSaveDoctor,
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
      child: _saving
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text('Save doctor'),
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

