import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'package:timezone/timezone.dart' as tz;

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:logger/logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart'; // ✨ ADD THIS

class NotificationService {
  static final Logger _logger = Logger();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service

  static Future<void> init() async {
    try {
      _logger.i('🔔 Initializing NotificationService...');

      // Initialize timezones

      tz.initializeTimeZones();

      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      _logger.i('✅ Timezone set to Asia/Kolkata');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      final initialized = await notificationsPlugin.initialize(
        settings,

        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          _logger.i('📨 Notification tapped: ${response.payload}');

          if (response.payload != null && response.payload!.isNotEmpty) {
            await speakNotification(response.payload!);

            // ✨ NEW: Reduce stock when user taps notification

            await _handleNotificationResponse(response);
          }
        },
      );

      if (initialized == true) {
        _logger.i('✅ Notifications plugin initialized successfully');
      }

      await _requestPermissions();

      await _testNotificationSystem();
    } catch (e, stackTrace) {
      _logger.e('❌ Error initializing NotificationService: $e');

      _logger.e('Stack trace: $stackTrace');
    }
  }

  // ✨ NEW: Handle notification response and reduce stock

  static Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      // Extract medication ID from notification ID

      // Format: medicationId  100 + index

      int notificationId = response.id ?? 0;

      int medicationId = notificationId ~/ 100; // Get medication ID

      if (medicationId > 0) {
        _logger.i('💊 Reducing stock for medication ID: $medicationId');

        await _reduceStock(medicationId);
      }
    } catch (e) {
      _logger.e('❌ Error handling notification response: $e');
    }
  }

  // ✨ NEW: Reduce stock by 1

  static Future<void> _reduceStock(int medicationId) async {
    try {
      final supabase = Supabase.instance.client;

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _logger.w('⚠️ No user logged in, cannot reduce stock');

        return;
      }

      // Get current stock

      final response =
          await supabase
              .from('medications')
              .select('stock_quantity')
              .eq('id', medicationId)
              .eq('user_id', userId)
              .single();

      int currentStock = response['stock_quantity'] as int;

      if (currentStock > 0) {
        int newStock = currentStock - 1;

        // Update stock

        await supabase
            .from('medications')
            .update({'stock_quantity': newStock})
            .eq('id', medicationId)
            .eq('user_id', userId);

        _logger.i('✅ Stock reduced: $currentStock → $newStock');

        // ✨ Alert if stock is low

        if (newStock <= 5 && newStock > 0) {
          _logger.w('⚠️ LOW STOCK WARNING: Only $newStock pills remaining');

          await _showLowStockNotification(medicationId, newStock);
        } else if (newStock == 0) {
          _logger.e('❌ OUT OF STOCK!');

          await _showOutOfStockNotification(medicationId);
        }
      } else {
        _logger.w('⚠️ Stock already at 0, cannot reduce further');
      }
    } catch (e) {
      _logger.e('❌ Error reducing stock: $e');
    }
  }

  // ✨ NEW: Show low stock warning

  static Future<void> _showLowStockNotification(
    int medicationId,
    int remainingStock,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'stock_alert_channel_v2',

            'Stock Alerts',

            channelDescription: 'Alerts for low medication stock',

            importance: Importance.high,

            priority: Priority.high,

            playSound: true,

            enableVibration: true,
          );

      await notificationsPlugin.show(
        99990 + medicationId, // Unique ID for stock alerts

        '⚠️ Low Stock Alert',

        'Only $remainingStock pills remaining. Time to refill!',

        const NotificationDetails(android: androidDetails),
      );

      _logger.i('📢 Low stock notification sent');
    } catch (e) {
      _logger.e('❌ Error showing low stock notification: $e');
    }
  }

  // ✨ NEW: Show out of stock alert

  static Future<void> _showOutOfStockNotification(int medicationId) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'stock_alert_channel_v2',

            'Stock Alerts',

            channelDescription: 'Alerts for medication out of stock',

            importance: Importance.max,

            priority: Priority.high,

            playSound: true,

            enableVibration: true,
          );

      await notificationsPlugin.show(
        99980 + medicationId, // Unique ID for out of stock alerts

        '❌ Out of Stock!',

        'Medication is out of stock. Please refill immediately!',

        const NotificationDetails(android: androidDetails),
      );

      _logger.i('📢 Out of stock notification sent');
    } catch (e) {
      _logger.e('❌ Error showing out of stock notification: $e');
    }
  }

  static Future<void> _testNotificationSystem() async {
    try {
      final pendingNotifications =
          await notificationsPlugin.pendingNotificationRequests();

      _logger.i(
        '📋 Currently ${pendingNotifications.length} pending notifications',
      );

      for (var notification in pendingNotifications) {
        _logger.d('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      _logger.e('❌ Error testing notification system: $e');
    }
  }

  /// Speak the notification message aloud

  static Future<void> speakNotification(String message) async {
    try {
      _logger.i('═══════════════════════════════════════');

      _logger.i('🔊 STARTING TTS (Text-to-Speech)');

      _logger.i('═══════════════════════════════════════');

      _logger.i('📝 Message to speak: "$message"');

      final FlutterTts tts = FlutterTts();

      tts.setErrorHandler((msg) {
        _logger.e('❌ TTS ERROR: $msg');
      });

      tts.setCompletionHandler(() {
        _logger.i('✅ TTS COMPLETED: Speaking finished!');
      });

      tts.setStartHandler(() {
        _logger.i('🎤 TTS STARTED: Engine started speaking!');
      });

      _logger.i('⚙️ Configuring TTS...');

      await tts.setLanguage("en-IN");

      await tts.setPitch(1.0);

      await tts.setSpeechRate(0.6);

      await tts.setVolume(1.0);

      _logger.i('🔊 CALLING TTS.SPEAK()...');

      final result = await tts.speak(message);

      if (result == 1) {
        _logger.i('✅ SUCCESS! Voice is playing now 🔊');
      } else {
        _logger.e('❌ FAILED! TTS returned: $result');
      }

      _logger.i('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      _logger.e('❌ EXCEPTION IN TTS: $e');

      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// Schedule a daily notification at a specific time (HH:mm)

  /// ALSO schedules automatic voice to play at the same time

  static Future<void> scheduleDailyNotification({
    required int id,

    required String title,

    required String body,

    required String timeStr,
  }) async {
    try {
      _logger.i('⏰ Scheduling notification ID: $id');

      _logger.d('   Title: $title');

      _logger.d('   Body: $body');

      _logger.d('   Time: $timeStr');

      final parts = timeStr.split(':');

      if (parts.length != 2) {
        throw Exception('Invalid time format. Expected HH:mm, got: $timeStr');
      }

      final hour = int.parse(parts[0]);

      final minute = int.parse(parts[1]);

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      _logger.i('   📅 Will trigger at: $scheduledTime');

      _logger.i(
        '   ⏱️ That is in: ${scheduledTime.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes',
      );

      String medicationName = body
          .replaceAll('Time to take ', '')
          .replaceAll('time to take ', '');

      String voiceMessage = "It's time to take $medicationName";

      _logger.d('   📢 Voice message will be: "$voiceMessage"');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'med_channel_v2',

            'Medication Reminders',

            channelDescription: 'Daily reminders to take your medicine',

            importance: Importance.max,

            priority: Priority.high,

            playSound: true,

            enableVibration: true,

            visibility: NotificationVisibility.public,

            icon: '@mipmap/ic_launcher',

            fullScreenIntent: true,
          );

      // Schedule the notification

      await notificationsPlugin.zonedSchedule(
        id,

        title,

        body,

        scheduledTime,

        const NotificationDetails(android: androidDetails),

        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,

        matchDateTimeComponents: DateTimeComponents.time,

        payload: voiceMessage,
      );

      _logger.i('✅ Successfully scheduled notification ID: $id');

      await _verifyNotificationScheduled(id);

      // ✨ ALSO schedule automatic voice at the same time

      _scheduleAutoVoice(scheduledTime, voiceMessage, id);
    } catch (e, stackTrace) {
      _logger.e('❌ Error scheduling notification: $e');

      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// Schedule voice to play automatically when notification time arrives

  /// ⚠️ Only works if app is running (not killed)

  static void _scheduleAutoVoice(
    tz.TZDateTime when,
    String message,
    int notificationId,
  ) {
    final now = tz.TZDateTime.now(tz.local);

    final delay = when.difference(now);

    if (delay.isNegative || delay.inSeconds < 1) {
      _logger.w('⚠️ Time already passed or too soon, speaking immediately');

      speakNotification(message);

      // ✨ Reduce stock immediately

      _reduceStockFromNotificationId(notificationId);

      return;
    }

    _logger.i('🎤 AUTO-VOICE SCHEDULED!');

    _logger.i(
      '   Will speak in ${delay.inMinutes} minutes (${delay.inSeconds} seconds)',
    );

    _logger.i('   ⚠️ App must remain open for auto-voice to work');

    // Schedule the voice to play at notification time

    Future.delayed(delay, () {
      _logger.i('');

      _logger.i('🔔🔔🔔 NOTIFICATION TIME! 🔔🔔🔔');

      _logger.i('🔊 AUTO-SPEAKING NOW...');

      speakNotification(message);

      // ✨ Reduce stock automatically

      _reduceStockFromNotificationId(notificationId);
    });
  }

  // ✨ NEW: Helper to reduce stock from notification ID

  static Future<void> _reduceStockFromNotificationId(int notificationId) async {
    try {
      int medicationId = notificationId ~/ 100;

      if (medicationId > 0) {
        _logger.i('💊 Auto-reducing stock for medication ID: $medicationId');

        await _reduceStock(medicationId);
      }
    } catch (e) {
      _logger.e('❌ Error auto-reducing stock: $e');
    }
  }

  static Future<void> _verifyNotificationScheduled(int id) async {
    try {
      final pendingNotifications =
          await notificationsPlugin.pendingNotificationRequests();

      final found = pendingNotifications.any((n) => n.id == id);

      if (found) {
        _logger.i('✅ Verified: Notification ID $id is in pending list');
      } else {
        _logger.e('❌ WARNING: Notification ID $id NOT found in pending list!');
      }
    } catch (e) {
      _logger.e('❌ Error verifying notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      _logger.i('🔕 Cancelling notification ID: $id');

      await notificationsPlugin.cancel(id);

      _logger.i('✅ Cancelled notification ID: $id');
    } catch (e) {
      _logger.e('❌ Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      _logger.i('🔕 Cancelling ALL notifications');

      await notificationsPlugin.cancelAll();

      _logger.i('✅ All notifications cancelled');
    } catch (e) {
      _logger.e('❌ Error cancelling all notifications: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    _logger.d('   Current time: $now');

    _logger.d('   Scheduled time: $scheduled');

    return scheduled;
  }

  static Future<void> _requestPermissions() async {
    try {
      _logger.i('🔐 Checking notification permissions...');

      var status = await Permission.notification.status;

      _logger.i('   Notification permission status: $status');

      if (!status.isGranted) {
        _logger.i('   Requesting notification permission...');

        status = await Permission.notification.request();

        _logger.i('   New permission status: $status');
      }

      if (status.isGranted) {
        _logger.i('✅ Notification permission granted');
      } else if (status.isDenied) {
        _logger.w('⚠️ Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        _logger.e('❌ Notification permission permanently denied');
      }

      if (await Permission.scheduleExactAlarm.isPermanentlyDenied == false) {
        var alarmStatus = await Permission.scheduleExactAlarm.status;

        if (!alarmStatus.isGranted) {
          alarmStatus = await Permission.scheduleExactAlarm.request();
        }
      }
    } catch (e) {
      _logger.e('❌ Error requesting permissions: $e');
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      _logger.i('🧪 Sending test notification...');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'test_channel_v2',

            'Test Notifications',

            channelDescription: 'Test notification channel',

            importance: Importance.max,

            priority: Priority.high,

            playSound: true,

            enableVibration: true,
          );

      await notificationsPlugin.show(
        999,

        'Test Notification',

        'If you see this, notifications are working! ✅',

        const NotificationDetails(android: androidDetails),

        payload: "Test notification is working perfectly",
      );

      _logger.i('✅ Test notification sent');

      // Automatically speak after showing notification

      await Future.delayed(const Duration(milliseconds: 500));

      _logger.i('🎤 Auto-speaking test notification...');

      await speakNotification("Test notification is working perfectly");
    } catch (e) {
      _logger.e('❌ Error sending test notification: $e');
    }
  }
}
