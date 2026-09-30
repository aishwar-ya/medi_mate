import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String text, bool isFinal);
typedef SpeechStatusCallback = void Function(String status);
typedef SpeechErrorCallback = void Function(String error);

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize({
    required SpeechStatusCallback onStatus,
    required SpeechErrorCallback onError,
  }) async {
    return _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(error.toString()),
    );
  }

  Future<void> start({
    required SpeechResultCallback onResult,
  }) async {
    await _speech.listen(
      localeId: 'en-IN',
      partialResults: true,
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();
  Future<void> dispose() => _speech.cancel();
}
