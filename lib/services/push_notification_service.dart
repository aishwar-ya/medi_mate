import 'dart:io' show Platform; // Used to check if running on Android/iOS
import 'package:flutter/foundation.dart' show kIsWeb; // Used to check if running on Web
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medi_mate/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      NotificationService.notificationsPlugin;

  static Future<void> init() async {
    print("🚀 Initializing PushNotificationService...");

    // ✅ Request permission (works on web, Android, iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('⚠️ User declined or has not accepted permission');
    }

    // ✅ Get FCM token (useful for testing web push)
    String? token = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $token');

    // ✅ Handle messages when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');
      if (!kIsWeb) {
        _showNotification(message);
      } else {
        print('🌐 Web message received (handled by service worker).');
      }
    });

    // ✅ Handle when app is opened from a terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🟢 App opened from notification: ${message.notification?.title}');
      // Handle navigation or any specific action if needed
    });

    // ✅ Background messages — only for Android/iOS
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    print("✅ PushNotificationService initialized successfully.");
  }

  // Handle background notifications (Android/iOS)
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('🌙 Handling background message: ${message.notification?.title}');
  }

  // Display notification (mobile only)
  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'push_channel',
      'Push Notifications',
      channelDescription: 'Notifications from Firebase',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new notification',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Get FCM token (can be used to send test messages)
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}