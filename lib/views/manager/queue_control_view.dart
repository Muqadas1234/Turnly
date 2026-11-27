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

  String _tokenFilter = 'all'; // all, waiting, serving, done

  List<Map<String, dynamic>> get _filteredTokens {
    if (_tokenFilter == 'waiting') {
      return vm.todayTokens.where((t) => (t['status'] ?? 'waiting') == 'waiting').toList();
    }
    if (_tokenFilter == 'serving') {
      return vm.todayTokens.where((t) => t['status'] == 'serving').toList();
    }
    if (_tokenFilter == 'done') {
      return vm.todayTokens.where((t) => t['status'] == 'done').toList();
    }
    return vm.todayTokens;
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _tokenFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _tokenFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.tealPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _metricBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _completeToken(int tokenId) async {
    try {
      _toast(await ManagerApi.completeToken(tokenId), ok: 'Consultation marked as completed');
    } finally {
      await vm.fetchDashboard(date: _dateString);
    }
  }

  Future<void> _skipToken(int tokenId) async {
    try {
      _toast(await ManagerApi.skipToken(tokenId), ok: 'Token skipped');
    } finally {
      await vm.fetchDashboard(date: _dateString);
    }
  }

  Widget _patientTokenCard(Map<String, dynamic> token) {
    final tokenId = _id(token['id']);
    final doctorId = _id(token['doctor_id']);
    final tokenNum = token['token_number'] ?? '?';
    final patientName = (token['patient_name'] ?? 'Patient').toString();
    final patientAge = token['patient_age'];
    final relation = (token['relation'] ?? '').toString();
    final phone = (token['account_phone'] ?? token['phone'] ?? '').toString();
    final isPriority = token['priority'] == true || token['priority']?.toString() == 'true' || token['priority'] == 1;
    final priorityCat = (token['priority_category'] ?? '').toString();
    final notes = (token['notes'] ?? '').toString();
    final status = (token['status'] ?? 'waiting').toString();

    final docName = (token['doctor_name'] ?? 'Doctor').toString();
    final docQual = (token['qualification'] ?? '').toString();
    final deptName = (token['department_name'] ?? '').toString();
    final room = (token['room'] ?? '—').toString();
    final timing = (token['availability_hours'] ?? '09:00 - 17:00').toString();

    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'serving') {
      statusBg = AppColors.successBg;
      statusColor = AppColors.success;
      statusLabel = 'Serving';
      statusIcon = Icons.record_voice_over_rounded;
    } else if (status == 'waiting') {
      statusBg = const Color(0xFFFFF8E1);
      statusColor = const Color(0xFFF57C00);
      statusLabel = 'Waiting';
      statusIcon = Icons.schedule_rounded;
    } else if (status == 'done') {
      statusBg = AppColors.border.withValues(alpha: 0.5);
      statusColor = AppColors.textSecondary;
      statusLabel = 'Done';
      statusIcon = Icons.check_circle_outline_rounded;
    } else {
      statusBg = AppColors.errorBg;
      statusColor = AppColors.error;
      statusLabel = status.capitalizeFirst ?? status;
      statusIcon = Icons.info_outline_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: status == 'serving' ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          width: status == 'serving' ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => showPatientDoctorDetailsSheet(context, token: token, doctor: token),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Token #, Patient name, Status badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: status == 'serving' ? AppColors.successBg : AppColors.tealLight,
                    child: Text(
                      '#$tokenNum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: status == 'serving' ? AppColors.success : AppColors.tealPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${relation.isNotEmpty ? relation : 'Self'}${patientAge != null ? ' · $patientAge yrs' : ''}${phone.isNotEmpty ? ' · 📞 $phone' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Doctor & Room container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_rounded, size: 16, color: AppColors.tealPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$docName${docQual.isNotEmpty ? ' ($docQual)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${deptName.isNotEmpty ? '$deptName · ' : ''}Room $room · 🕒 $timing',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),

              // Priority & Notes
              if (isPriority || notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (isPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '⚠️ Priority${priorityCat.isNotEmpty ? ': $priorityCat' : ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                        ),
                      ),
                    if (notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Note: $notes',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ],

              // Actions
              if (status == 'waiting' && doctorId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callNext(doctorId, doctorContext: token),
                        icon: const Icon(Icons.record_voice_over_rounded, size: 16),
                        label: const Text('Call Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                    if (tokenId != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _skipToken(tokenId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ],
                ),
              ] else if (status == 'serving' && tokenId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completeToken(tokenId),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Complete Consultation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _skipToken(tokenId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
              // 4 Summary Metrics in a single modern row
              Row(
                children: [
                  Expanded(child: _metricBadge('Booked', '${vm.todayTokens.length}', Icons.confirmation_num_outlined, AppColors.tealPrimary)),
                  const SizedBox(width: 8),
                  Expanded(child: _metricBadge('Waiting', '${vm.todayTokens.where((t) => (t['status'] ?? 'waiting') == 'waiting').length}', Icons.schedule_rounded, const Color(0xFFF57C00))),
                  const SizedBox(width: 8),
                  Expanded(child: _metricBadge('In Room', '${vm.todayTokens.where((t) => t['status'] == 'serving').length}', Icons.record_voice_over_rounded, AppColors.success)),
                  const SizedBox(width: 8),
                  Expanded(child: _metricBadge('Done', '${vm.todayTokens.where((t) => t['status'] == 'done').length}', Icons.check_circle_outline_rounded, AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 16),
              // Section Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateUtils.isSameDay(_selectedDate, DateTime.now())
                              ? 'Today’s Patient Appointments'
                              : 'Appointments for ${DateFormat('d MMM yyyy').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Each card has patient details, assigned doctor & call controls',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', 'All (${vm.todayTokens.length})'),
                    const SizedBox(width: 6),
                    _filterChip('waiting', 'Waiting (${vm.todayTokens.where((t) => (t['status'] ?? 'waiting') == 'waiting').length})'),
                    const SizedBox(width: 6),
                    _filterChip('serving', 'In Room (${vm.todayTokens.where((t) => t['status'] == 'serving').length})'),
                    const SizedBox(width: 6),
                    _filterChip('done', 'Completed (${vm.todayTokens.where((t) => t['status'] == 'done').length})'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Unified Token Cards List
              if (_filteredTokens.isEmpty)
                _emptyState('No appointments found for this date. When patients book tokens, they will appear here with complete patient and doctor details.')
              else
                ..._filteredTokens.map((token) => _patientTokenCard(token)),

              const SizedBox(height: 14),
              // Collapsible Doctor OPD Directory at the bottom
              if (vm.todayQueues.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.medical_services_outlined, color: AppColors.tealPrimary),
                      title: Text(
                        'Doctors & Rooms Directory (${vm.todayQueues.length} Doctors)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'View room numbers & OPD timings for all hospital doctors',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      children: [
                        const Divider(height: 1),
                        ...vm.todayQueues.map((queue) {
                          final doctorId = _id(queue['id'] ?? queue['doctor_id']);
                          final doctor = _value(queue, ['name', 'doctor_name'], fallback: 'Doctor');
                          final room = _value(queue, ['room']);
                          final dept = _value(queue, ['department_name'], fallback: '');
                          final timing = _value(queue, ['availability_hours'], fallback: '09:00 - 17:00');
                          final waiting = _value(queue, ['waiting'], fallback: '0');

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.tealLight,
                              child: Text(
                                doctor.isNotEmpty ? doctor.substring(0, 1) : 'D',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
                              ),
                            ),
                            title: Text(doctor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(
                              '${dept.isNotEmpty ? '$dept · ' : ''}Room $room · 🕒 $timing',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            trailing: doctorId != null
                                ? OutlinedButton(
                                    onPressed: () => _openQueue(doctorId, doctor),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: Text('Queue ($waiting)', style: const TextStyle(fontSize: 11)),
                                  )
                                : null,
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
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
