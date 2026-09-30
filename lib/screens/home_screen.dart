import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:medi_mate/models/medication_model.dart';

import 'package:medi_mate/screens/add_medication_screen.dart';

import 'package:medi_mate/screens/barcode_scanner_screen.dart';

import 'package:medi_mate/services/notification_service.dart';

import 'package:intl/intl.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:logger/logger.dart';

class MedicationListScreen extends StatefulWidget {

  const MedicationListScreen({super.key});

  @override

  State<MedicationListScreen> createState() => _MedicationListScreenState();

}

class _MedicationListScreenState extends State<MedicationListScreen> {

  final supabase = Supabase.instance.client;

  final logger = Logger();

  String? _fcmToken;

  late Future<List<Medication>> _medicationsFuture;

  List<Medication> _medicationsList = [];

  @override

  void initState() {

    super.initState();

    _initializeFCM();

    _medicationsFuture = _fetchMedications().then((meds) {

      if (mounted) {

        setState(() {

          _medicationsList = meds;

        });

        _rescheduleNotifications(meds);

      }

      return meds;

    });

  }

  Future<void> _initializeFCM() async {

    try {

      logger.i('🔔 Initializing FCM...');

      _fcmToken = await FirebaseMessaging.instance.getToken();

      if (_fcmToken != null) {

        logger.i('✅ FCM Token obtained');

        await _saveFCMTokenToDatabase(_fcmToken!);

      } else {

        logger.e('❌ Failed to get FCM token');

      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {

        logger.i('🔄 FCM Token refreshed');

        _fcmToken = newToken;

        _saveFCMTokenToDatabase(newToken);

      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {

        logger.i(

          '📨 Received foreground message: ${message.notification?.title}',

        );

      });

    } catch (e) {

      logger.e('❌ Error initializing FCM: $e');

    }

  }

  Future<void> _saveFCMTokenToDatabase(String token) async {

    try {

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        logger.w('⚠️ No user logged in, cannot save FCM token');

        return;

      }

      await supabase.from('user_tokens').upsert({

        'user_id': userId,

        'fcm_token': token,

        'updated_at': DateTime.now().toIso8601String(),

      }, onConflict: 'user_id');

      logger.i('✅ FCM token saved successfully');

    } catch (e) {

      logger.e('❌ Error saving FCM token: $e');

    }

  }

