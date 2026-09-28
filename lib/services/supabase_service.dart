import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Add new reminder
  static Future<Map<String, dynamic>> addReminder(String title, DateTime time) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final Map<String, dynamic> reminder = await _client
          .from('voice_reminders')
          .insert({
            'title': title,
            'scheduled_time': time.toIso8601String(),
            'user_id': user.id,
          })
          .select()
          .single();
      return reminder;
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  // Fetch all reminders
  static Future<List<Map<String, dynamic>>> fetchReminders() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final List<dynamic> response = await _client
          .from('voice_reminders')
          .select()
          .eq('user_id', user.id)
          .order('scheduled_time', ascending: true);
      
      return response.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  // Delete reminder
  static Future<void> deleteReminder(String id) async {
    try {
      await _client
          .from('voice_reminders')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }
}