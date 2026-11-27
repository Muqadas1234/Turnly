import 'package:flutter/material.dart';
import 'app_colors.dart';

enum TokenPhase { waiting, serving, done, cancelled, skipped }

/// Read-only view over a token map returned by the Turnly API.
/// Accepts several key spellings so small backend naming differences
/// do not break the screens.
class TokenInfo {
  final Map<String, dynamic> raw;
  const TokenInfo(this.raw);

  String _s(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = raw[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }

  int? _i(List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v == null) continue;
      final n = int.tryParse(v.toString());
      if (n != null) return n;
      final d = double.tryParse(v.toString());
      if (d != null) return d.round();
    }
    return null;
  }

  int? get id => _i(['id', 'token_id', 'tokenId']);
  int get number => _i(['token_number', 'tokenNumber', 'number']) ?? 0;
  String get numberLabel => '#$number';

  String get doctor => _s(['doctor_name', 'doctorName'], 'Doctor');
  String get department => _s(['department_name', 'departmentName', 'specialization', 'specialty']);
  String get hospital => _s(['hospital_name', 'hospitalName'], 'Hospital');
  int? get ahead => _i(['ahead_count', 'aheadCount']);
  int? get waitMinutes => _i(['estimated_wait_minutes', 'eta_minutes', 'etaMinutes']);
  int? get nowServing => _i(['now_serving', 'nowServing', 'current_token']);

  String get doctorLine => department.isEmpty ? doctor : '$doctor · $department';

  String get patientLine {
    final name = _s(['family_member_name', 'familyMemberName', 'patient_name', 'patientName']);
    final relation = _s(['family_member_relation', 'relation']);
    if (name.isEmpty) return 'For you';
    return relation.isEmpty ? 'For $name' : 'For $name ($relation)';
  }

  TokenPhase get phase {
    final s = _s(['status']).toLowerCase();
    if (s.contains('cancel')) return TokenPhase.cancelled;
    if (s.contains('skip')) return TokenPhase.skipped;
    if (s.contains('complet') || s == 'done') return TokenPhase.done;
    if (s.contains('call') || s.contains('serv') || s.contains('progress')) {
      return TokenPhase.serving;
    }
    return TokenPhase.waiting;
  }

  bool get isActive => phase == TokenPhase.waiting || phase == TokenPhase.serving;
  bool get canCancel => phase == TokenPhase.waiting;

  /// 0 Booked, 1 Waiting, 2 Serving, 3 Done
  int get stepIndex {
    switch (phase) {
      case TokenPhase.waiting:
        return 1;
      case TokenPhase.serving:
        return 2;
      case TokenPhase.done:
        return 3;
      default:
        return 1;
    }
  }

  String get statusLabel {
    switch (phase) {
      case TokenPhase.waiting:
        return 'Waiting';
      case TokenPhase.serving:
        return 'Serving';
      case TokenPhase.done:
        return 'Done';
      case TokenPhase.cancelled:
        return 'Cancelled';
      case TokenPhase.skipped:
        return 'Skipped';
    }
  }

  Color get statusColor {
    switch (phase) {
      case TokenPhase.waiting:
        return AppColors.adminPrimaryDark;
      case TokenPhase.serving:
        return AppColors.adminBlue;
      case TokenPhase.done:
        return AppColors.success;
      case TokenPhase.cancelled:
        return AppColors.error;
      case TokenPhase.skipped:
        return AppColors.warning;
    }
  }

  Color get statusBg {
    switch (phase) {
      case TokenPhase.waiting:
        return AppColors.adminPrimaryLight;
      case TokenPhase.serving:
        return AppColors.adminBlueBg;
      case TokenPhase.done:
        return AppColors.successBg;
      case TokenPhase.cancelled:
        return AppColors.errorBg;
      case TokenPhase.skipped:
        return AppColors.warningBg;
    }
  }

  DateTime? get _date {
    final s = _s(['booking_date', 'date', 'appointment_date']);
    if (s.length < 10) return null;
    return DateTime.tryParse(s.substring(0, 10));
  }

  /// "Today" or "24 Nov" (empty if the API gave no date).
  String get dateLabel {
    final d = _date;
    if (d == null) return '';
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  /// One-line summary for the list card.
  String get queueInfo {
    final parts = <String>[];
    if (dateLabel.isNotEmpty) parts.add(dateLabel);
    if (phase == TokenPhase.serving) {
      parts.add('Being served now');
    } else if (phase == TokenPhase.waiting) {
      final a = ahead;
      final w = waitMinutes;
      if (a != null) parts.add('$a patient${a == 1 ? '' : 's'} ahead');
      if (w != null) parts.add('~$w min');
    }
    return parts.isEmpty ? statusLabel : parts.join(' · ');
  }
}
