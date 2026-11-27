import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_stepper/easy_stepper.dart';
import '../../utils/app_colors.dart';
import '../../utils/token_display.dart';
import '../../viewmodels/patient_viewmodel.dart';
import '../../widgets/custom_button.dart';

/// Live queue tracking for one token.
/// [token] is the map from the My Tokens list. When omitted (e.g. opened via
/// the named route) the patient's current active token is used.
class MyTokenView extends StatefulWidget {
  final Map<String, dynamic>? token;
  const MyTokenView({super.key, this.token});

  @override
  State<MyTokenView> createState() => _MyTokenViewState();
}

class _MyTokenViewState extends State<MyTokenView> {
  late final PatientViewModel _vm;
  Timer? _poll;
  Map<String, dynamic>? _snapshot;

  @override
  void initState() {
    super.initState();
    _vm = Get.find<PatientViewModel>();
    _snapshot = widget.token ?? _vm.activeToken.value;
    _vm.fetchActiveToken();
    // Live polling for rapid real-time updates while this view is active
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  int? get _id => _snapshot == null ? null : TokenInfo(_snapshot!).id;

  Future<void> _tick() async {
    await _vm.fetchActiveToken();
    // Token left the active list (completed / cancelled / skipped): ask the
    // API for its final state so the screen shows the real status.
    final id = _id;
    if (id != null && !_vm.activeTokens.any((m) => TokenInfo(m).id == id)) {
      try {
        final res = await _vm.fetchTokenDetail(id);
        final data = res['token'] ?? res['data'];
        if (res['success'] == true && data is Map && mounted) {
          setState(() => _snapshot = Map<String, dynamic>.from(data));
        }
      } catch (_) {}
    }
  }

  TokenInfo? _current() {
    final id = _id;
    if (id != null) {
      for (final m in _vm.activeTokens) {
        if (TokenInfo(m).id == id) {
          _snapshot = m;
          return TokenInfo(m);
        }
      }
    } else if (_vm.activeTokens.isNotEmpty) {
      _snapshot = _vm.activeTokens.first;
    }
    return _snapshot == null ? null : TokenInfo(_snapshot!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text('Live Queue Tracking',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Obx(() {
        // Touch the observable so this rebuilds whenever the list refreshes.
        final observed = _vm.activeTokens.length; // subscribes Obx to list changes
        if (observed < 0) return const SizedBox.shrink();
        final t = _current();
        if (t == null) {
          return _vm.isLoadingTokens.value
              ? const Center(child: CircularProgressIndicator())
              : const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No token to track right now.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _tick,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _mainCard(t),
                const SizedBox(height: 16),
                _metrics(t),
                const SizedBox(height: 16),
                _stepper(t),
                if (t.phase == TokenPhase.serving) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0F9D58).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded, color: Color(0xFF0F9D58), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('It’s Your Turn!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F9D58))),
                              SizedBox(height: 2),
                              Text('You are currently being served. Please proceed to the doctor’s room.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (t.phase == TokenPhase.done) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Consultation Completed',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                              SizedBox(height: 2),
                              Text('Your consultation has ended. Thank you for using Turnly!',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (t.canCancel) ...[
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Cancel Token',
                    height: 48,
                    backgroundColor: AppColors.errorBg,
                    textColor: AppColors.error,
                    onPressed: () => _confirmCancel(t),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _mainCard(TokenInfo t) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: t.statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              t.phase == TokenPhase.waiting ? 'WAITING IN QUEUE' : t.statusLabel.toUpperCase(),
              style: TextStyle(color: t.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const Text('YOUR TOKEN NUMBER',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(t.numberLabel,
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
          const SizedBox(height: 12),
          Text(t.doctor,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            t.department.isEmpty ? t.hospital : '${t.department} · ${t.hospital}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(t.patientLine, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _metrics(TokenInfo t) {
    final serving = t.phase == TokenPhase.serving;
    final aheadText = serving ? '0' : (t.ahead?.toString() ?? '—');
    final waitText = serving ? 'Now' : (t.waitMinutes == null ? '—' : '~${t.waitMinutes} mins');
    final nowServing = t.nowServing == null ? '—' : '#${t.nowServing}';
    return Column(
      children: [
        Row(children: [
          _metric('Now Serving', serving ? t.numberLabel : nowServing),
          const SizedBox(width: 12),
          _metric('Patients Ahead', aheadText, color: AppColors.adminPrimary),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _metric('Approx Wait', waitText),
          const SizedBox(width: 12),
          _metric('Date', t.dateLabel.isEmpty ? '—' : t.dateLabel),
        ]),
      ],
    );
  }

  Widget _stepper(TokenInfo t) {
    final active = t.stepIndex;
    const titles = ['Booked', 'Waiting', 'Serving', 'Done'];

    Widget dot(int i) {
      if (i < active) {
        return const CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.adminPrimary,
          child: Icon(Icons.check, size: 16, color: AppColors.surface),
        );
      }
      if (i == active) {
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.adminPrimary, width: 2.5),
          ),
          child: const Center(
            child: CircleAvatar(radius: 4, backgroundColor: AppColors.adminPrimary),
          ),
        );
      }
      return const CircleAvatar(radius: 13, backgroundColor: AppColors.border);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          EasyStepper(
            activeStep: active,
            stepRadius: 13,
            showStepBorder: false,
            showLoadingAnimation: false,
            titlesAreLargerThanSteps: true,
            lineStyle: const LineStyle(
              lineLength: 48,
              lineThickness: 2.5,
              lineType: LineType.normal,
              defaultLineColor: AppColors.border,
              finishedLineColor: AppColors.adminPrimary,
            ),
            steps: [
              for (var i = 0; i < titles.length; i++) EasyStep(customStep: dot(i), title: titles[i]),
            ],
          ),
          if (t.phase == TokenPhase.cancelled || t.phase == TokenPhase.skipped)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('This token was ${t.statusLabel.toLowerCase()}.',
                  style: TextStyle(fontSize: 12, color: t.statusColor)),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(TokenInfo t) {
    final id = t.id;
    if (id == null) return;
    Get.defaultDialog(
      title: 'Cancel Token',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      middleText: 'Are you sure you want to cancel token ${t.numberLabel}?',
      textConfirm: 'Yes, Cancel',
      textCancel: 'Keep Token',
      confirmTextColor: AppColors.surface,
      buttonColor: AppColors.error,
      cancelTextColor: AppColors.textSecondary,
      onConfirm: () async {
        Get.back();
        final res = await _vm.cancelToken(id);
        final ok = res['success'] == true;
        Get.snackbar(
          ok ? 'Token Cancelled' : 'Could not cancel',
          ok
              ? 'Token ${t.numberLabel} has been cancelled.'
              : (res['message']?.toString() ?? 'Please try again.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          colorText: AppColors.surface,
        );
        if (ok) Get.back();
      },
    );
  }
}
