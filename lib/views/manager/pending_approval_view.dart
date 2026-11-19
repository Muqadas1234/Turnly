import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/manager_viewmodel.dart';

class PendingApprovalView extends StatefulWidget {
  const PendingApprovalView({super.key});

  @override
  State<PendingApprovalView> createState() => _PendingApprovalViewState();
}

class _PendingApprovalViewState extends State<PendingApprovalView> {
final vm = Get.find<ManagerViewModel>();

@override
void initState() {
super.initState();
vm.startStatusPolling();
}

@override
void dispose() {
vm.stopStatusPolling();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
body: SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
child: Column(
children: [
const Spacer(),
// Clock icon circle
Container(
width: 84,
height: 84,
decoration: BoxDecoration(
color: Colors.amber.shade50,
shape: BoxShape.circle,
),
child: Icon(
Icons.access_time_rounded,
size: 40,
color: Colors.amber.shade800,
),
),
const SizedBox(height: 18),

// Status badge
Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
decoration: BoxDecoration(
color: Colors.amber.shade100,
borderRadius: BorderRadius.circular(20),
),
child: Text(
'Status: Pending',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: Colors.amber.shade900,
),
),
),
const SizedBox(height: 14),

// Title & description
const Text(
'Registration submitted',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w700,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 8),
Obx(() {
final hospitalName =
vm.currentHospital.value?.name.isNotEmpty == true
? vm.currentHospital.value!.name
: vm.hospitalNameC.text.trim().isNotEmpty
? vm.hospitalNameC.text.trim()
: 'your hospital';

return Text(
"The Turnly admin team is reviewing $hospitalName. We'll notify you as soon as it's approved.",
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 13.5,
height: 1.45,
color: AppColors.textSecondary,
),
);
}),
const SizedBox(height: 24),

// Timeline stepper card
Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: AppColors.border),
),
child: Column(
children: [
_buildTimelineStep(
title: 'Registration submitted',
subtitle: 'Just now',
state: _StepState.completed,
showLine: true,
),
_buildTimelineStep(
title: 'Admin review',
subtitle: 'In progress · usually within 24h',
state: _StepState.active,
showLine: true,
),
_buildTimelineStep(
title: 'Hospital goes live',
subtitle: 'Patients can book tokens',
state: _StepState.upcoming,
showLine: false,
),
],
),
),
const SizedBox(height: 14),

// Need help card
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: AppColors.border),
),
child: Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: AppColors.tealLight,
borderRadius: BorderRadius.circular(10),
),
child: const Icon(
Icons.mail_outline_rounded,
color: AppColors.tealPrimary,
size: 20,
),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Need help?',
style: TextStyle(
fontSize: 13.5,
fontWeight: FontWeight.w700,
color: AppColors.textPrimary,
),
),
SizedBox(height: 2),
Text(
'support@turnly.pk · +92 21 111 000 111',
style: TextStyle(
fontSize: 12,
color: AppColors.textSecondary,
),
),
],
),
),
],
),
),
const Spacer(),

Obx(() => SizedBox(
width: double.infinity,
height: 48,
child: ElevatedButton(
onPressed: vm.isLoading.value
? null
: () => vm.loadMyHospital(routeByStatus: true),
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.tealPrimary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: vm.isLoading.value
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
: const Text(
'Refresh status',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
)),
],
),
),
),
);
}

Widget _buildTimelineStep({
required String title,
required String subtitle,
required _StepState state,
required bool showLine,
}) {
Color circleColor;
Widget? icon;

switch (state) {
case _StepState.completed:
circleColor = AppColors.tealPrimary;
icon = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
break;
case _StepState.active:
circleColor = Colors.amber.shade100;
icon = Icon(Icons.circle, color: Colors.amber.shade700, size: 10);
break;
case _StepState.upcoming:
circleColor = AppColors.border;
icon = null;
break;
}

return IntrinsicHeight(
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Column(
children: [
Container(
width: 24,
height: 24,
decoration: BoxDecoration(
color: circleColor,
shape: BoxShape.circle,
),
child: icon,
),
if (showLine)
Expanded(
child: Container(
width: 2,
color: state == _StepState.completed
? AppColors.tealPrimary
: AppColors.border,
),
),
],
),
const SizedBox(width: 12),
Expanded(
child: Padding(
padding: EdgeInsets.only(bottom: showLine ? 18 : 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 13.5,
fontWeight: FontWeight.w700,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 2),
Text(
  subtitle,
  style: const TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  ),
),
],
),
),
),
],
),
);
}
}
enum _StepState { completed, active, upcoming }