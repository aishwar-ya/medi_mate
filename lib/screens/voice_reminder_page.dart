import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/notification_service.dart';

class VoiceReminderPage extends StatefulWidget {
  const VoiceReminderPage({super.key});

  @override
  _VoiceReminderPageState createState() => _VoiceReminderPageState();
}

class _VoiceReminderPageState extends State<VoiceReminderPage> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  String _text = 'Press the button and start speaking...';
  String _status = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _tts.setLanguage("en-IN");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.9);
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
          _status = '🎤 Listening...';
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
        _status = 'Processing your command...';
      });
      _speech.stop();
      _processVoiceCommand(_text);
    }
  }

  /// Parse command like: "Remind me to take Paracetamol at 8:30 AM"
  void _processVoiceCommand(String command) async {
    if (command.isEmpty) {
      setState(() => _status = '❌ Could not hear you clearly. Please try again.');
      await _tts.speak("I couldn’t hear you clearly. Please try again.");
      return;
    }

    // Extract time from command
    final timeRegex = RegExp(
      r'at (\d{1,2})(?::(\d{2}))?\s*(AM|PM)?', // <-- Simplified this part
      caseSensitive: false,
    );
    final match = timeRegex.firstMatch(command);

    if (match == null) {
      setState(() {
        _status = "⚠️ Couldn't understand the time. Try saying '... at 8:30 AM'";
      });
      await _tts.speak(
          "Sorry, I couldn’t understand the time. Please try again, for example say at 8 30 AM.");
      return;
    }

    // Extract time details
    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2) ?? '00');
    String ampm = (match.group(3) ?? '').toUpperCase();

    if (ampm == 'PM' && hour < 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0; // 12 AM is 00:00

    String timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    // --- START: CORRECTED CODE BLOCK ---

    // Extract medicine name (before "at")
    String title = command.substring(0, match.start).trim();

    // Create a case-insensitive RegExp to find "remind me to" at the start
    final removeRegex = RegExp(r'^remind me to\s*', caseSensitive: false);

    // Use the RegExp to replace the phrase with an empty string
    title = title.replaceFirst(removeRegex, '').trim();

    if (title.isEmpty) title = 'Medication Reminder';

    // --- END: CORRECTED CODE BLOCK ---

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      // Schedule local notification
      await NotificationService.scheduleDailyNotification(
        id: id,
        title: '💊 Reminder: $title',
        body: 'It’s time to $title ($timeStr)',
        timeStr: timeStr,
      );

      // Voice confirmation
      final message = 'Okay, reminder set to $title at $timeStr.';
      setState(() => _status = message);
      await _tts.speak(message);
    } catch (e) {
      setState(() => _status = '❌ Error setting reminder: $e');
      await _tts.speak("Sorry, I couldn’t set that reminder. Please try again.");
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Reminder')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status.isEmpty
                    ? 'Press the mic and speak a command.'
                    : _status,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                "Try saying:\n'Remind me to take my Paracetamol at 8:30 AM'\nor\n'Remind me to drink water at 10 PM'",
                style: TextStyle(
                    color: Colors.grey[600], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor:
            _isListening ? Colors.red : Theme.of(context).primaryColor,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}