  Future<List<Medication>> _fetchMedications() async {

    try {

      logger.i('📥 Fetching medications...');

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        logger.w('⚠️ No user logged in');

        return [];

      }

      final response = await supabase

          .from('medications')

          .select()

          .eq('user_id', userId)

          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> data =

          (response as List)

              .map((item) => Map<String, dynamic>.from(item as Map))

              .toList();

      logger.i('✅ Fetched ${data.length} medications');

      return data.map((item) => Medication.fromJson(item)).toList();

    } catch (e) {

      logger.e('❌ Error fetching medications: $e');

      return [];

    }

  }

  Future<void> _refreshList() async {

    try {

      final meds = await _fetchMedications();

      if (!mounted) return;

      setState(() {

        _medicationsList = meds;

        _medicationsFuture = Future<List<Medication>>.value(meds);

      });

    } catch (e) {

      logger.e('❌ Error refreshing medications: $e');

    }

  }

  String _convert12To24Hour(String time12) {

    try {

      List<String> parts = time12.split(' ');

      if (parts.length != 2) return time12;

      List<String> hm = parts[0].split(':');

      int hour = int.parse(hm[0]);

      int minute = int.parse(hm[1]);

      String ampm = parts[1].toUpperCase();

      if (ampm == 'PM' && hour != 12) hour += 12;

      if (ampm == 'AM' && hour == 12) hour = 0;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    } catch (e) {

      logger.e('❌ Error converting time: $e');

      return time12;

    }

  }

  Future<void> _addMedication() async {

    final result = await Navigator.push<Map<String, dynamic>>(

      context,

      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),

    );

    if (result != null && mounted) {

      try {

        final userId = supabase.auth.currentUser?.id;

        if (userId == null) throw Exception('User not logged in');

        result['user_id'] = userId;

        logger.i('➕ Adding new medication: ${result['name']}');

        final insertedData =

            await supabase.from('medications').insert(result).select();

        final newMed = Medication.fromJson(insertedData.first);

        logger.i('✅ Medication added with ID: ${newMed.id}');

        // Auto-generate barcode if not present

        if (result['barcode'] == null || result['barcode'].toString().isEmpty) {

          final barcode = 'MEDIC00${newMed.id}';

          await supabase

              .from('medications')

              .update({'barcode': barcode})

              .eq('id', newMed.id)

              .eq('user_id', userId);

          logger.i('📊 Barcode generated: $barcode');

        }

        // Schedule notifications

        if (result['reminder_times'] != null &&

            result['reminder_times'] is List) {

          final List<String> reminderTimes = List<String>.from(

            result['reminder_times'],

          );

          logger.i(

            '⏰ Scheduling ${reminderTimes.length} notifications for ${newMed.name}',

          );

          for (int i = 0; i < reminderTimes.length; i++) {

            String timeStr12Hour = reminderTimes[i];

            String timeStr24Hour = _convert12To24Hour(timeStr12Hour);

            int notificationId = newMed.id * 100 + i;

            await _scheduleNotificationWithFCM(

              id: notificationId,

              medicationId: newMed.id,

              medicationName: newMed.name,

              timeStr: timeStr24Hour,

            );

          }

        }

        await _refreshList();

      } catch (e) {

        logger.e('❌ Failed to add medication: $e');

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text('Failed to add medication: $e'),

              backgroundColor: Colors.red,

            ),

          );

        }

      }

    }

  }

  Future<void> _scheduleNotificationWithFCM({

    required int id,

    required int medicationId,

    required String medicationName,

    required String timeStr,

  }) async {

    try {

      logger.i(

        '🔔 Scheduling notification ID: $id for medication ID: $medicationId',

      );

      await NotificationService.scheduleDailyNotification(

        id: id,

        title: 'Medication Reminder',

        body: 'Time to take $medicationName',

        timeStr: timeStr,

      );

      logger.i('✅ Local notification scheduled successfully');

      if (_fcmToken != null) {

        final userId = supabase.auth.currentUser?.id;

        if (userId != null) {

          await supabase.from('scheduled_notifications').insert({

            'user_id': userId,

            'medication_id': medicationId,

            'notification_id': id,

            'medication_name': medicationName,

            'scheduled_time': timeStr,

            'fcm_token': _fcmToken,

            'updated_at': DateTime.now().toIso8601String(),

          });

          logger.i('✅ Notification schedule saved to database');

        }

      }

    } catch (e) {

      logger.e('❌ Error scheduling notification: $e');

    }

  }

  Future<void> _scanBarcode() async {

    final barcode = await Navigator.push<String>(

      context,

      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),

    );

    logger.i('📷 Barcode received: $barcode');

    final cleanBarcode = barcode?.trim();

    if (cleanBarcode != null && mounted) {

      try {

        final userId = supabase.auth.currentUser?.id;

        if (userId == null) throw Exception('User not logged in');

        logger.i('🔍 Checking barcode_lookups for: "$cleanBarcode"');

        final barcodeData =

            await supabase

                .from('barcode_lookups')

                .select('barcode, medication_name, dosage')

                .eq('barcode', cleanBarcode)

                .maybeSingle();

        logger.i('📊 Query result: $barcodeData');

        if (barcodeData != null) {

          logger.i(

            '✅ FOUND! Name: ${barcodeData['medication_name']}, Dosage: ${barcodeData['dosage']}',

          );

          // Check if user already has this medication

          final userHasMed =

              await supabase

                  .from('medications')

                  .select('id, name')

                  .eq('user_id', userId)

                  .eq('barcode', cleanBarcode)

                  .maybeSingle();

          if (userHasMed != null) {

            if (mounted) {

              ScaffoldMessenger.of(context).showSnackBar(

                SnackBar(

                  content: Text(

                    'You already have ${userHasMed['name']} in your list',

                  ),

                  backgroundColor: Colors.orange,

                ),

              );

            }

            return;

          }

          // Open form with pre-filled data

          if (mounted) {

            logger.i('🎨 Opening form with pre-filled data...');

            final result = await Navigator.push<Map<String, dynamic>>(

              context,

              MaterialPageRoute(

                builder:

                    (_) => AddMedicationScreen(

                      initialData: {

                        'name': barcodeData['medication_name'],

                        'dosage': barcodeData['dosage'],

                        'barcode': barcodeData['barcode'],

                        'stock_quantity': 30,

                        'frequency': 'Once daily',

                      },

                    ),

              ),

            );

            logger.i('📋 Form returned: $result');

            if (result != null && mounted) {

              await _saveMedicationFromBarcode(result, userId);

            } else {

              logger.w('⚠️ User cancelled form');

            }

          }

        } else {

          logger.w('❌ Barcode not found in database: $cleanBarcode');

          if (mounted) {

            final shouldCreate = await showDialog<bool>(

              context: context,

              builder:

                  (context) => AlertDialog(

                    title: const Text('New Medication'),

                    content: Text(

                      'Barcode "$cleanBarcode" not found.\n\nWould you like to add a new medication?',

                    ),

                    actions: [

                      TextButton(

                        onPressed: () => Navigator.pop(context, false),

                        child: const Text('Cancel'),

                      ),

                      ElevatedButton(

                        onPressed: () => Navigator.pop(context, true),

                        child: const Text('Add New'),

                      ),

                    ],

                  ),

            );

            if (shouldCreate == true && mounted) {

              final result = await Navigator.push<Map<String, dynamic>>(

                context,

                MaterialPageRoute(

                  builder:

                      (_) => AddMedicationScreen(

                        initialData: {

                          'barcode': cleanBarcode,

                          'stock_quantity': 30,

                        },

                      ),

                ),

              );

              if (result != null && mounted) {

                await _saveMedicationFromBarcode(result, userId);

                // Add to barcode_lookups for future

                try {

                  await supabase.from('barcode_lookups').insert({

                    'barcode': cleanBarcode,

                    'medication_name': result['name'],

                    'dosage': result['dosage'],

                  });

                  logger.i('📊 Added to barcode_lookups');

                } catch (e) {

                  logger.w('⚠️ Could not add to barcode_lookups: $e');

                }

              }

            }

          }

        }

      } catch (e, stackTrace) {

        logger.e('❌ Error processing barcode: $e');

        logger.e('Stack: $stackTrace');

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text('Error: ${e.toString()}'),

              backgroundColor: Colors.red,

              duration: const Duration(seconds: 5),

            ),

          );

        }

      }

    }

  }

  Future<void> _saveMedicationFromBarcode(

    Map<String, dynamic> medicationData,

    String userId,

  ) async {

    try {

      medicationData['user_id'] = userId;

      logger.i('💾 Saving: ${medicationData['name']}');

      logger.d('📦 Data: $medicationData');

      final insertedData =

          await supabase

              .from('medications')

              .insert(medicationData)

              .select()

              .single();

      final newMed = Medication.fromJson(insertedData);

      logger.i('✅ Saved with ID: ${newMed.id}');

      // Schedule notifications

      if (medicationData['reminder_times'] != null &&

          medicationData['reminder_times'] is List) {

        final List<String> reminderTimes = List<String>.from(

          medicationData['reminder_times'],

        );

        logger.i('⏰ Scheduling ${reminderTimes.length} notifications');

        for (int i = 0; i < reminderTimes.length; i++) {

          String timeStr12Hour = reminderTimes[i];

          String timeStr24Hour = _convert12To24Hour(timeStr12Hour);

          int notificationId = newMed.id * 100 + i;

          await _scheduleNotificationWithFCM(

            id: notificationId,

            medicationId: newMed.id,

            medicationName: newMed.name,

            timeStr: timeStr24Hour,

          );

        }

      }

      await _refreshList();

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('${newMed.name} added successfully! 🎉'),

            backgroundColor: Colors.green,

          ),

        );

      }

    } catch (e, stackTrace) {

      logger.e('❌ Error saving: $e');

      logger.e('Stack: $stackTrace');

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('Failed to save: ${e.toString()}'),

            backgroundColor: Colors.red,

          ),

        );

      }

    }

  }

  Future<void> _editMedication(Medication med) async {

    final result = await Navigator.push<Map<String, dynamic>>(

      context,

      MaterialPageRoute(

        builder: (_) => AddMedicationScreen(initialData: med.toMap()),

      ),

    );

    if (result == null || !mounted) {

      return;

    }

    try {

      final dynamic idValue = result['id'];

      if (idValue == null) {

        throw Exception('Medication ID is missing.');

      }

      final int id = idValue is int ? idValue : int.parse(idValue.toString());

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception('No user is logged in.');

      }

      // Make a copy so we don't modify

      // the result returned by the edit screen.

      final Map<String, dynamic> updateData = Map<String, dynamic>.from(result);

      updateData.remove('id');

      logger.i('✏️ Updating medication ID: $id');

      logger.i(

        '⏰ New reminder times: '

        '${updateData['reminder_times']}',

      );

      logger.i(

        '📅 New next dose: '

        '${updateData['next_dose']}',

      );

      // ------------------------------------------------------------

      // UPDATE SUPABASE

      // ------------------------------------------------------------

      final updatedRows =

          await supabase

              .from('medications')

              .update(updateData)

              .eq('id', id)

              .eq('user_id', userId)

              .select();

      if (updatedRows.isEmpty) {

        throw Exception(

          'Medication was not updated. '

          'Check the user_id/RLS policy.',

        );

      }

      logger.i('✅ Medication updated successfully');

      logger.i('💾 Database result: $updatedRows');

      // ------------------------------------------------------------

      // CANCEL OLD NOTIFICATIONS

      // ------------------------------------------------------------

      await _cancelAllNotificationsForMedication(id);

      // ------------------------------------------------------------

      // SCHEDULE NEW NOTIFICATIONS

      // ------------------------------------------------------------

      final dynamic reminderData = updateData['reminder_times'];

      if (reminderData is List && reminderData.isNotEmpty) {

        final List<String> reminderTimes =

            reminderData.map((time) => time.toString()).toList();

        logger.i(

          '⏰ Scheduling '

          '${reminderTimes.length} new reminders',

        );

        for (int i = 0; i < reminderTimes.length; i++) {

          final String timeStr12Hour = reminderTimes[i];

          final String timeStr24Hour = _convert12To24Hour(timeStr12Hour);

          final int notificationId = id * 100 + i;

          await _scheduleNotificationWithFCM(

            id: notificationId,

            medicationId: id,

            medicationName: updateData['name']?.toString() ?? med.name,

            timeStr: timeStr24Hour,

          );

          logger.i(

            '🔔 Notification scheduled: '

            '$timeStr12Hour',

          );

        }

      }

      // ------------------------------------------------------------

      // IMPORTANT:

      // FETCH THE MEDICATION AGAIN FROM SUPABASE

      // ------------------------------------------------------------

      await _refreshList();

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Medication updated successfully! ✓'),

          backgroundColor: Colors.green,

        ),

      );

    } catch (e, stackTrace) {

      logger.e('❌ Failed to update medication: $e');

      logger.e('Stack trace: $stackTrace');

      if (!mounted) {

        return;

      }

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Failed to update medication: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }

  Future<void> _cancelAllNotificationsForMedication(int medicationId) async {

    try {

      logger.i('🔕 Cancelling all notifications for: $medicationId');

      for (int i = 0; i < 10; i++) {

        int notificationId = medicationId * 100 + i;

        await NotificationService.cancelNotification(notificationId);

      }

      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {

        await supabase

            .from('scheduled_notifications')

            .delete()

            .eq('medication_id', medicationId)

            .eq('user_id', userId);

      }

      logger.i('✅ All notifications cancelled');

    } catch (e) {

      logger.e('❌ Error cancelling notifications: $e');

    }

  }

  Future<void> _deleteMedication(int id) async {

    try {

      logger.i('🗑️ Deleting medication ID: $id');

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception('No user logged in');

      }

      final deletedRows = await supabase

          .from('medications')

          .delete()

          .eq('id', id)

          .eq('user_id', userId)

          .select('id');

      if (deletedRows.isEmpty) {

        throw Exception(

          'Medication was not deleted. Check the DELETE RLS policy and user_id.',

        );

      }

      logger.i('✅ Deleted from database: $deletedRows');

      await _cancelAllNotificationsForMedication(id);

      await _refreshList();

    } catch (e) {

      logger.e('❌ Failed to delete: $e');

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('Failed to delete: $e'),

            backgroundColor: Colors.red,

          ),

        );

      }

    }

  }

  Future<void> _handleDismiss(int index) async {

    if (index < 0 || index >= _medicationsList.length) return;

    final med = _medicationsList[index];

    await _deleteMedication(med.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text('${med.name} deleted'),

        duration: const Duration(seconds: 2),

      ),

    );

  }

  String _formatDisplayTime(String? isoString) {

    if (isoString == null) return 'No Time';

    try {

      final dt = DateTime.parse(isoString);

      return DateFormat('h:mm a').format(dt);

    } catch (e) {

      return 'Invalid Time';

    }

  }

  Future<void> _rescheduleNotifications(List<Medication> medications) async {

    try {

      logger.i('🔄 Rescheduling notifications...');

      for (var med in medications) {

        if (med.reminderTimes != null && med.reminderTimes!.isNotEmpty) {

          for (int i = 0; i < med.reminderTimes!.length; i++) {

            String timeStr12Hour = med.reminderTimes![i];

            String timeStr24Hour = _convert12To24Hour(timeStr12Hour);

            int notificationId = med.id * 100 + i;

            await _scheduleNotificationWithFCM(

              id: notificationId,

              medicationId: med.id,

              medicationName: med.name,

              timeStr: timeStr24Hour,

            );

          }

        }

      }

      logger.i('✅ All notifications rescheduled');

    } catch (e) {

      logger.e('❌ Error rescheduling: $e');

    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reminderCount = _medicationsList.fold<int>(
      0,
      (total, med) => total + (med.reminderTimes?.length ?? 0),
    );
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildMessageState(
              context,
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: 'Unable to load your medications.',
              action: FilledButton.icon(
                onPressed: _refreshList,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && _medicationsList.isEmpty) {
            return Center(
              child: CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshList,
            color: scheme.primary,
            backgroundColor: Colors.white,
            child: SafeArea(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                children: [
                  _buildHeroHeader(greeting: greeting),
                  const SizedBox(height: 18),
                  _buildStatsCard(
                    medicineCount: _medicationsList.length,
                    todayCount: _medicationsList.where((m) => (m.reminderTimes?.isNotEmpty ?? false)).length,
                    reminderCount: reminderCount,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Medications',
                              style: TextStyle(color: Color(0xFF211738), fontSize: 21, fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Keep your medicines organized and on time',
                              style: TextStyle(color: Color(0xFF766C88), fontSize: 12.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      if (_medicationsList.isNotEmpty)
                        TextButton(
                          onPressed: _addMedication,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6D28D9),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Add new', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_medicationsList.isEmpty)
                    _buildEmptyMedicationCard()
                  else
                    ..._medicationsList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      final displayTime = _formatDisplayTime(med.nextDose);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(med.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4EA),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE54866), size: 27),
                          ),
                          onDismissed: (_) => _handleDismiss(index),
                          child: MedicationCard(
                            name: med.name,
                            dosage: med.dosage ?? '',
                            nextDose: displayTime,
                            reminderTimes: med.reminderTimes,
                            onTap: () => _editMedication(med),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 6),
                  _buildQuickActions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader({required String greeting}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 185),
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCCBFF), Color(0xFFEFE7FF), Color(0xFFF7F1FF)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -35,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.35), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 12,
            bottom: -45,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(color: const Color(0xFFB99AFF).withValues(alpha: 0.18), shape: BoxShape.circle),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('MediMate', style: TextStyle(color: Color(0xFF5422B8), fontSize: 17, fontWeight: FontWeight.w800)),
                        SizedBox(width: 7),
                        Icon(Icons.favorite_rounded, color: Color(0xFF8B5CF6), size: 18),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(greeting + ',', style: const TextStyle(color: Color(0xFF514665), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    const Text('Aiswarya 👋', style: TextStyle(color: Color(0xFF211738), fontSize: 27, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    const Text('Take care of your health today.', style: TextStyle(color: Color(0xFF6F6382), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      _headerIconButton(Icons.notifications_none_rounded, () {}),
                      const SizedBox(width: 8),
                      _headerIconButton(Icons.qr_code_scanner_rounded, _scanBarcode),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _addMedication,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 7))],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 66,
            bottom: 3,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), shape: BoxShape.circle),
              child: const Icon(Icons.medical_services_rounded, color: Color(0xFF7C3AED), size: 38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: const Color(0xFF5422B8), size: 21),
      ),
    );
  }

  Widget _buildStatsCard({required int medicineCount, required int todayCount, required int reminderCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(child: _statItem(Icons.medication_rounded, '$medicineCount', medicineCount == 1 ? 'Medicine' : 'Medicines')),
          _statDivider(),
          Expanded(child: _statItem(Icons.schedule_rounded, '$todayCount', 'Today')),
          _statDivider(),
          Expanded(child: _statItem(Icons.notifications_active_rounded, '$reminderCount', 'Reminders')),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 45, color: const Color(0xFFE8E0F5));

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 21),
        ),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(color: Color(0xFF211738), fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: Color(0xFF766C88), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyMedicationCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE4D9F8))),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(color: Color(0xFFF0E9FF), shape: BoxShape.circle),
            child: const Icon(Icons.medication_outlined, color: Color(0xFF7C3AED), size: 38),
          ),
          const SizedBox(height: 15),
          const Text('No medications yet', style: TextStyle(color: Color(0xFF211738), fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Add a medicine manually or scan its barcode\nto get started.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF766C88), fontSize: 13, height: 1.45)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _addMedication,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add medication'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _quickActionCard(Icons.qr_code_scanner_rounded, 'Scan Barcode', 'Identify medicine', _scanBarcode)),
        const SizedBox(width: 12),
        Expanded(child: _quickActionCard(Icons.add_circle_outline_rounded, 'Add Medicine', 'Enter details', _addMedication)),
      ],
    );
  }

  Widget _quickActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFF0E9FF), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF211738), fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF766C88), fontSize: 10.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================

  // EMPTY / ERROR MESSAGE

  // ============================================================

  Widget _buildMessageState(

    BuildContext context, {

    required IconData icon,

    required String title,

    required String message,

    Widget? action,

  }) {

    final theme = Theme.of(context);

    final scheme = theme.colorScheme;

    return Center(

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 32),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              width: 76,

              height: 76,

              decoration: BoxDecoration(

                color: scheme.primary.withOpacity(0.10),

                shape: BoxShape.circle,

              ),

              child: Icon(icon, size: 36, color: scheme.primary),

            ),

            const SizedBox(height: 18),

            Text(

              title,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),

            ),

            const SizedBox(height: 7),

            Text(

              message,

              textAlign: TextAlign.center,

              style: TextStyle(

                height: 1.45,

                fontSize: 14,

                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.62),

              ),

            ),

            if (action != null) ...[const SizedBox(height: 20), action],

          ],

        ),

      ),

    );

  }

}

// ============================================================

// MEDICATION CARD

// ============================================================

class MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String nextDose;
  final List<String>? reminderTimes;
  final VoidCallback onTap;

  const MedicationCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.nextDose,
    required this.reminderTimes,
    required this.onTap,
  });

  Color _accentForMedicine() {
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF60A5FA),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForMedicine();
    final hasReminders = reminderTimes != null && reminderTimes!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8E0F5)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 7)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.medication_rounded, color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF211738), fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        if (hasReminders)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFE7F6F3), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_active_rounded, color: Color(0xFF16877A), size: 12),
                                SizedBox(width: 4),
                                Text('Reminder on', style: TextStyle(color: Color(0xFF16877A), fontSize: 9.5, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (dosage.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(dosage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF766C88), fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.schedule_rounded, color: accent, size: 14),
                        ),
                        const SizedBox(width: 7),
                        Text(hasReminders ? 'Reminder' : 'Next dose', style: const TextStyle(color: Color(0xFF766C88), fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasReminders ? reminderTimes!.join('  •  ') : nextDose,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF7C3AED), size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
