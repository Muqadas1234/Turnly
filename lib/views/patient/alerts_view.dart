import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/notifications_viewmodel.dart';

/// Notification Center: today's and earlier queue/booking updates.
class AlertsView extends StatelessWidget {
  const AlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.put(NotificationsViewModel());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(vm: vm),
            Expanded(child: _Body(vm: vm)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  final NotificationsViewModel vm;
  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.chevron_left_rounded,
                    size: 24, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Obx(() {
            if (vm.unreadCount == 0) return const SizedBox.shrink();
            return Material(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: vm.markAllRead,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ body

class _Body extends StatelessWidget {
  final NotificationsViewModel vm;
  const _Body({required this.vm});

  @override
  Widget build(BuildContext context) => Obx(() => _content(context));

  Widget _content(BuildContext context) {
    final items = vm.items.toList();

    if (vm.isLoading.value && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tealPrimary),
      );
    }

    if (items.isEmpty) {
      final error = vm.errorMessage.value;
      return RefreshIndicator(
        color: AppColors.tealPrimary,
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            _MessageState(
              icon: error == null
                  ? Icons.notifications_none_rounded
                  : Icons.cloud_off_rounded,
              title: error == null ? 'No notifications yet' : 'Couldn’t load',
              message: error ??
                  'Booking confirmations and queue updates will show up here.',
              actionLabel: error == null ? null : 'Try again',
              onAction: vm.load,
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = items.where((n) => _isSameDay(n.createdAt, now)).toList();
    final earlier = items.where((n) => !_isSameDay(n.createdAt, now)).toList();

    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: vm.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (today.isNotEmpty) ...[
            const _SectionLabel('TODAY'),
            ...today.map((n) => _NotificationCard(n: n, vm: vm)),
          ],
          if (earlier.isNotEmpty) ...[
            const _SectionLabel('EARLIER'),
            ...earlier.map((n) => _NotificationCard(n: n, vm: vm)),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ card

class _NotificationCard extends StatelessWidget {
  final AppNotification n;
  final NotificationsViewModel vm;
  const _NotificationCard({required this.n, required this.vm});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(n.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            // unread = teal outline, read = plain grey outline
            color: n.isRead ? AppColors.border : AppColors.tealBorder,
            width: n.isRead ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, size: 20, color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeLabel(n.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    vm.markRead(n);

    // Queue/booking alerts open the patient's My Tokens tab.
    final isTokenAlert = n.type.startsWith('token_') ||
        n.type == 'turn_near' ||
        n.type.startsWith('priority_');
    if (isTokenAlert &&
        Get.isRegistered<NotificationService>() &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      Get.find<NotificationService>().pendingTab.value = 1;
    }
  }
}

// ----------------------------------------------------------- empty/error

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.tealPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealPrimary,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- helpers

class _IconStyle {
  final IconData icon;
  final Color color;
  final Color background;
  const _IconStyle(this.icon, this.color, this.background);
}

/// Icon + colours per notification type (types come from the backend notify.js).
_IconStyle _styleFor(String type) {
  switch (type) {
    case 'token_called':
      return const _IconStyle(
          Icons.notifications_none_rounded, AppColors.success, AppColors.successBg);
    case 'turn_near':
      return const _IconStyle(
          Icons.access_time_rounded, AppColors.warning, AppColors.suspendedBg);
    case 'token_booked':
      return const _IconStyle(Icons.confirmation_number_outlined,
          AppColors.tealPrimary, AppColors.tealLight);
    case 'token_completed':
    case 'priority_approved':
    case 'hospital_approved':
      return const _IconStyle(
          Icons.check_rounded, AppColors.success, AppColors.successBg);
    case 'token_cancelled':
    case 'priority_rejected':
    case 'hospital_rejected':
      return const _IconStyle(
          Icons.close_rounded, AppColors.error, AppColors.errorBg);
    case 'token_skipped':
      return const _IconStyle(
          Icons.person_off_outlined, AppColors.adminOrange, AppColors.suspendedBg);
    case 'hospital_suspended':
      return const _IconStyle(
          Icons.pause_circle_outline_rounded, AppColors.warning, AppColors.suspendedBg);
    default:
      return const _IconStyle(
          Icons.notifications_none_rounded, AppColors.tealPrimary, AppColors.tealLight);
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 2m, 18m, 1h for today; "10 Nov" for earlier days.
String _timeLabel(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (_isSameDay(t, now)) {
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
  return '${t.day} ${_months[t.month - 1]}';
}