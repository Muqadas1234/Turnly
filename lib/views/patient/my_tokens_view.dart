import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../utils/token_display.dart';
import '../../viewmodels/patient_viewmodel.dart';
import '../../widgets/custom_button.dart';
import 'my_token_view.dart';

class MyTokensView extends StatefulWidget {
  const MyTokensView({super.key});

  @override
  State<MyTokensView> createState() => _MyTokensViewState();
}

class _MyTokensViewState extends State<MyTokensView> {
  late final PatientViewModel _vm;
  Timer? _poll;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _vm = Get.find<PatientViewModel>();
    _refresh();
    // Live polling for rapid real-time updates
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _vm.fetchTokens(scope: 'active'),
      _vm.fetchTokens(scope: 'history'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My tokens',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _buildSegmented(),
                const SizedBox(height: 20),
                Obx(() {
                  final loading = _vm.isLoadingTokens.value;
                  final active = _vm.activeTokens.map((m) => TokenInfo(m)).toList();
                  final history = _vm.historyTokens.map((m) => TokenInfo(m)).toList();

                  if (_selectedTab == 0) {
                    if (active.isEmpty) {
                      return loading ? _loader() : _buildEmptyState();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final t in active) ...[
                          _buildActiveTokenCard(t),
                          const SizedBox(height: 16),
                        ],
                        if (history.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Recent history',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          for (final t in history.take(3)) ...[
                            _buildHistoryItem(t),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    );
                  }

                  if (history.isEmpty) {
                    return loading
                        ? _loader()
                        : const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text('No past tokens yet',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final t in history) ...[
                        _buildHistoryItem(t),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Padding(
    padding: EdgeInsets.only(top: 80),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _buildSegmented() {
    Widget label(int i, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: _selectedTab == i ? FontWeight.bold : FontWeight.w500,
            color: _selectedTab == i ? AppColors.textPrimary : AppColors.textSecondary,
          )),
    );
    return CustomSlidingSegmentedControl<int>(
      initialValue: _selectedTab,
      isStretch: true,
      children: {0: label(0, 'Active'), 1: label(1, 'History')},
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      thumbDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      onValueChanged: (v) => setState(() => _selectedTab = v),
    );
  }

  Widget _buildActiveTokenCard(TokenInfo t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.numberLabel,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.adminPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: t.statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(t.statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.doctorLine,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(t.patientLine, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _iconLine(Icons.location_on_outlined, t.hospital),
          const SizedBox(height: 6),
          _iconLine(Icons.access_time_outlined, t.queueInfo),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Track live',
                  height: 42,
                  backgroundColor: AppColors.adminPrimaryLight,
                  textColor: AppColors.adminPrimaryDark,
                  onPressed: () => Get.to(() => MyTokenView(token: t.raw)),
                ),
              ),
              if (t.canCancel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Cancel',
                    height: 42,
                    backgroundColor: AppColors.errorBg,
                    textColor: AppColors.error,
                    onPressed: () => _confirmCancel(t),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
    ],
  );

  Widget _buildHistoryItem(TokenInfo t) {
    final isDone = t.phase == TokenPhase.done;
    final date = t.dateLabel.isEmpty ? '' : '${t.dateLabel} · ';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: t.statusBg, shape: BoxShape.circle),
            child: Icon(isDone ? Icons.check : Icons.close, color: t.statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.doctorLine,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text('$date${t.hospital} · Token ${t.numberLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: t.statusBg, borderRadius: BorderRadius.circular(12)),
            child: Text(t.statusLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 70),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: AppColors.adminPrimaryLight, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.confirmation_number_outlined, size: 44, color: AppColors.adminPrimary),
        ),
        const SizedBox(height: 24),
        const Text('No active tokens',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Book a token from home and skip the waiting room. Your live queue position will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 80),
        CustomButton(
          label: 'Find a hospital',
          height: 48,
          backgroundColor: AppColors.adminPrimary,
          textColor: AppColors.surface,
          onPressed: () => Get.offAllNamed(AppRoutes.home),
        ),
        const SizedBox(height: 20),
      ],
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
        if (ok) _vm.fetchTokens(scope: 'history');
      },
    );
  }
}
