import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../services/notification_service.dart';

class VoiceReminderPage extends StatefulWidget {
  const VoiceReminderPage({super.key});

  @override
  State<VoiceReminderPage> createState() => _VoiceReminderPageState();
}

class _VoiceReminderPageState extends State<VoiceReminderPage> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;

  String _text = 'Press the microphone and start speaking...';
  String _status = '';

  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color lavender = Color(0xFFF3EEFF);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF716A80);
  static const Color success = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    _tts = FlutterTts();
    _tts.setLanguage("en-IN");
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.9);
  }

  // ------------------------------------------------------------
  // START / STOP LISTENING
  // ------------------------------------------------------------

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _status = 'Listening...';
          _text = '';
        });

        _speech.listen(
          onResult: (val) {
            if (!mounted) return;

            setState(() {
              _text = val.recognizedWords;
            });
          },
        );
      } else {
        setState(() {
          _status = 'Speech recognition is not available.';
        });

        await _tts.speak(
          'Speech recognition is not available.',
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _status = 'Processing your command...';
      });

      await _speech.stop();

      _processVoiceCommand(_text);
    }
  }

  // ------------------------------------------------------------
  // PROCESS VOICE COMMAND
  // ------------------------------------------------------------

  void _processVoiceCommand(String command) async {
    if (command.trim().isEmpty) {
      setState(() {
        _status =
            'Could not hear you clearly. Please try again.';
      });

      await _tts.speak(
        "I couldn't hear you clearly. Please try again.",
      );

      return;
    }

    // ----------------------------------------------------------
    // EXTRACT TIME
    //
    // Example:
    // "Remind me to take Paracetamol at 8:30 AM"
    // ----------------------------------------------------------

    final timeRegex = RegExp(
      r'at (\d{1,2})(?::(\d{2}))?\s(AM|PM)?',
      caseSensitive: false,
    );

    final match = timeRegex.firstMatch(command);

    if (match == null) {
      setState(() {
        _status =
            "Couldn't understand the time. Try saying '... at 8:30 AM'";
      });

      await _tts.speak(
        "Sorry, I couldn't understand the time. "
        "Please try again. For example, say at 8 30 AM.",
      );

      return;
    }

    // ----------------------------------------------------------
    // EXTRACT TIME DETAILS
    // ----------------------------------------------------------

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2) ?? '00');

    String ampm = (match.group(3) ?? '').toUpperCase();

    if (ampm == 'PM' && hour < 12) {
      hour += 12;
    }

    if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }

    String timeStr =
        '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';

    // ----------------------------------------------------------
    // EXTRACT REMINDER TITLE
    // ----------------------------------------------------------

    String title =
        command.substring(0, match.start).trim();

    final removeRegex = RegExp(
      r'^remind me to\s',
      caseSensitive: false,
    );

    title = title.replaceFirst(
      removeRegex,
      '',
    ).trim();

    if (title.isEmpty) {
      title = 'Medication Reminder';
    }

    // ----------------------------------------------------------
    // CREATE NOTIFICATION ID
    // ----------------------------------------------------------

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      // --------------------------------------------------------
      // SCHEDULE NOTIFICATION
      // --------------------------------------------------------

      await NotificationService.scheduleDailyNotification(
        id: id,
        title: '💊 Reminder: $title',
        body: 'It’s time to $title ($timeStr)',
        timeStr: timeStr,
      );

      // --------------------------------------------------------
      // VOICE CONFIRMATION
      // --------------------------------------------------------

      final message =
          'Okay, reminder set to $title at $timeStr.';

      if (mounted) {
        setState(() {
          _status = message;
        });
      }

      await _tts.speak(message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error setting reminder: $e';
        });
      }

      await _tts.speak(
        "Sorry, I couldn't set that reminder. Please try again.",
      );
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width =
                  constraints.maxWidth > 430
                      ? 430
                      : constraints.maxWidth;

              return SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    // ------------------------------------------------
                    // MAIN PAGE
                    // ------------------------------------------------

                    Column(
                      children: [
                        _buildTopBar(),

                        Expanded(
                          child: Stack(
                            children: [
                              // Decorative circle
                              Positioned(
                                top: -42,
                                right: -50,
                                child: Container(
                                  width: 125,
                                  height: 125,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE9DFFF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              SingleChildScrollView(
                                physics:
                                    const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  100,
                                ),
                                child: Column(
                                  children: [
                                    _buildVoiceHeader(),

                                    const SizedBox(height: 15),

                                    _buildStatusCard(),

                                    const SizedBox(height: 12),

                                    _buildSpeechCard(),

                                    const SizedBox(height: 12),

                                    _buildExamplesCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ------------------------------------------------
                    // MICROPHONE BUTTON
                    // ------------------------------------------------

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 18,
                      child: Center(
                        child: _buildMicrophoneButton(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      height: 82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),

          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: primary,
                size: 21,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          const SizedBox(width: 11),

          const Text(
            'Voice Reminder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // VOICE HEADER
  // ------------------------------------------------------------

  Widget _buildVoiceHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: lavender,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.11),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6D28D9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isListening
                  ? Icons.graphic_eq_rounded
                  : Icons.mic_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
        ),

        const SizedBox(height: 13),

        const Text(
          'Speak Your Reminder',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Tell MediMate what you want to remember',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textMuted,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // STATUS CARD
  // ------------------------------------------------------------

  Widget _buildStatusCard() {
    final bool hasStatus = _status.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: hasStatus ? lavender : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasStatus
              ? const Color(0xFFE0D3F8)
              : const Color(0xFFE5DCF4),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.045),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasStatus
                  ? primary.withOpacity(0.12)
                  : const Color(0xFFF1EDF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isListening
                  ? Icons.mic_rounded
                  : hasStatus
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
              color: _isListening
                  ? primary
                  : hasStatus
                      ? success
                      : primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status.isEmpty
                      ? 'Ready for your command'
                      : _status,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _isListening
                      ? 'I’m listening...'
                      : 'Tap the microphone below to start.',
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SPEECH CARD
  // ------------------------------------------------------------

  Widget _buildSpeechCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5DCF4),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.text_fields_rounded,
                  color: primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'Your command',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 84,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EXAMPLES CARD
  // ------------------------------------------------------------

  Widget _buildExamplesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0D3F8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'Try saying',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildExample(
            'Remind me to take my Paracetamol at 8:30 AM',
          ),

          const SizedBox(height: 8),

          _buildExample(
            'Remind me to drink water at 10 PM',
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EXAMPLE
  // ------------------------------------------------------------

  Widget _buildExample(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: primary,
            size: 18,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textDark,
                fontSize: 11.5,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MICROPHONE BUTTON
  // ------------------------------------------------------------

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: _listen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isListening
                ? const [
                    Color(0xFFEF4444),
                    Color(0xFFDC2626),
                  ]
                : const [
                    Color(0xFF8B5CF6),
                    Color(0xFF6D28D9),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isListening ? Colors.red : primary)
                  .withOpacity(0.26),
              blurRadius: 19,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          _isListening
              ? Icons.mic_off_rounded
              : Icons.mic_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}