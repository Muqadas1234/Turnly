import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/manager_api.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../viewmodels/manager_viewmodel.dart';

/// Live queue control for the hospital manager.
/// Backend: GET /api/queue/stats (doctor list), GET /api/queue/:doctorId,
/// POST /api/queue/:doctorId/call-next, POST /api/queue/tokens/:id/{complete|skip|recall|cancel}
class QueueControlView extends StatefulWidget {
  const QueueControlView({super.key});

  @override
  State<QueueControlView> createState() => _QueueControlViewState();
}

class _QueueControlViewState extends State<QueueControlView> {
  late final ManagerViewModel vm;
  final RxSet<int> _busy = <int>{}.obs;
  Timer? _pollTimer;
  DateTime _selectedDate = DateTime.now();
  String get _dateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    vm = Get.find<ManagerViewModel>();
    vm.fetchDashboard(date: _dateString);
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _busy.isEmpty) vm.fetchDashboard(date: _dateString);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tealPrimary,
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
      vm.fetchDashboard(date: _dateString);
    }
  }

  int? _id(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

  String _value(Map<String, dynamic> item, List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  void _toast(Map<String, dynamic> r, {String ok = 'Done'}) {
    final success = r['success'] == true;
    Get.snackbar(
      success ? 'Queue updated' : 'Action failed',
      r['message']?.toString() ?? (success ? ok : 'Please try again.'),
      backgroundColor: success ? AppColors.successBg : AppColors.errorBg,
      colorText: success ? AppColors.textPrimary : AppColors.error,
    );
  }

  Future<void> _callNext(int doctorId, {Map<String, dynamic>? doctorContext}) async {
    _busy.add(doctorId);
    try {
      final res = await ManagerApi.callNext(doctorId, date: _dateString);
      if (res['success'] == true) {
        final token = res['token'] is Map ? Map<String, dynamic>.from(res['token'] as Map) : null;
        if (token != null && mounted) {
          showPatientDoctorDetailsSheet(context, token: token, doctor: doctorContext);
        } else {
          _toast(res);
        }
      } else {
        _toast(res);
      }
    } finally {
      _busy.remove(doctorId);
      await vm.fetchDashboard(date: _dateString);
    }
  }

  Future<void> _completeCurrent(int doctorId) async {
    _busy.add(doctorId);
    try {
      _toast(await ManagerApi.completeCurrent(doctorId, date: _dateString), ok: 'Consultation marked as completed');
    } finally {
      _busy.remove(doctorId);
      await vm.fetchDashboard(date: _dateString);
    }
  }

  void _openQueue(int doctorId, String doctorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoctorQueueSheet(doctorId: doctorId, doctorName: doctorName, date: _dateString),
    ).whenComplete(() => vm.fetchDashboard(date: _dateString));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Queue control'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh queue',
            onPressed: () => vm.fetchDashboard(date: _dateString),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.fetchDashboard(date: _dateString),
        child: Obx(() {
          if (vm.isDashboardLoading.value && vm.todayQueues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.tealPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Queue Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            DateUtils.isSameDay(_selectedDate, DateTime.now())
                                ? 'Today (${DateFormat('d MMM yyyy').format(_selectedDate)})'
                                : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.tealPrimary),
                      label: const Text('Change date', style: TextStyle(color: AppColors.tealPrimary, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              _summaryCard(
                'Patients waiting',
                vm.inQueueNow.value.toString(),
                Icons.groups_outlined,
              ),
              const SizedBox(height: 18),
              Text(
                DateUtils.isSameDay(_selectedDate, DateTime.now())
                    ? 'Today’s doctor queues'
                    : 'Doctor queues for ${DateFormat('d MMM yyyy').format(_selectedDate)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              if (vm.errorMessage.value.isNotEmpty && vm.todayQueues.isEmpty)
                _emptyState(vm.errorMessage.value)
              else if (vm.todayQueues.isEmpty)
                _emptyState('No doctors yet. Add doctors from the Doctors tab to start managing queues.')
              else
                ...vm.todayQueues.map((queue) {
                  final doctorId = _id(queue['id'] ?? queue['doctor_id']);
                  final doctor = _value(queue, ['name', 'doctor_name'], fallback: 'Doctor');
                  final qualification = _value(queue, ['qualification'], fallback: '');
                  final serving = _value(queue, ['now_serving'], fallback: 'none');
                  final servingName = _value(queue, ['now_serving_patient_name'], fallback: '');
                  final servingAge = queue['now_serving_patient_age'];
                  final servingRelation = (queue['now_serving_relation'] ?? '').toString();
                  final servingPhone = (queue['now_serving_patient_phone'] ?? '').toString();
                  final servingPriority = queue['now_serving_priority'] == true || queue['now_serving_priority']?.toString() == 'true';
                  final servingPriorityCat = (queue['now_serving_priority_category'] ?? '').toString();
                  final servingNotes = (queue['now_serving_notes'] ?? '').toString();
                  final waiting = _value(queue, ['waiting'], fallback: '0');
                  final room = _value(queue, ['room']);
                  final dept = _value(queue, ['department_name'], fallback: '');
                  final timing = _value(queue, ['availability_hours'], fallback: '09:00 - 17:00');
                  final isServing = serving != 'none' && serving.isNotEmpty && serving != 'null';
                  final waitingCount = int.tryParse(waiting) ?? 0;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.tealLight,
                                child: Icon(Icons.medical_services_outlined, color: AppColors.tealPrimary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doctor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    if (qualification.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(qualification, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.tealPrimary)),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dept.isEmpty ? '' : '$dept · '}Room $room · 🕒 $timing',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(waiting,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.tealPrimary)),
                                  const Text('waiting', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          if (isServing) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () {
                                showPatientDoctorDetailsSheet(
                                  context,
                                  token: {
                                    'token_number': serving,
                                    'patient_name': servingName,
                                    'patient_age': servingAge,
                                    'relation': servingRelation,
                                    'account_phone': servingPhone,
                                    'priority': servingPriority,
                                    'priority_category': servingPriorityCat,
                                    'notes': servingNotes,
                                    'doctor_name': doctor,
                                    'qualification': qualification,
                                    'department_name': dept,
                                    'room': room,
                                    'availability_hours': timing,
                                    'status': 'serving',
                                  },
                                  doctor: queue,
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.success),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Serving: Token #$serving${servingName.isNotEmpty ? ' · $servingName' : ''}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success),
                                          ),
                                        ),
                                        const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.success),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${servingRelation.isNotEmpty ? servingRelation : 'Self'}${servingAge != null ? ' · $servingAge yrs' : ''}${servingPhone.isNotEmpty ? ' · 📞 $servingPhone' : ''}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    if (servingPriority || servingNotes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (servingPriority)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '⚠️ Priority${servingPriorityCat.isNotEmpty ? ': $servingPriorityCat' : ''}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning),
                                              ),
                                            ),
                                          if (servingNotes.isNotEmpty)
                                            Expanded(
                                              child: Text('Note: $servingNotes',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (doctorId == null)
                            const Text('Doctor id missing from server response.',
                                style: TextStyle(fontSize: 12, color: AppColors.error))
                          else
                            Row(
                              children: [
                                if (isServing) ...[
                                  Expanded(
                                    child: Obx(() => ElevatedButton.icon(
                                          onPressed: _busy.contains(doctorId) ? null : () => _completeCurrent(doctorId),
                                          icon: _busy.contains(doctorId)
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.check_circle_outline_rounded, size: 18),
                                          label: const Text('Complete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Obx(() => ElevatedButton.icon(
                                        onPressed: (_busy.contains(doctorId) || waitingCount == 0)
                                            ? null
                                            : () => _callNext(doctorId, doctorContext: queue),
                                        icon: _busy.contains(doctorId)
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.skip_next_rounded, size: 18),
                                        label: Text(isServing ? 'Next (#$waitingCount)' : 'Call next'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      )),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _openQueue(doctorId, doctor),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Icon(Icons.list_alt_rounded, size: 18),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.tealPrimary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          if (index == 0) Get.offNamed(AppRoutes.managerDashboard);
          if (index == 2) Get.offNamed(AppRoutes.doctorManagement);
          if (index == 3) Get.offNamed(AppRoutes.profile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Doctors'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tealPrimary, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _emptyState(String message) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
}

/// Per-doctor queue: serving / waiting / skipped lists with token actions.
class _DoctorQueueSheet extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String? date;
  const _DoctorQueueSheet({required this.doctorId, required this.doctorName, this.date});

  @override
  State<_DoctorQueueSheet> createState() => _DoctorQueueSheetState();
}

class _DoctorQueueSheetState extends State<_DoctorQueueSheet> {
  bool _loading = true;
  bool _acting = false;
  String _error = '';
  Map<String, dynamic> _queue = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _list(dynamic v) =>
      v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await ManagerApi.getQueueOverview(widget.doctorId, date: widget.date);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true && r['queue'] is Map) {
        _queue = Map<String, dynamic>.from(r['queue'] as Map);
      } else {
        _error = r['message']?.toString() ?? 'Could not load this queue.';
      }
    });
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    final r = await action();
    Get.snackbar(
      r['success'] == true ? 'Queue updated' : 'Action failed',
      r['message']?.toString() ?? (r['success'] == true ? 'Done' : 'Please try again.'),
      backgroundColor: r['success'] == true ? AppColors.successBg : AppColors.errorBg,
      colorText: r['success'] == true ? AppColors.textPrimary : AppColors.error,
    );
    if (mounted) setState(() => _acting = false);
    await _load();
  }

  int? _tid(Map<String, dynamic> t) => t['id'] is int ? t['id'] as int : int.tryParse('${t['id']}');

  String _who(Map<String, dynamic> t) {
    for (final k in ['patient_name', 'family_member_name', 'name', 'account_name']) {
      final v = t[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return 'Patient';
  }

  Future<void> _callNextFromSheet() async {
    if (_acting) return;
    setState(() => _acting = true);
    final r = await ManagerApi.callNext(widget.doctorId, date: widget.date);
    if (mounted) setState(() => _acting = false);
    if (r['success'] == true) {
      final token = r['token'] is Map ? Map<String, dynamic>.from(r['token'] as Map) : null;
      if (token != null && mounted) {
        showPatientDoctorDetailsSheet(context, token: token, doctor: _queue);
      } else {
        Get.snackbar(
          'Queue updated',
          r['message']?.toString() ?? 'Next patient called',
          backgroundColor: AppColors.successBg,
          colorText: AppColors.textPrimary,
        );
      }
    } else {
      Get.snackbar(
        'Action failed',
        r['message']?.toString() ?? 'Please try again.',
        backgroundColor: AppColors.errorBg,
        colorText: AppColors.error,
      );
    }
    await _load();
  }

  Widget _infoChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.tealPrimary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _tokenTile(Map<String, dynamic> t, List<Widget> actions, {bool isServing = false}) {
    final priority = t['priority'] == true || t['priority']?.toString() == 'true';
    final priorityCat = t['priority_category']?.toString() ?? '';
    final notes = t['notes']?.toString() ?? '';
    final phone = (t['account_phone'] ?? t['phone'] ?? '').toString();
    final age = t['patient_age'];
    final relation = (t['relation'] ?? '').toString();

    return InkWell(
      onTap: () => showPatientDoctorDetailsSheet(context, token: t, doctor: _queue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isServing ? AppColors.successBg : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isServing ? AppColors.success.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isServing ? AppColors.success.withValues(alpha: 0.2) : AppColors.tealLight,
                  child: Text('#${t['token_number'] ?? '?'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isServing ? AppColors.success : AppColors.tealPrimary,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _who(t),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isServing ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${relation.isNotEmpty ? relation : 'Self'}${age != null ? ' · $age yrs' : ''}${phone.isNotEmpty ? ' · 📞 $phone' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            if (priority || notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (priority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚠️ Priority${priorityCat.isNotEmpty ? ': $priorityCat' : ''}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning),
                      ),
                    ),
                  if (notes.isNotEmpty)
                    Text('Note: $notes',
                        style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, Color color, VoidCallback onTap) => IconButton(
        tooltip: tip,
        onPressed: _acting ? null : onTap,
        icon: Icon(icon, color: color),
        visualDensity: VisualDensity.compact,
      );

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          ...children,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final serving = _queue['now_serving'] is Map ? Map<String, dynamic>.from(_queue['now_serving'] as Map) : null;
    final waiting = _list(_queue['waiting']);
    final skipped = _list(_queue['skipped']);
    final qualification = (_queue['qualification'] ?? '').toString();
    final dept = (_queue['department_name'] ?? '').toString();
    final room = (_queue['room'] ?? '').toString();
    final timing = (_queue['availability_hours'] ?? '09:00 - 17:00').toString();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.doctorName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      if (qualification.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(qualification,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.tealPrimary)),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (dept.isNotEmpty) _infoChip(Icons.local_hospital_outlined, dept),
                          if (room.isNotEmpty) _infoChip(Icons.meeting_room_outlined, 'Room $room'),
                          _infoChip(Icons.access_time_rounded, timing),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh queue'),
              ],
            ),
            const Divider(height: 18),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, textAlign: TextAlign.center))
                      : ListView(
                          controller: scroll,
                          children: [
                            _section('Now serving', [
                              if (serving == null)
                                const Text('Nobody is being served.', style: TextStyle(color: AppColors.textSecondary))
                              else ...[
                                _tokenTile(
                                  serving,
                                  [
                                    _iconBtn(Icons.check_circle_rounded, 'Mark done (Stop)', AppColors.success,
                                        () => _run(() => ManagerApi.completeToken(_tid(serving)!))),
                                    _iconBtn(Icons.person_off_rounded, 'Skip (no-show)', AppColors.warning,
                                        () => _run(() => ManagerApi.skipToken(_tid(serving)!))),
                                  ],
                                  isServing: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _acting ? null : () => _run(() => ManagerApi.completeToken(_tid(serving)!)),
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                      label: const Text('Complete Consultation (Stop)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                            _section('Waiting (${waiting.length})', [
                              if (waiting.isEmpty)
                                const Text('No patients waiting.', style: TextStyle(color: AppColors.textSecondary))
                              else ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _acting ? null : _callNextFromSheet,
                                      icon: const Icon(Icons.skip_next_rounded, size: 18),
                                      label: Text('Call next (#${waiting.first['token_number']})'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ),
                                ...waiting.map((t) => _tokenTile(t, [
                                      _iconBtn(Icons.play_arrow_rounded, 'Call next', AppColors.primary,
                                          () => _callNextFromSheet()),
                                      _iconBtn(Icons.person_off_rounded, 'Skip', AppColors.warning,
                                          () => _run(() => ManagerApi.skipToken(_tid(t)!))),
                                      _iconBtn(Icons.cancel_rounded, 'Cancel token', AppColors.error,
                                          () => _run(() => ManagerApi.cancelToken(_tid(t)!))),
                                    ])),
                              ],
                            ]),
                            if (skipped.isNotEmpty)
                              _section('Skipped (${skipped.length})', [
                                ...skipped.map((t) => _tokenTile(t, [
                                      _iconBtn(Icons.undo_rounded, 'Put back in queue', AppColors.primary,
                                          () => _run(() => ManagerApi.recallToken(_tid(t)!))),
                                      _iconBtn(Icons.cancel_rounded, 'Cancel token', AppColors.error,
                                          () => _run(() => ManagerApi.cancelToken(_tid(t)!))),
                                    ])),
                              ]),
                            const SizedBox(height: 24),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comprehensive BottomSheet showing patient details and doctor details
void showPatientDoctorDetailsSheet(
  BuildContext context, {
  required Map<String, dynamic> token,
  Map<String, dynamic>? doctor,
}) {
  final tokenNum = token['token_number'] ?? token['number'] ?? '?';
  final patientName = token['patient_name'] ?? token['name'] ?? 'Patient';
  final patientAge = token['patient_age'];
  final relation = (token['relation'] ?? '').toString();
  final phone = (token['account_phone'] ?? token['phone'] ?? token['patient_phone'] ?? '').toString();
  final isPriority = token['priority'] == true || token['priority']?.toString() == 'true';
  final priorityCat = (token['priority_category'] ?? '').toString();
  final notes = (token['notes'] ?? '').toString();
  final status = (token['status'] ?? 'serving').toString();

  final docName = token['doctor_name'] ?? doctor?['doctor_name'] ?? doctor?['name'] ?? 'Doctor';
  final docQual = (token['qualification'] ?? doctor?['qualification'] ?? '').toString();
  final deptName = (token['department_name'] ?? doctor?['department_name'] ?? '').toString();
  final room = (token['room'] ?? doctor?['room'] ?? '—').toString();
  final timing = (token['availability_hours'] ?? doctor?['availability_hours'] ?? '09:00 - 17:00').toString();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(ctx).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tealPrimary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Token #$tokenNum',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'serving'
                          ? 'Now In Consultation'
                          : (status == 'waiting' ? 'Waiting in Queue' : 'Consultation Done'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: status == 'serving' ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status == 'serving' ? 'Patient called to doctor room' : 'Token status: $status',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Patient details card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_rounded, size: 18, color: AppColors.tealPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Patient Details',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _detailRow('Full Name', patientName.toString(), isBold: true),
                _detailRow('Relation & Age', '${relation.isNotEmpty ? relation : 'Self'}${patientAge != null ? ' · $patientAge years' : ''}'),
                if (phone.isNotEmpty)
                  _detailRow('Contact Phone', '📞 $phone'),
                if (isPriority)
                  _detailRow('Priority Status', '⚠️ ${priorityCat.isNotEmpty ? priorityCat : 'Priority Case'}', valueColor: AppColors.warning),
                if (notes.isNotEmpty)
                  _detailRow('Reason / Notes', '📝 $notes'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Doctor & room details card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_services_rounded, size: 18, color: AppColors.tealPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Doctor & Room Details',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _detailRow('Doctor', docName.toString(), isBold: true),
                if (docQual.isNotEmpty)
                  _detailRow('Qualification', docQual),
                if (deptName.isNotEmpty)
                  _detailRow('Department', deptName),
                _detailRow('Room Number', 'Room $room'),
                _detailRow('OPD Timings', '🕒 $timing'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close / Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _detailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
