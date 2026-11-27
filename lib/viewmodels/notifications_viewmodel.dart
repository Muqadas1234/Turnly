import 'package:get/get.dart';

import '../services/api_service.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      type: '${json['type'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      isRead: json['is_read'] == true,
      createdAt: (DateTime.tryParse('${json['created_at']}') ?? DateTime.now())
          .toLocal(),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

class NotificationsViewModel extends GetxController {
  final items = <AppNotification>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  int get unreadCount => items.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// [silent] refreshes in the background without a spinner or error banner.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      errorMessage.value = null;
    }
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true) {
        final list = (res['notifications'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        items.assignAll(list);
      } else if (!silent) {
        errorMessage.value =
            res['message']?.toString() ?? 'Could not load notifications.';
      }
    } catch (_) {
      if (!silent) {
        errorMessage.value =
        'Could not load notifications. Check your connection and try again.';
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    final i = items.indexWhere((x) => x.id == n.id);
    if (i != -1) items[i] = n.copyWith(isRead: true);
    try {
      final res = await ApiService.markNotificationRead(n.id);
      if (res['success'] != true) load(silent: true);
    } catch (_) {
      load(silent: true);
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    items.assignAll(items.map((n) => n.copyWith(isRead: true)).toList());
    try {
      final res = await ApiService.markAllNotificationsRead();
      if (res['success'] != true) load(silent: true);
    } catch (_) {
      load(silent: true);
    }
  }
}