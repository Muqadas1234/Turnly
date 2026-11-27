import 'dart:async';
import '../viewmodels/notifications_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/routes.dart';
import 'api_service.dart';

/// Push notifications (FCM) for Android, iOS and Web.
///
/// Web needs the VAPID key from Firebase Console > Project settings > Cloud
/// Messaging > Web Push certificates, passed at build time:
///   flutter run -d chrome --dart-define=FCM_VAPID_KEY=<key>
class NotificationService extends GetxService {
  static const String _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  /// firebase_messaging has no Windows/Linux implementation.
  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Patient HomeView tab requested by a notification tap (1 = My Tokens).
  final pendingTab = RxnInt();

  final List<StreamSubscription> _subs = [];
  bool _started = false;

  /// True only when FCM can really run here: supported platform, Firebase initialised,
  /// web has a VAPID key, and the browser/environment supports messaging.
  static Future<bool> _canUseFcm() async {
    if (!isSupported) return false;
    if (kIsWeb && _vapidKey.isEmpty) return false;
    if (Firebase.apps.isEmpty) return false;
    try {
      return await FirebaseMessaging.instance.isSupported();
    } catch (_) {
      return false;
    }
  }

  /// Current device token (null if unsupported / permission denied / no VAPID key).
  static Future<String?> fetchToken() async {
    if (!isSupported) return null;
    try {
      if (kIsWeb && _vapidKey.isEmpty) {
        debugPrint('FCM: FCM_VAPID_KEY not set - web push token unavailable');
        return null;
      }
      return await FirebaseMessaging.instance
          .getToken(vapidKey: kIsWeb ? _vapidKey : null);
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  /// Call once the user is logged in (any role). Safe to call repeatedly.
  Future<void> start({
    required Future<void> Function(String token) onTokenReady,
  }) async {
    if (!isSupported || _started) return;
    _started = true;
    try {
      if (!await _canUseFcm()) {
        debugPrint('FCM: skipped (unsupported here, Firebase not ready, or web without FCM_VAPID_KEY)');
        _started = false;
        return;
      }
      final fcm = FirebaseMessaging.instance;
      final settings = await fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        debugPrint('FCM: notification permission denied');
        _started = false; // ask again next time (e.g. after next login)
        return;
      }

      // iOS: foreground notifications are silent unless this is enabled.
      await fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await fetchToken();
      debugPrint('***************************************FCM TOKEN: $token ******************************************');
      if (token != null) await onTokenReady(token);

      _subs.add(fcm.onTokenRefresh.listen(onTokenReady));

      // Foreground: Android/Web show nothing by themselves, so show a banner.
      _subs.add(FirebaseMessaging.onMessage.listen((message) {
        // keep the Notifications screen current if it is open
        if (Get.isRegistered<NotificationsViewModel>()) {
          Get.find<NotificationsViewModel>().load(silent: true);
        }
        final n = message.notification;
        if (n == null) return;
        Get.snackbar(
          n.title ?? 'Turnly',
          n.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          onTap: (_) => _handleTap(message),
        );
      }));

      // Background -> tap
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_handleTap));

      // Terminated -> tap
      final initial = await fcm.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (e) {
      debugPrint('FCM start error: $e');
      _started = false;
    }
  }

  /// Logout: stop pushes to this device and drop the Firebase token.
  /// Must run BEFORE the JWT is cleared.
  Future<void> stopAndUnregister() async {
    for (final s in _subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    _subs.clear();
    _started = false;
    if (!await _canUseFcm()) return; // nothing was registered, nothing to remove
    try {
      final token = await fetchToken();
      if (token != null) {
        await ApiService.removeFcmToken(fcmToken: token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('FCM unregister error: $e');
    }
  }

  /// Routes by the `type` the backend sends (services/notify.js).
  void _handleTap(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    if (type.startsWith('token_') ||
        type == 'turn_near' ||
        type.startsWith('priority_')) {
      pendingTab.value = 1; // patient: My Tokens tab
      if (Get.currentRoute != AppRoutes.home &&
          Get.currentRoute != AppRoutes.splash) {
        Get.offAllNamed(AppRoutes.home);
      }
    } else if (type.startsWith('hospital_')) {
      // manager: splash re-checks auth and routes by hospital status
      Get.offAllNamed(AppRoutes.splash);
    } else {
      Get.toNamed(AppRoutes.alerts);
    }
  }
}