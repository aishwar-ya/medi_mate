import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/notification_service.dart';

class VoiceReminderPage extends StatefulWidget {
  const VoiceReminderPage({super.key});

  @override
  _VoiceReminderPageState createState() => _VoiceReminderPageState();
}

class _VoiceReminderPageState extends State<VoiceReminderPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking...';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Also initialize your notification service if it's not already
    // NotificationService.init(); // Assuming you call this in main.dart
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _status = 'Listening...';
          _text = '';
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _status = 'Processing...';
      });
      _speech.stop();
      _processVoiceCommand(_text);
    }
  }

  /// This is the new "parser" function
  void _processVoiceCommand(String command) {
    if (command.isEmpty) {
      setState(() {
        _status = 'Could not hear you. Please try again.';
      });
      return;
    }

    // Example command: "Remind me to take my paracetamol at 8:30 AM"
    // We will try to extract "paracetamol" and "8:30 AM".

    // 1. Find the time (e.g., "at 8:30 AM", "at 10 PM", "at 14:00")
    // This regex is basic and can be improved.
    final timeRegex = RegExp(
      r'at (\d{1,2})(?::(\d{2}))?\s*(AM|PM|)',
      caseSensitive: false,
    );
    final match = timeRegex.firstMatch(command);

    if (match == null) {
      setState(() {
        _status = "Sorry, I couldn't understand the time. Please try again, e.g., '...at 8:30 AM'.";
      });
      return;
    }

    // 2. Extract time components
    String hourStr = match.group(1)!; // e.g., "8"
    String minuteStr = match.group(2) ?? '00'; // e.g., "30" or "00"
    String ampm = match.group(3)?.toUpperCase() ?? ''; // e.g., "AM"

    int hour = int.parse(hourStr);
    int minute = int.parse(minuteStr);

    // Convert to 24-hour format
    if (ampm == 'PM' && hour < 12) {
      hour += 12;
    }
    if (ampm == 'AM' && hour == 12) {
      hour = 0; // Midnight
    }
    
    // Format for your service: 'HH:mm'
    final String timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'; // "08:30" or "20:30"

    // 3. Extract the title (everything before "at")
    String title = command.substring(0, match.start).trim();
    if (title.isEmpty) {
      title = 'Medication Reminder';
    }

    // Capitalize first letter
    title = title[0].toUpperCase() + title.substring(1);

    // 4. Schedule the notification using your service!
    try {
      // We need a unique ID for the notification
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      NotificationService.scheduleDailyNotification(
        id: id,
        title: title,
        body: 'Time to take your medicine! ($timeStr)',
        timeStr: timeStr,
      );

      setState(() {
        _status = 'Reminder set for $title at $timeStr daily!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error setting reminder: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Reminder'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isListening ? 'Listening...' : _status,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _text,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Try saying:\n'Remind me to take my paracetamol at 8:30 AM'\nor\n'... at 10 PM'",
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}