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

  static const Color purple = Color(0xFF7C3AED);

  static const Color purpleDark = Color(0xFF5B21B6);

  static const Color lavender = Color(0xFFF3EEFF);

  static const Color pageBackground = Color(0xFFF8F6FF);

  static const Color textDark = Color(0xFF211738);

  static const Color textMuted = Color(0xFF716A80);

  static const Color success = Color(0xFF16A34A);

  static const Color danger = Color(0xFFDC2626);

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

      final List<Map<String, dynamic>> data = (response as List)

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

      final parts = time12.split(' ');

      if (parts.length != 2) return time12;

      final hm = parts[0].split(':');

      final hour = int.parse(hm[0]);

      final minute = int.parse(hm[1]);

      final ampm = parts[1].toUpperCase();

      var finalHour = hour;

      if (ampm == 'PM' && hour != 12) {

        finalHour += 12;

      }

      if (ampm == 'AM' && hour == 12) {

        finalHour = 0;

      }

      return '${finalHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    } catch (e) {

      logger.e('❌ Error converting time: $e');

      return time12;

    }

  }

  Future<void> _addMedication() async {

    final result = await Navigator.push<Map<String, dynamic>>(

      context,

      MaterialPageRoute(

        builder: (_) => const AddMedicationScreen(),

      ),

    );

    if (result != null && mounted) {

      try {

        final userId = supabase.auth.currentUser?.id;

        if (userId == null) {

          throw Exception('User not logged in');

        }

        result['user_id'] = userId;

        logger.i(

          '➕ Adding new medication: ${result['name']}',

        );

        final insertedData =

            await supabase.from('medications').insert(result).select();

        final newMed = Medication.fromJson(insertedData.first);

        logger.i(

          '✅ Medication added with ID: ${newMed.id}',

        );

        if (result['barcode'] == null ||

            result['barcode'].toString().isEmpty) {

          final barcode = 'MEDIC00${newMed.id}';

          await supabase

              .from('medications')

              .update({'barcode': barcode})

              .eq('id', newMed.id)

              .eq('user_id', userId);

          logger.i('📊 Barcode generated: $barcode');

        }

        if (result['reminder_times'] != null &&

            result['reminder_times'] is List) {

          final List<String> reminderTimes =

              List<String>.from(result['reminder_times']);

          logger.i(

            '⏰ Scheduling ${reminderTimes.length} notifications for ${newMed.name}',

          );

          for (int i = 0; i < reminderTimes.length; i++) {

            final timeStr12Hour = reminderTimes[i];

            final timeStr24Hour =

                _convert12To24Hour(timeStr12Hour);

            final notificationId = newMed.id * 100 + i;

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

              content: Text(

                'Failed to add medication: $e',

              ),

              backgroundColor: danger,

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

      await NotificationService.scheduleDailyNotification(

        id: id,

        title: 'Medication Reminder',

        body: 'Time to take $medicationName',

        timeStr: timeStr,

      );

      logger.i(

        '✅ Local notification scheduled successfully',

      );

      if (_fcmToken != null) {

        final userId = supabase.auth.currentUser?.id;

        if (userId != null) {

          await supabase
              .from('scheduled_notifications')
              .upsert(
                {
                  'user_id': userId,
                  'medication_id': medicationId,
                  'medication_name': medicationName,
                  'scheduled_time': timeStr,
                  'fcm_token': _fcmToken,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                onConflict: 'user_id,medication_id',
              );

          logger.i(

            '✅ Notification schedule saved to database',

          );

        }

      }

    } catch (e) {

      logger.e(

        '❌ Error scheduling notification: $e',

      );

    }

  }

  Future<void> _scanBarcode() async {

    final barcode = await Navigator.push<String>(

      context,

      MaterialPageRoute(

        builder: (_) => const BarcodeScannerScreen(),

      ),

    );

    logger.i('📷 Barcode received: $barcode');

    final cleanBarcode = barcode?.trim();

    if (cleanBarcode != null && mounted) {

      try {

        final userId = supabase.auth.currentUser?.id;

        if (userId == null) {

          throw Exception('User not logged in');

        }

        final barcodeData = await supabase

            .from('barcode_lookups')

            .select(

              'barcode, medication_name, dosage',

            )

            .eq('barcode', cleanBarcode)

            .maybeSingle();

        if (barcodeData != null) {

          final userHasMed = await supabase

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

          if (mounted) {

            final result =

                await Navigator.push<Map<String, dynamic>>(

              context,

              MaterialPageRoute(

                builder: (_) => AddMedicationScreen(

                  initialData: {

                    'name':

                        barcodeData['medication_name'],

                    'dosage':

                        barcodeData['dosage'],

                    'barcode':

                        barcodeData['barcode'],

                    'stock_quantity': 30,

                    'frequency': 'Once daily',

                  },

                ),

              ),

            );

            if (result != null && mounted) {

              await _saveMedicationFromBarcode(

                result,

                userId,

              );

            }

          }

        } else {

          if (mounted) {

            final shouldCreate =

                await showDialog<bool>(

              context: context,

              builder: (context) => AlertDialog(

                title: const Text(

                  'New Medication',

                ),

                content: Text(

                  'Barcode "$cleanBarcode" not found.\n\nWould you like to add a new medication?',

                ),

                actions: [

                  TextButton(

                    onPressed: () =>

                        Navigator.pop(context, false),

                    child: const Text('Cancel'),

                  ),

                  ElevatedButton(

                    onPressed: () =>

                        Navigator.pop(context, true),

                    child: const Text('Add New'),

                  ),

                ],

              ),

            );

            if (shouldCreate == true && mounted) {

              final result =

                  await Navigator.push<Map<String, dynamic>>(

                context,

                MaterialPageRoute(

                  builder: (_) => AddMedicationScreen(

                    initialData: {

                      'barcode': cleanBarcode,

                      'stock_quantity': 30,

                    },

                  ),

                ),

              );

              if (result != null && mounted) {

                await _saveMedicationFromBarcode(

                  result,

                  userId,

                );

                try {

                  await supabase

                      .from('barcode_lookups')

                      .insert({

                    'barcode': cleanBarcode,

                    'medication_name':

                        result['name'],

                    'dosage': result['dosage'],

                  });

                } catch (e) {

                  logger.w(

                    '⚠️ Could not add to barcode_lookups: $e',

                  );

                }

              }

            }

          }

        }

      } catch (e, stackTrace) {

        logger.e(

          '❌ Error processing barcode: $e',

        );

        logger.e(

          'Stack: $stackTrace',

        );

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(

              content: Text(

                'Error: ${e.toString()}',

              ),

              backgroundColor: danger,

              duration:

                  const Duration(seconds: 5),

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

      final insertedData = await supabase

          .from('medications')

          .insert(medicationData)

          .select()

          .single();

      final newMed =

          Medication.fromJson(insertedData);

      if (medicationData['reminder_times'] != null &&

          medicationData['reminder_times'] is List) {

        final List<String> reminderTimes =

            List<String>.from(

          medicationData['reminder_times'],

        );

        for (int i = 0;

            i < reminderTimes.length;

            i++) {

          final timeStr12Hour =

              reminderTimes[i];

          final timeStr24Hour =

              _convert12To24Hour(

            timeStr12Hour,

          );

          final notificationId =

              newMed.id * 100 + i;

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

            content: Text(

              '${newMed.name} added successfully! 🎉',

            ),

            backgroundColor: success,

          ),

        );

      }

    } catch (e, stackTrace) {

      logger.e('❌ Error saving: $e');

      logger.e(

        'Stack: $stackTrace',

      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(

              'Failed to save: ${e.toString()}',

            ),

            backgroundColor: danger,

          ),

        );

      }

    }

  }

  Future<void> _editMedication(

    Medication med,

  ) async {

    final result =

        await Navigator.push<Map<String, dynamic>>(

      context,

      MaterialPageRoute(

        builder: (_) => AddMedicationScreen(

          initialData: med.toMap(),

        ),

      ),

    );

    if (result == null || !mounted) return;

    try {

      final dynamic idValue = result['id'];

      if (idValue == null) {

        throw Exception(

          'Medication ID is missing.',

        );

      }

      final int id = idValue is int

          ? idValue

          : int.parse(idValue.toString());

      final userId =

          supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception(

          'No user is logged in.',

        );

      }

      final updateData =

          Map<String, dynamic>.from(result);

      updateData.remove('id');

      final updatedRows = await supabase

          .from('medications')

          .update(updateData)

          .eq('id', id)

          .eq('user_id', userId)

          .select();

      if (updatedRows.isEmpty) {

        throw Exception(

          'Medication was not updated. Check the user_id/RLS policy.',

        );

      }

      await _cancelAllNotificationsForMedication(

        id,

      );

      final dynamic reminderData =

          updateData['reminder_times'];

      if (reminderData is List &&

          reminderData.isNotEmpty) {

        final reminderTimes = reminderData

            .map((time) => time.toString())

            .toList();

        for (

          int i = 0;

          i < reminderTimes.length;

          i++

        ) {

          final timeStr12Hour =

              reminderTimes[i];

          final timeStr24Hour =

              _convert12To24Hour(

            timeStr12Hour,

          );

          final notificationId =

              id * 100 + i;

          await _scheduleNotificationWithFCM(

            id: notificationId,

            medicationId: id,

            medicationName:

                updateData['name']?.toString() ??

                    med.name,

            timeStr: timeStr24Hour,

          );

        }

      }

      await _refreshList();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(

            'Medication updated successfully! ✓',

          ),

          backgroundColor: success,

        ),

      );

    } catch (e, stackTrace) {

      logger.e(

        '❌ Failed to update medication: $e',

      );

      logger.e(

        'Stack trace: $stackTrace',

      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            'Failed to update medication: $e',

          ),

          backgroundColor: danger,

        ),

      );

    }

  }

  Future<void> _cancelAllNotificationsForMedication(

    int medicationId,

  ) async {

    try {

      for (int i = 0; i < 10; i++) {

        final notificationId =

            medicationId * 100 + i;

        await NotificationService

            .cancelNotification(

          notificationId,

        );

      }

      final userId =

          supabase.auth.currentUser?.id;

      if (userId != null) {

        await supabase

            .from('scheduled_notifications')

            .delete()

            .eq(

              'medication_id',

              medicationId,

            )

            .eq(

              'user_id',

              userId,

            );

      }

    } catch (e) {

      logger.e(

        '❌ Error cancelling notifications: $e',

      );

    }

  }

  Future<void> _deleteMedication(

    int id,

  ) async {

    try {

      final userId =

          supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception(

          'No user logged in',

        );

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

      await _cancelAllNotificationsForMedication(

        id,

      );

      await _refreshList();

    } catch (e) {

      logger.e(

        '❌ Failed to delete: $e',

      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(

              'Failed to delete: $e',

            ),

            backgroundColor: danger,

          ),

        );

      }

    }

  }

  Future<void> _handleDismiss(

    int index,

  ) async {

    if (index < 0 ||

        index >= _medicationsList.length) {

      return;

    }

    final med = _medicationsList[index];

    await _deleteMedication(med.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(

          '${med.name} deleted',

        ),

        duration:

            const Duration(seconds: 2),

      ),

    );

  }

  String _formatDisplayTime(

    String? isoString,

  ) {

    if (isoString == null) {

      return 'No Time';

    }

    try {

      final dt = DateTime.parse(

        isoString,

      );

      return DateFormat(

        'h:mm a',

      ).format(dt);

    } catch (_) {

      return 'Invalid Time';

    }

  }

  Future<void> _rescheduleNotifications(

    List<Medication> medications,

  ) async {

    try {

      for (final med in medications) {

        if (med.reminderTimes != null &&

            med.reminderTimes!.isNotEmpty) {

          for (

            int i = 0;

            i < med.reminderTimes!.length;

            i++

          ) {

            final timeStr12Hour =

                med.reminderTimes![i];

            final timeStr24Hour =

                _convert12To24Hour(

              timeStr12Hour,

            );

            final notificationId =

                med.id * 100 + i;

            await _scheduleNotificationWithFCM(

              id: notificationId,

              medicationId: med.id,

              medicationName: med.name,

              timeStr: timeStr24Hour,

            );

          }

        }

      }

    } catch (e) {

      logger.e(

        '❌ Error rescheduling notifications: $e',

      );

    }

  }

  @override

  Widget build(

    BuildContext context,

  ) {

    return Scaffold(

      backgroundColor: pageBackground,

      body: SafeArea(

        child: Center(

          child: ConstrainedBox(

            constraints:

                const BoxConstraints(

              maxWidth: 430,

            ),

            child:

                FutureBuilder<List<Medication>>(

              future: _medicationsFuture,

              builder: (

                context,

                snapshot,

              ) {

                if (snapshot.hasError) {

                  return _buildMessageState(

                    icon:

                        Icons.error_outline_rounded,

                    title:

                        'Something went wrong',

                    message:

                        'Unable to load your medications.',

                    action: TextButton(

                      onPressed:

                          _refreshList,

                      child:

                          const Text('Try again'),

                    ),

                  );

                }

                if (snapshot.connectionState ==

                        ConnectionState.waiting &&

                    _medicationsList.isEmpty) {

                  return const Center(

                    child:

                        CircularProgressIndicator(

                      strokeWidth: 2.5,

                      color: purple,

                    ),

                  );

                }

                return RefreshIndicator(

                  onRefresh: _refreshList,

                  color: purple,

                  child: ListView(

                    physics:

                        const AlwaysScrollableScrollPhysics(),

                    padding:

                        const EdgeInsets.fromLTRB(

                      12,

                      10,

                      12,

                      170,

                    ),

                    children: [

                      _buildDashboardHeader(),

                      const SizedBox(height: 12),

                      _buildDashboardStats(),

                      const SizedBox(height: 10),

                      _buildMedicationSection(),

                    ],

                  ),

                );

              },

            ),

          ),

        ),

      ),

    );

  }

  Widget _buildDashboardHeader() {

    return Container(

      height: 122,

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [

            Color(0xFFEFE7FF),

            Color(0xFFDCD0FF),

          ],

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

        ),

        borderRadius:

            BorderRadius.circular(18),

      ),

      clipBehavior: Clip.hardEdge,

      child: Stack(

        children: [

          Positioned(

            top: -32,

            right: 54,

            child: Container(

              width: 82,

              height: 82,

              decoration: BoxDecoration(

                color: Colors.white

                    .withOpacity(0.22),

                shape: BoxShape.circle,

              ),

            ),

          ),

          Positioned(

            right: -8,

            bottom: -10,

            child: Image.asset(

              'assets/images/home_doctor.png',

              width: 150,

              height: 124,

              fit: BoxFit.contain,

              errorBuilder:

                  (_, __, ___) =>

                      const SizedBox.shrink(),

            ),

          ),

          Positioned(

            left: 12,

            top: 9,

            child: Row(

              children: [

                Container(

                  width: 22,

                  height: 22,

                  decoration: BoxDecoration(

                    color: Colors.white

                        .withOpacity(0.9),

                    borderRadius:

                        BorderRadius.circular(6),

                  ),

                  child: const Icon(

                    Icons.medication_rounded,

                    color: purple,

                    size: 13,

                  ),

                ),

                const SizedBox(width: 5),

                const Text(

                  'MediMate',

                  style: TextStyle(

                    color: textDark,

                    fontSize: 10,

                    fontWeight:

                        FontWeight.w800,

                  ),

                ),

              ],

            ),

          ),

          Positioned(

            right: 9,

            top: 7,

            child: Row(

              children: [

                _headerAction(

                  icon:

                      Icons.qr_code_scanner_rounded,

                  onTap: _scanBarcode,

                ),

                const SizedBox(width: 5),

                GestureDetector(

                  onTap: _addMedication,

                  child: Container(

                    width: 27,

                    height: 27,

                    decoration:

                        const BoxDecoration(

                      color: purple,

                      shape:

                          BoxShape.circle,

                    ),

                    child: const Icon(

                      Icons.add_rounded,

                      color: Colors.white,

                      size: 18,

                    ),

                  ),

                ),

              ],

            ),

          ),

          const Positioned(

            left: 12,

            top: 46,

            child: Text(

              'Good morning,',

              style: TextStyle(

                color: textMuted,

                fontSize: 9,

                fontWeight:

                    FontWeight.w500,

              ),

            ),

          ),

          const Positioned(

            left: 12,

            top: 62,

            child: Text(

              'Aiswarya 👋',

              style: TextStyle(

                color: textDark,

                fontSize: 19,

                fontWeight:

                    FontWeight.w900,

              ),

            ),

          ),

          const Positioned(

            left: 12,

            top: 88,

            child: Text(

              'Take care of your health today!',

              style: TextStyle(

                color: textMuted,

                fontSize: 8,

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _headerAction({

    required IconData icon,

    required VoidCallback onTap,

  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        width: 27,

        height: 27,

        decoration:

            const BoxDecoration(

          color: Colors.white,

          shape: BoxShape.circle,

        ),

        child: Icon(

          icon,

          color: purple,

          size: 14,

        ),

      ),

    );

  }

  Widget _buildDashboardStats() {

    final medicineCount =

        _medicationsList.length;

    final todayCount =

        _medicationsList.length;

    final reminderCount =

        _medicationsList.fold<int>(

      0,

      (sum, med) =>

          sum +

          (med.reminderTimes?.length ?? 0),

    );

    return Container(

      height: 76,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:

            BorderRadius.circular(17),

        border: Border.all(

          color: const Color(

            0xFFE9E1F5,

          ),

        ),

        boxShadow: [

          BoxShadow(

            color:

                purple.withOpacity(0.04),

            blurRadius: 10,

            offset:

                const Offset(0, 3),

          ),

        ],

      ),

      child: Row(

        children: [

          Expanded(

            child: _statItem(

              Icons.medication_rounded,

              medicineCount.toString(),

              'Medicines',

            ),

          ),

          _statDivider(),

          Expanded(

            child: _statItem(

              Icons.schedule_rounded,

              todayCount.toString(),

              'Today',

            ),

          ),

          _statDivider(),

          Expanded(

            child: _statItem(

              Icons

                  .notifications_active_rounded,

              reminderCount.toString(),

              'Reminders',

            ),

          ),

        ],

      ),

    );

  }

  Widget _statDivider() {

    return Container(

      width: 1,

      height: 30,

      color:

          const Color(0xFFE8E0F2),

    );

  }

  Widget _statItem(

    IconData icon,

    String value,

    String label,

  ) {

    return Column(

      mainAxisAlignment:

          MainAxisAlignment.center,

      children: [

        Container(

          width: 28,

          height: 28,

          decoration: BoxDecoration(

            color: lavender,

            borderRadius:

                BorderRadius.circular(8),

          ),

          child: Icon(

            icon,

            color: purple,

            size: 15,

          ),

        ),

        const SizedBox(height: 3),

        Text(

          value,

          style: const TextStyle(

            color: textDark,

            fontSize: 13,

            fontWeight:

                FontWeight.w900,

          ),

        ),

        Text(

          label,

          style: const TextStyle(

            color: textMuted,

            fontSize: 7,

          ),

        ),

      ],

    );

  }

  Widget _buildMedicationSection() {

    return Column(

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            const Expanded(

              child: Text(

                'My Medications',

                style: TextStyle(

                  color: textDark,

                  fontSize: 13,

                  fontWeight:

                      FontWeight.w900,

                ),

              ),

            ),

            GestureDetector(

              onTap: _refreshList,

              child: const Text(

                'View all',

                style: TextStyle(

                  color: purple,

                  fontSize: 7,

                  fontWeight:

                      FontWeight.w700,

                ),

              ),

            ),

          ],

        ),

        const SizedBox(height: 6),

        if (_medicationsList.isEmpty)

          _buildEmptyState()

        else

          ...List.generate(

            _medicationsList.length,

            (index) {

              final med =

                  _medicationsList[index];

              final displayTime =

                  _formatDisplayTime(

                med.nextDose,

              );

              return Padding(

                padding:

                    const EdgeInsets.only(

                  bottom: 8,

                ),

                child: Dismissible(

                  key: Key(

                    med.id.toString(),

                  ),

                  direction:

                      DismissDirection

                          .endToStart,

                  background: Container(

                    decoration:

                        BoxDecoration(

                      color: danger

                          .withOpacity(

                        0.12,

                      ),

                      borderRadius:

                          BorderRadius.circular(

                        14,

                      ),

                    ),

                    alignment:

                        Alignment.centerRight,

                    padding:

                        const EdgeInsets.only(

                      right: 18,

                    ),

                    child: const Icon(

                      Icons

                          .delete_outline_rounded,

                      color: danger,

                      size: 22,

                    ),

                  ),

                  onDismissed: (_) =>

                      _handleDismiss(

                    index,

                  ),

                  child:

                      MedicationCard(

                    name: med.name,

                    dosage:

                        med.dosage ?? '',

                    nextDose:

                        displayTime,

                    reminderTimes:

                        med.reminderTimes,

                    stockQuantity:

                        med.stockQuantity,

                    onTap: () =>

                        _editMedication(

                      med,

                    ),

                  ),

                ),

              );

            },

          ),

      ],

    );

  }

  Widget _buildEmptyState() {

    return Container(

      width: double.infinity,

      padding:

          const EdgeInsets.symmetric(

        horizontal: 20,

        vertical: 25,

      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:

            BorderRadius.circular(16),

        border: Border.all(

          color:

              const Color(0xFFE5DCF4),

        ),

      ),

      child: Column(

        children: [

          Container(

            width: 58,

            height: 58,

            decoration: BoxDecoration(

              color: lavender,

              borderRadius:

                  BorderRadius.circular(

                17,

              ),

            ),

            child: const Icon(

              Icons.medication_outlined,

              color: purple,

              size: 28,

            ),

          ),

          const SizedBox(height: 10),

          const Text(

            'No medications yet',

            style: TextStyle(

              color: textDark,

              fontSize: 15,

              fontWeight:

                  FontWeight.w800,

            ),

          ),

          const SizedBox(height: 5),

          const Text(

            'Add a medicine manually or scan its barcode.',

            textAlign:

                TextAlign.center,

            style: TextStyle(

              color: textMuted,

              fontSize: 9,

            ),

          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(

            onPressed:

                _addMedication,

            icon: const Icon(

              Icons.add_rounded,

              size: 16,

            ),

            label: const Text(

              'Add Medication',

            ),

            style:

                ElevatedButton.styleFrom(

              backgroundColor:

                  purple,

              foregroundColor:

                  Colors.white,

              padding:

                  const EdgeInsets.symmetric(

                horizontal: 16,

                vertical: 10,

              ),

              shape:

                  RoundedRectangleBorder(

                borderRadius:

                    BorderRadius.circular(

                  11,

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _buildMessageState({

    required IconData icon,

    required String title,

    required String message,

    Widget? action,

  }) {

    return Center(

      child: Padding(

        padding:

            const EdgeInsets.symmetric(

          horizontal: 32,

        ),

        child: Container(

          padding:

              const EdgeInsets.all(26),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:

                BorderRadius.circular(26),

            border: Border.all(

              color:

                  const Color(0xFFE5DCF4),

            ),

          ),

          child: Column(

            mainAxisSize:

                MainAxisSize.min,

            children: [

              Container(

                width: 76,

                height: 76,

                decoration:

                    const BoxDecoration(

                  color: lavender,

                  shape:

                      BoxShape.circle,

                ),

                child: Icon(

                  icon,

                  size: 36,

                  color: purple,

                ),

              ),

              const SizedBox(

                height: 18,

              ),

              Text(

                title,

                textAlign:

                    TextAlign.center,

                style: const TextStyle(

                  color: textDark,

                  fontSize: 19,

                  fontWeight:

                      FontWeight.w800,

                ),

              ),

              const SizedBox(

                height: 7,

              ),

              Text(

                message,

                textAlign:

                    TextAlign.center,

                style: const TextStyle(

                  height: 1.45,

                  fontSize: 13,

                  color: textMuted,

                ),

              ),

              if (action != null) ...[

                const SizedBox(

                  height: 20,

                ),

                action,

              ],

            ],

          ),

        ),

      ),

    );

  }

}

class MedicationCard

    extends StatelessWidget {

  static const Color purple =

      Color(0xFF7C3AED);

  static const Color lavender =

      Color(0xFFF3EEFF);

  static const Color textDark =

      Color(0xFF211738);

  static const Color textMuted =

      Color(0xFF716A80);

  final String name;

  final String dosage;

  final String nextDose;

  final List<String>? reminderTimes;

  final int? stockQuantity;

  final VoidCallback onTap;

  const MedicationCard({

    super.key,

    required this.name,

    required this.dosage,

    required this.nextDose,

    required this.reminderTimes,

    required this.onTap,

    required this.stockQuantity,

  });

  @override

  Widget build(

    BuildContext context,

  ) {

    final hasReminders =

        reminderTimes != null &&

            reminderTimes!.isNotEmpty;

    final timeText = hasReminders

        ? reminderTimes!.join(

            '  •  ',

          )

        : nextDose;

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        borderRadius:

            BorderRadius.circular(14),

        child: Ink(

          height: 88,

          padding:

              const EdgeInsets.symmetric(

            horizontal: 10,

            vertical: 9,

          ),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:

                BorderRadius.circular(14),

            border: Border.all(

              color:

                  const Color(0xFFE7DFF5),

            ),

            boxShadow: [

              BoxShadow(

                color: purple

                    .withOpacity(0.045),

                blurRadius: 8,

                offset:

                    const Offset(0, 2),

              ),

            ],

          ),

          child: Row(

            children: [

              Container(

                width: 48,

                height: 48,

                decoration:

                    BoxDecoration(

                  color: lavender,

                  borderRadius:

                      BorderRadius.circular(

                    14,

                  ),

                ),

                child: const Icon(

                  Icons.medication_rounded,

                  color: purple,

                  size: 25,

                ),

              ),

              const SizedBox(

                width: 11,

              ),

              Expanded(

                child: Column(

                  crossAxisAlignment:

                      CrossAxisAlignment

                          .start,

                  mainAxisAlignment:

                      MainAxisAlignment

                          .center,

                  children: [

                    Text(

                      name,

                      maxLines: 1,

                      overflow:

                          TextOverflow

                              .ellipsis,

                      style:

                          const TextStyle(

                        color: textDark,

                        fontSize: 12,

                        fontWeight:

                            FontWeight.w800,

                      ),

                    ),

                    const SizedBox(

                      height: 2,

                    ),

                    Text(

                      dosage.isEmpty

                          ? '—'

                          : dosage,

                      maxLines: 1,

                      overflow:

                          TextOverflow

                              .ellipsis,

                      style:

                          const TextStyle(

                        color: textMuted,

                        fontSize: 8.5,

                      ),

                    ),

                    const SizedBox(

                      height: 6,

                    ),

                    Row(

                      children: [

                        const Icon(

                          Icons

                              .schedule_rounded,

                          color: purple,

                          size: 12,

                        ),

                        const SizedBox(

                          width: 4,

                        ),

                        Flexible(

                          child: Text(

                            timeText,

                            maxLines: 1,

                            overflow:

                                TextOverflow

                                    .ellipsis,

                            style:

                                const TextStyle(

                              color: purple,

                              fontSize: 8,

                              fontWeight:

                                  FontWeight

                                      .w700,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ],

                ),

              ),

              const SizedBox(

                width: 5,

              ),

              Column(

                mainAxisAlignment:

                    MainAxisAlignment

                        .center,

                crossAxisAlignment:

                    CrossAxisAlignment

                        .end,

                children: [

                  Container(

                    padding:

                        const EdgeInsets

                            .symmetric(

                      horizontal: 8,

                      vertical: 5,

                    ),

                    decoration:

                        BoxDecoration(

                      color:

                          const Color(

                        0xFFE8F8F0,

                      ),

                      borderRadius:

                          BorderRadius

                              .circular(

                        10,

                      ),

                    ),

                    child:

                        const Row(

                      mainAxisSize:

                          MainAxisSize

                              .min,

                      children: [

                        Icon(

                          Icons

                              .notifications_active_rounded,

                          color:

                              Color(

                            0xFF159A6A,

                          ),

                          size: 9,

                        ),

                        SizedBox(

                          width: 3,

                        ),

                        Text(

                          'Reminder on',

                          style:

                              TextStyle(

                            color:

                                Color(

                              0xFF159A6A,

                            ),

                            fontSize: 6.5,

                            fontWeight:

                                FontWeight

                                    .w700,

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(

                    height: 5,

                  ),

                  Container(

                    width: 28,

                    height: 28,

                    decoration:

                        BoxDecoration(

                      color:

                          const Color(

                        0xFFF6F2FC,

                      ),

                      borderRadius:

                          BorderRadius

                              .circular(

                        8,

                      ),

                    ),

                    child:

                        const Icon(

                      Icons

                          .chevron_right_rounded,

                      size: 18,

                      color:

                          Color(

                        0xFF8B829B,

                      ),

                    ),

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }

}