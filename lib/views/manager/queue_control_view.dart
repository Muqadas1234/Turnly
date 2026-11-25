import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/routes.dart';

class QueuePatient {
  final int number;
  final String name;
  final String subtitle;
  final bool isPriority;

  QueuePatient({
    required this.number,
    required this.name,
    required this.subtitle,
    this.isPriority = false,
  });
}

class DoctorQueueData {
  final String room;
  QueuePatient? current;
  final List<QueuePatient> waiting;

  DoctorQueueData({
    required this.room,
    this.current,
    required this.waiting,
  });
}

class QueueControlView extends StatefulWidget {
  const QueueControlView({super.key});

  @override
  State<QueueControlView> createState() => _QueueControlViewState();
}

class _QueueControlViewState extends State<QueueControlView> {
static const Color _nowServingBlue = Color(0xFF1D5CE5);
static const Color _skipButtonBlue = Color(0xFF2A68EB);
static const Color _priorityBg = Color(0xFFEDE9FE);
static const Color _priorityText = Color(0xFF6D28D9);

String _selectedDoctor = 'Dr. Ahmed';

final Map<String, DoctorQueueData> _queues = {
'Dr. Ahmed': DoctorQueueData(
room: 'Room 4',
current: QueuePatient(
number: 9,
name: 'Imran Siddiqui',
subtitle: '54 yrs • Self',
),
waiting: [
QueuePatient(
number: 10,
name: 'Zainab Ali',
subtitle: 'Elderly • booked 8:40 AM',
isPriority: true,
),
QueuePatient(
number: 11,
name: 'Hassan Raza',
subtitle: 'Self • booked 8:52 AM',
),
QueuePatient(
number: 12,
name: 'Ayesha Khan',
subtitle: 'Self • booked 9:05 AM',
),
QueuePatient(
number: 13,
name: 'Sara Khan',
subtitle: 'Daughter of Ayesha • 9:05 AM',
),
],
),
'Dr. Sana': DoctorQueueData(
room: 'Room 2',
current: QueuePatient(
number: 24,
name: 'Bilal Tariq',
subtitle: '32 yrs • Self',
),
waiting: [
QueuePatient(
number: 25,
name: 'Fatima Noor',
subtitle: 'Self • booked 9:10 AM',
),
],
),
'Dr. Hina': DoctorQueueData(
room: 'Room 1',
current: QueuePatient(
number: 7,
name: 'Usman Ghani',
subtitle: '41 yrs • Self',
),
waiting: [
QueuePatient(
number: 8,
name: 'Mariam Bibi',
subtitle: 'Elderly • booked 8:55 AM',
isPriority: true,
),
],
),
};

void _advanceQueue() {
setState(() {
final activeQueue = _queues[_selectedDoctor]!;
if (activeQueue.waiting.isNotEmpty) {
final nextUp = activeQueue.waiting.removeAt(0);
activeQueue.current = QueuePatient(
number: nextUp.number,
name: nextUp.name,
subtitle: nextUp.subtitle.split('•').first.trim(),
);
} else {
activeQueue.current = null;
}
});
}

@override
Widget build(BuildContext context) {
final activeQueue = _queues[_selectedDoctor]!;
final nextPatient =
activeQueue.waiting.isNotEmpty ? activeQueue.waiting.first : null;

return Scaffold(
backgroundColor: AppColors.background,
body: SafeArea(
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// 1. Doctor Filter Pills
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: _queues.keys.map((doctor) {
final isSelected = _selectedDoctor == doctor;
return Padding(
padding: const EdgeInsets.only(right: 8),
child: GestureDetector(
onTap: () => setState(() => _selectedDoctor = doctor),
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
decoration: BoxDecoration(
color: isSelected
? AppColors.tealPrimary
: AppColors.surface,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: isSelected
? AppColors.tealPrimary
: AppColors.border,
),
),
child: Text(
doctor,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: isSelected
? Colors.white
: AppColors.textPrimary,
),
),
),
),
);
}).toList(),
),
),
const SizedBox(height: 18),

