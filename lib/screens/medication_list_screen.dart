import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_mate/models/medication_model.dart';
import 'package:medi_mate/screens/add_medication_screen.dart';
import 'package:medi_mate/screens/barcode_scanner_screen.dart';
import 'package:medi_mate/services/notification_service.dart';
import 'package:intl/intl.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final supabase = Supabase.instance.client;

  late Future<List<Medication>> _medicationsFuture;
  List<Medication> _medicationsList = [];

  @override
  void initState() {
    super.initState();
    _medicationsFuture = _fetchMedications().then((meds) {
      if (mounted) {
        setState(() {
          _medicationsList = meds;
        });
      }
      return meds;
    });
  }

  Future<List<Medication>> _fetchMedications() async {
    try {
      // --- FIX 2: Secure the query to only fetch meds for the current user ---
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return []; // Not logged in

      final List<Map<String, dynamic>> data = await supabase
          .from('medications')
          .select()
          .eq('user_id', userId) // Only get rows where user_id matches
          .order('created_at', ascending: false);

      return data.map((item) => Medication.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      return [];
    }
  }

  void _refreshList() {
    setState(() {
      _medicationsFuture = _fetchMedications().then((meds) {
        if (mounted) {
          setState(() {
            _medicationsList = meds;
          });
        }
        return meds;
      });
    });
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

        final insertedData =
            await supabase.from('medications').insert(result).select();
        final newMed = Medication.fromJson(insertedData.first);

        if (newMed.nextDose != null) {
          final dt = DateTime.parse(newMed.nextDose!);
          final timeStr = DateFormat('HH:mm').format(dt);

          await NotificationService.scheduleDailyNotification(
            id: newMed.id,
            title: 'Medication Reminder',
            body: 'Time to take ${newMed.name}',
            timeStr: timeStr,
          );
        }

        _refreshList();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to add medication: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => AddMedicationScreen(initialData: {'barcode': barcode}),
        ),
      );

      if (result != null && mounted) {
        try {
          // --- FIX 3 (Repeat): Add the user_id before inserting ---
          final userId = supabase.auth.currentUser?.id;
          if (userId == null) throw Exception('User not logged in');
          result['user_id'] = userId;

          final insertedData =
              await supabase.from('medications').insert(result).select();
          final newMed = Medication.fromJson(insertedData.first);

          if (newMed.nextDose != null) {
            // --- FIX 4 (Repeat): Format the ISO string back to 'HH:mm' ---
            final dt = DateTime.parse(newMed.nextDose!);
            final timeStr = DateFormat('HH:mm').format(dt);

            await NotificationService.scheduleDailyNotification(
              id: newMed.id,
              title: 'Medication Reminder',
              body: 'Time to take ${newMed.name}',
              timeStr: timeStr, // Pass the formatted time
            );
          }

          _refreshList();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to add medication: $e'),
                  backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _editMedication(Medication med) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => AddMedicationScreen(initialData: med.toMap())),
    );

    if (result != null && mounted) {
      try {
        final id = result['id'] as int;
        result.remove('id'); 
        
        // --- FIX 5: Secure the update query ---
        final userId = supabase.auth.currentUser?.id;

        // --- THIS IS THE FIX for line 177 ---
        // If there is no user, stop the function.
        if (userId == null) {
          debugPrint("Error: No user logged in for update.");
          return; 
        }
        // ------------------------------------

        await supabase.from('medications').update(result)
            .eq('id', id)
            .eq('user_id', userId); // Only update if user_id matches

        await NotificationService.cancelNotification(id);
        if (result['next_dose'] != null) {
          // --- FIX 4 (Repeat): Format the ISO string back to 'HH:mm' ---
          final dt = DateTime.parse(result['next_dose']);
          final timeStr = DateFormat('HH:mm').format(dt);

          await NotificationService.scheduleDailyNotification(
            id: id,
            title: 'Medication Reminder',
            body: 'Time to take ${result['name']}',
            timeStr: timeStr,
          );
        }

        _refreshList();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update medication: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteMedication(int id) async {
    try {
      // --- FIX 5 (Repeat): Secure the delete query ---
      final userId = supabase.auth.currentUser?.id;

      // --- THIS IS THE FIX for line 212 ---
      // If there is no user, stop the function.
      if (userId == null) {
        debugPrint("Error: No user logged in for delete.");
        return; 
      }
      // ------------------------------------

      await supabase.from('medications').delete()
          .eq('id', id)
          .eq('user_id', userId); // Only delete if user_id matches
          
      await NotificationService.cancelNotification(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red),
        );
      }
      // You should refresh the list even if delete fails, to revert the UI
      _refreshList();
    }
  }

  void _handleDismiss(int index) {
    final med = _medicationsList[index];

    setState(() {
      _medicationsList.removeAt(index);
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text('${med.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _medicationsList.insert(index, med);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        _deleteMedication(med.id);
      }
    });
  }

  // --- FIX 6: Helper function to format ISO time for display ---
  String _formatDisplayTime(String? isoString) {
    if (isoString == null) return 'No Time';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('h:mm a').format(dt); // e.g., "8:00 AM"
    } catch (e) {
      return 'Invalid Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode,
              tooltip: 'Scan Barcode'),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              onPressed: _addMedication,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _medicationsList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          if (_medicationsList.isEmpty) {
            return const Center(
                child: Text('No medications added yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _medicationsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final med = _medicationsList[index];
                // --- FIX 7: Use the helper to show a clean time ---
                final displayTime = _formatDisplayTime(med.nextDose);

                return Dismissible(
                  key: Key(med.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.red.shade700),
                  ),
                  onDismissed: (_) => _handleDismiss(index),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _editMedication(med),
                    child: MedicationCard(
                      name: med.name,
                      nextDose: displayTime, // Pass the formatted time
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final String name;
  final String nextDose;

  const MedicationCard(
      {super.key, required this.name, required this.nextDose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.medication,
                  color: Theme.of(context).primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Next dose: $nextDose',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}