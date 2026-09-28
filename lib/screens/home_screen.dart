import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _medicationsFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _medicationsFuture = _getMedications();
  }

  Future<List<dynamic>> _getMedications() async {
    try {
      final data = await supabase
          .from('medications')
          .select('id, name, dosage') 
          .order('created_at', ascending: false); 

      return data;
    } catch (e) {
      throw Exception('Failed to load medications: ${e.toString()}');
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Medication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g., Aspirin)'),
              ),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage (e.g., 100mg)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final dosage = dosageController.text.trim();

                if (name.isEmpty) return; 

                try {
                  await supabase.from('medications').insert({
                    'name': name,
                    'dosage': dosage,
                  });

                  // FIX 1: Add check after await, before using context
                  if (!context.mounted) return;

                  Navigator.pop(context); // Close the dialog

                  setState(() {
                    _medicationsFuture = _getMedications();
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medication added!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                } catch (e) {
                  // FIX 2: Add check after await, before using context
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add medication: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await supabase.auth.signOut();
              
              // FIX 3: Use context.mounted instead of just mounted
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no medications yet.\nTap the + button to add one!',
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final medications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              final medName = med['name'] ?? 'No Name';
              final medDosage = med['dosage'] ?? 'No Dosage';

              return Card(
                child: ListTile(
                  title: Text(medName),
                  subtitle: Text(medDosage),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}