// 2. NOW SERVING Blue Card
Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: _nowServingBlue,
borderRadius: BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color: _nowServingBlue.withOpacity(0.22),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'NOW SERVING',
style: TextStyle(
color: Colors.white70,
fontSize: 11,
fontWeight: FontWeight.w700,
letterSpacing: 0.8,
),
),
Text(
activeQueue.room,
style: const TextStyle(
color: Colors.white70,
fontSize: 12,
fontWeight: FontWeight.w500,
),
),
],
),
const SizedBox(height: 12),
if (activeQueue.current != null)
Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Text(
'#${activeQueue.current!.number}',
style: const TextStyle(
color: Colors.white,
fontSize: 38,
fontWeight: FontWeight.w800,
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
activeQueue.current!.name,
style: const TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 2),
Text(
activeQueue.current!.subtitle,
style: const TextStyle(
color: Colors.white70,
fontSize: 12.5,
),
),
],
),
),
],
)
else
const Padding(
padding: EdgeInsets.symmetric(vertical: 16),
child: Center(
child: Text(
'No patient currently being served',
style: TextStyle(color: Colors.white70),
),
),
),
const SizedBox(height: 18),

// Complete & Skip no-show Buttons
Row(
children: [
Expanded(
child: ElevatedButton.icon(
onPressed: activeQueue.current != null
? _advanceQueue
: null,
icon: const Icon(Icons.check_rounded, size: 18),
label: const Text('Complete'),
style: ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: AppColors.tealPrimary,
  elevation: 0,
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  textStyle: const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
  ),
),
),
),
  const SizedBox(width: 12),
  Expanded(
    child: OutlinedButton.icon(
      onPressed: activeQueue.current != null
          ? _advanceQueue
          : null,
      icon: const Icon(Icons.skip_next_outlined, size: 18),
      label: const Text('Skip no-show'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _skipButtonBlue,
        side: BorderSide(
          color: Colors.white.withOpacity(0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
    ),
  ),
],
),
],
),
),
  const SizedBox(height: 14),
// 3. Call Next Primary CTA Button
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: nextPatient != null ? _advanceQueue : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(
        nextPatient != null
            ? 'Call next - #${nextPatient.number}'
            : 'No patients waiting',
      ),
    ),
  ),
  const SizedBox(height: 22),
// 4. Waiting Section Header
  Text(
    'Waiting - ${activeQueue.waiting.length} patients',
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  ),
  const SizedBox(height: 12),
// 5. Waiting Patient Cards
  ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: activeQueue.waiting.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final patient = activeQueue.waiting[index];
      return _buildWaitingPatientCard(patient);
    },
  ),
],
),
),
),
// 6. Matching BottomNavigationBar from ManagerDashboardView
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: 1,
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.tealPrimary,
    unselectedItemColor: AppColors.textSecondary,
    selectedFontSize: 11.5,
    unselectedFontSize: 11.5,
    onTap: (index) {
      if (index == 0) Get.offNamed(AppRoutes.managerDashboard);
      if (index == 2) Get.toNamed(AppRoutes.doctorManagement);
      if (index == 3) Get.toNamed(AppRoutes.profile);
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment_rounded),
        label: 'Queue',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.medical_services_outlined),
        activeIcon: Icon(Icons.medical_services_rounded),
        label: 'Doctors',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ],
  ),
);
}
Widget _buildWaitingPatientCard(QueuePatient patient) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: patient.isPriority ? _priorityBg : AppColors.tealLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '#${patient.number}',
            style: TextStyle(
              color: patient.isPriority
                  ? _priorityText
                  : AppColors.tealPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                patient.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (patient.isPriority)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _priorityBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Priority',
              style: TextStyle(
                color: _priorityText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}
}