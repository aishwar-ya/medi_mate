import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final supabase = Supabase.instance.client;

  // Fetch user settings from Supabase
  // FIX 1: The return type is now nullable (Map? instead of Map)
  Future<Map<String, dynamic>?> _loadSettings() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // <-- FIX 2: Changed .single() to .maybeSingle()

      return data;
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  // Update a single setting column in Supabase
  Future<void> _updateSetting(String columnName, bool value) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      await supabase.from('profiles').update({columnName: value}).eq('id', userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save setting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // The FutureBuilder type is also updated to be nullable
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadSettings(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          // No data (or data is null, which .maybeSingle() returns)
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile data found.'));
          }

          // Data loaded successfully
          final settings = snapshot.data!;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Medication'),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'Medication Reminders',
                      subtitle: 'Receive reminders to take your medications',
                      value: settings['medication_reminders'] ?? false,
                      onChanged: (value) {
                        setState(() => settings['medication_reminders'] = value);
                        _updateSetting('medication_reminders', value);
                      },
                    ),
                    const Divider(),
                    _buildSettingItem(
                      title: 'Refill Reminders',
                      subtitle: 'Receive reminders to refill your medications',
                      value: settings['refill_reminders'] ?? false,
                      onChanged: (value) {
                        setState(() => settings['refill_reminders'] = value);
                        _updateSetting('refill_reminders', value);
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Hydration'),
                  _buildSettingsCard([
                    _buildSettingItem(
                      title: 'Hydration Reminders',
                      subtitle: 'Receive reminders to drink water',
                      value: settings['hydration_reminders'] ?? false,
                      onChanged: (value) {
                        setState(() => settings['hydration_reminders'] = value);
                        _updateSetting('hydration_reminders', value);
                      },
                    ),
                    const Divider(),
                    _buildSettingItem(
                      title: 'Goal Achievement',
                      subtitle: 'Get notified when you reach your hydration goal',
                      value: settings['goal_achievement'] ?? false,
                      onChanged: (value) {
                        setState(() => settings['goal_achievement'] = value);
                        _updateSetting('goal_achievement', value);
                      },
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------
  // UI Helper Methods
  // ------------------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}